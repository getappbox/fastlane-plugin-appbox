fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios gymbox

```sh
[bundle exec] fastlane ios gymbox
```

Upload IPA file and Send an email to single email.

### ios gymbox_message

```sh
[bundle exec] fastlane ios gymbox_message
```

Upload IPA file and Send email with a custom message.

### ios gymbox_keep_same_link

```sh
[bundle exec] fastlane ios gymbox_keep_same_link
```

Upload IPA file and keep the same link for all future upload IPAs.

### ios gymbox_custom_db_dir_name

```sh
[bundle exec] fastlane ios gymbox_custom_db_dir_name
```

Upload IPA file and keep the same link for all future upload IPAs in Custom Dropbox folder.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
