# v0.0.7

Validate and bail out early if the repository is not actually a Puppet module.
This is identified simply by the presence of a `metadata.json` file. This will
allow an org to enable the webhook for all repositories and it will just ignore
non-module repos.


# v0.0.6.1

Fixed a crasher when encountering unhandled filetypes.


# v0.0.6

Spawn the actual analysis in a worker thread so that the webhook can respond
immediately. This should hopefully reduce the number of 503 timeouts.
Added some actual docs on how to run this thing.

# v0.0.5

Cleaned up output format so that the github comment is more readable.


# v0.0.4.1

* Add Puppetfile output


# v0.0.3

* Make all URIs in a report into forms that are clickable in a web browser.


# v0.0.2

* Check against the base repo instead of head
* A bit more error handling


# v0.0.1

* Initial release.
