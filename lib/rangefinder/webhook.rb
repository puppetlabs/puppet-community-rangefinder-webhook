require 'json'
require 'logger'
require 'tmpdir'
require 'sinatra/base'
require 'rangefinder'
require 'open-uri'

require 'octokit'
require 'openssl'     # Verifies the webhook signature
require 'jwt'         # Authenticates a GitHub App
require 'time'        # Gets ISO 8601 representation of a Time object

class Rangefinder::Webhook < Sinatra::Base
  require 'rangefinder/webhook/version'

  set :logging, true
  set :strict,  true
  set :views,         File.dirname(__FILE__) + '/../../views'
  set :public_folder, File.dirname(__FILE__) + '/../../public'

  def initialize(app=nil)
    super(app)
    $logger.info "Starting Rangefinder Webhook Service v#{Rangefinder::Webhook::VERSION}"
    $logger.info "Running Rangefinder v#{Rangefinder::VERSION}"

    begin
      @rangefinder    = Rangefinder.new(:gcloud => settings.gcloud)
      @app_identifier = settings.github[:app_identifier]
      @webhook_secret = settings.github[:webhook_secret]
      @private_key    = OpenSSL::PKey::RSA.new(File.read(settings.github[:private_key_file]))
    rescue => e
      $logger.error "There's a problem with your configuration file!"
      $logger.error e.message
      $logger.debug e.backtrace.join "\n"
      exit 1
    end
  end

  # Before each request to the `/event_handler` route
  before '/event_handler' do
    get_payload_request(request)
    verify_webhook_signature
    authenticate_app
    # Authenticate the app installation in order to run API operations
    authenticate_installation(@payload)
  end


  post '/event_handler' do
    $logger.debug @payload

    case request.env['HTTP_X_GITHUB_EVENT']
    when 'pull_request'
      case @payload['action']
      when 'opened', 'reopened'
        scan_for_impact(@payload)
      else
        $logger.info "Unhandled PR action: #{@payload['action']}"
      end
    end

    200 # success status
  end

  get '/' do
    erb :index
  end

  not_found do
    halt 404, "You shall not pass! (page not found)\n"
  end

  helpers do
    def scan_for_impact(payload)
      begin
        repo  = payload.dig('pull_request', 'base', 'repo', 'full_name')
        idx   = payload.dig('pull_request', 'number')
        files = @installation_client.pull_request_files(repo, idx)
        paths = files.map {|file| file[:filename] }
      rescue => e
        $logger.error "Problem retrieving file list from PR: #{e.message}"
        $logger.debug e.backtrace.join("\n")
        return
      end

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('module.tar.gz', open("https://api.github.com/repos/#{repo}/tarball/pull/#{idx}/head").read)
          system("tar -xzf module.tar.gz --strip-components=1")
          @impact = @rangefinder.analyze(paths)

          # don't comment if we don't know anything about any of the changed files
          return if @impact.compact.empty?

          # This really only works on a single module root anyways
          @puppetfiles = @impact.map { |item| item[:puppetfile] }.compact.uniq.first

          # Add the file url to each entry
          @impact.each do |item|
            uri = files.shift[:blob_url] # this order is intentional, it keeps the two lists in sync
            next if item.nil?
            item[:fileuri] = uri

            munge_repo_urls(item[:exact])
            munge_repo_urls(item[:near])
          end
          @impact.compact!

          @installation_client.add_comment(repo, idx, erb(:impact))
        end
      end
    end

    def munge_repo_urls(mod)
      mod.each do |item|
        item[:repo] = canonicalize(item[:repo], item[:module])
      end
    end

    def canonicalize(url, mod)
      # do it like this instead of a regex because this should cover more git servers. (github, gitlab, bitbucket, etc)
      if url.nil? or url.class != String
        "https://forge.puppet.com/#{mod.sub('-', '/')}"
      elsif url.start_with? 'git://'
        url.sub(/^git/, 'https')
      elsif url.start_with? 'git@'
        url.sub(/^git@([^:]+):/, 'https://\1/')
      elsif url !~ URI::regexp
        "https://forge.puppet.com/#{mod.sub('-', '/')}"
      else
        url
      end
    end

    # Saves the raw payload and converts the payload to JSON format
    def get_payload_request(request)
      # request.body is an IO or StringIO object
      # Rewind in case someone already read it
      request.body.rewind
      # The raw text of the body is required for webhook signature verification
      @payload_raw = request.body.read
      begin
        @payload = JSON.parse @payload_raw
      rescue => e
        fail  "Invalid JSON (#{e}): #{@payload_raw}"
      end
    end

    # Instantiate an Octokit client authenticated as a GitHub App.
    # GitHub App authentication requires that you construct a
    # JWT (https://jwt.io/introduction/) signed with the app's private key,
    # so GitHub can be sure that it came from the app an not altererd by
    # a malicious third party.
    def authenticate_app
      payload = {
          iat: Time.now.to_i,             # The time that this JWT was issued
          exp: Time.now.to_i + (10 * 60), # JWT expiration time (10 minute max)
          iss: @app_identifier,           # Your GitHub App's identifier number
      }

      # Cryptographically sign the JWT.
      jwt = JWT.encode(payload, @private_key, 'RS256')

      # Create the Octokit client, using the JWT as the auth token.
      @app_client ||= Octokit::Client.new(bearer_token: jwt)
    end

    # Instantiate an Octokit client, authenticated as an installation of a
    # GitHub App, to run API operations.
    def authenticate_installation(payload)
      @installation_id = payload['installation']['id']
      @installation_token = @app_client.create_app_installation_access_token(@installation_id)[:token]
      @installation_client = Octokit::Client.new(bearer_token: @installation_token)
    end

    # Check X-Hub-Signature to confirm that this webhook was generated by
    # GitHub, and not a malicious third party.
    #
    # GitHub uses the WEBHOOK_SECRET, registered to the GitHub App, to
    # create the hash signature sent in the `X-HUB-Signature` header of each
    # webhook. This code computes the expected hash signature and compares it to
    # the signature sent in the `X-HUB-Signature` header. If they don't match,
    # this request is an attack, and you should reject it. GitHub uses the HMAC
    # hexdigest to compute the signature. The `X-HUB-Signature` looks something
    # like this: "sha1=123456".
    # See https://developer.github.com/webhooks/securing/ for details.
    def verify_webhook_signature
      their_signature_header = request.env['HTTP_X_HUB_SIGNATURE'] || 'sha1='
      method, their_digest = their_signature_header.split('=')
      our_digest = OpenSSL::HMAC.hexdigest(method, @webhook_secret, @payload_raw)
      halt 401 unless their_digest == our_digest

      # The X-GITHUB-EVENT header provides the name of the event.
      # The action value indicates the which action triggered the event.
      $logger.debug "---- received event #{request.env['HTTP_X_GITHUB_EVENT']}"
      $logger.debug "----    action #{@payload['action']}" unless @payload['action'].nil?
    end

  end

end
