# Rangefinder GitHub integration

Rangefinder is a tool that helps predict the downstream impact of breaking
file changes. This GitHub integration allows us to tie it to pull requests
and provide impact prediction reports as comments when a PR is filed.

It's still fairly young in its development, so please don't hesitate to
file issues either here or on the
[Rangefinder tool](https://github.com/puppetlabs/puppet-community-rangefinder) itself.

See my [blog post](https://binford2k.com/2020/04/30/downstream-impact-of-pull-requests/)
for more information on this tool.


## Installation

1. Visit its [GitHub app page](https://github.com/apps/puppet-community-rangefinder).
2. Click **Install App** in the sidebar.
3. Select your name or an organization you belong to.
4. Then select the repositories you'd like to enable the app on.

![install app](public/install_app.png)
![select repos](public/select_repos.png)


## Running your own server

This is a fairly complex configuration. You'll need to register both Google Cloud
and GitHub apps, and configure Rangefinder itself.

* Register a new GitHub app following the instructions at:
    * https://developer.github.com/apps/building-github-apps/creating-a-github-app/
* Generate a new GitHub private key:
    * https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps/
* Create a new Google Cloud service account:
    * https://cloud.google.com/docs/authentication/getting-started

Use that information to generate your configuration file. The `:gcloud` key will
be passed directly through to the [Rangefinder config](https://github.com/puppetlabs/puppet-community-rangefinder#configuration).
If you're using the official Puppet public BigQuery dataset, then you should use
the values provided in the example below.

The configuration file location defaults to the first found of

1. `~/.rangefinder.conf`
2. `/etc/rangefinder/config.yaml`

### Example configuration:

``` yaml
---
:gcloud:
  :dataset: community
  :project: dataops-puppet-public-data
  :keyfile: <your service account credentials>
:github:
  :app_identifier: <your app id>
  :private_key_file: <your private key file>
  :webhook_secret: <your webhook secret>
```


## Limitations

This is super early in development and has not yet been battle tested.


## Disclaimer

I take no liability for the use of this tool.


Contact
-------

binford2k@gmail.com

