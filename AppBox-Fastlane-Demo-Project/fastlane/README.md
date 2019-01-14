fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios gymbox
```
fastlane ios gymbox
```
Upload IPA file and Send an email to single email.
### ios gymbox_message
```
fastlane ios gymbox_message
```
Upload IPA file and Send email with a custom message.
### ios gymbox_keep_same_link
```
fastlane ios gymbox_keep_same_link
```
Upload IPA file and keep the same link for all future upload IPAs.
### ios gymbox_custom_db_dir_name
```
fastlane ios gymbox_custom_db_dir_name
```
Upload IPA file and keep the same link for all future upload IPAs in Custom Dropbox folder.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
