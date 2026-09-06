# AppBox Plugin for Fastlane

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-appbox)

## 1. Getting Started

**Step 1** - This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-appbox`, add it to your project by running:

```bash
fastlane add_plugin appbox
```

**Step 2** - Install AppBox using one of the following methods:

- **Direct Install:**
  ```bash
  curl -s https://getappbox.com/install.sh | bash
  ```

- **Homebrew:**
  ```bash
  brew install --cask appbox
  ```

Now, open AppBox and login with your Dropbox account.

This plugin targets **AppBox 4.0 or later**, which requires macOS 15 Sequoia or later.

**Step 3** - Define appbox action in your project Fastfile with emails and message. Here the available params for appbox plugins - 

- `emails` (Optional | String) - Comma-separated list of email address that should receive application installation link.
- `message` (Optional | String) - A personal message shown under "Message from the developer" in the email, such as `'Here is the latest build.'`. Sent exactly as written — see [Using build details in the message](#using-build-details-in-the-message) to include the version or build number, or if you are moving off the AppBox 3 placeholders.
- `keep_same_link` (Optional | Bool) - This feature will keep same short URL for all future build/IPA uploaded with same bundle identifier. If this option is enabled, you can also download the previous build with the same URL. Read more [here](https://docs.getappbox.com/Features/keepsamelink/). 
- `slack_webhook_url` (Optional | String) - Slack Incoming Webhook URL to post a notification to a Slack channel.
- `ms_teams_webhook_url` (Optional | String) - Microsoft Teams Incoming Webhook URL to post a notification to a Teams channel.
- `webhook_message` (Optional | String) - **Deprecated and ignored since AppBox 4**, which generates the notification text from the build itself. The plugin warns and drops it, so existing Fastfiles keep working unchanged.
- `dropbox_folder_name` (Optional | String) - You can change the link by providing a Custom Dropbox Folder Name. By default folder name will be the application bundle identifier. So, AppBox will keep the same link for the IPA file available in the same folder. Read more [here](https://docs.getappbox.com/Features/keepsamelink/).

### Using build details in the message

`message` is plain text and is sent exactly as written, so most Fastfiles just pass a sentence. To include the version, build number or app name, interpolate them from fastlane in a **double-quoted** string, since Ruby only expands `#{}` there:

```rb
message: "MyApp #{get_version_number}(#{get_build_number}) is ready to test.",
```

AppBox 3 used to do this for you by substituting `{BUILD_NAME}`, `{BUILD_VERSION}` and `{BUILD_NUMBER}`. AppBox 4 removed that substitution, so a message still containing them arrives with the braces intact. Replace them as follows:

| AppBox 3 placeholder | Replace with |
| --- | --- |
| `{BUILD_NAME}` | your app or scheme name, or `#{File.basename(lane_context[SharedValues::IPA_OUTPUT_PATH], '.ipa')}` |
| `{BUILD_VERSION}` | `#{get_version_number}` |
| `{BUILD_NUMBER}` | `#{get_build_number}` |
| `{SHARE_URL}` | Nothing to do. It only applied to `webhook_message`, which AppBox 4 ignores and generates itself. |


## 2. Demo Fastfile with a lane `gymbox` with Different Options

#### 1. Upload IPA file and Send an email to single email.

```rb
default_platform(:ios)

platform :ios do
  lane :gymbox do
    gym
    appbox(
        emails: 'you@example.com',
    )
  end
end
```

#### 2. Upload IPA file and Send email to multiple commas separated emails.

```rb
default_platform(:ios)

platform :ios do
  lane :gymbox do
    gym
    appbox(
        emails: 'you@example.com,someoneelse@example.com',
    )
  end
end
```

#### 3. Upload IPA file and Send email with a custom message.

```rb
default_platform(:ios)

platform :ios do
  lane :gymbox do
    gym
    appbox(
        emails: 'you@example.com',
        message: 'Please test the new checkout flow.',
    )
  end
end
```

#### 4. Upload IPA file and keep the same link for all future upload IPAs.

```rb
default_platform(:ios)

platform :ios do
  lane :gymbox do
    gym
    appbox(
        emails: 'you@example.com',
        message: 'Here is the latest build.',
        keep_same_link: true,
    )
  end
end
```

#### 5. Upload IPA file and keep the same link for all future upload IPAs in Custom Dropbox folder.

```rb
default_platform(:ios)

platform :ios do
  lane :gymbox do
    gym
    appbox(
        emails: 'you@example.com',
        message: 'Here is the latest build.',
        keep_same_link: true,
        dropbox_folder_name: 'Fastlane-Demo-Keep-Same-Link',
    )
  end
end
```

## 3. Supported AppBox link access via Fastlane SharedValues
- `APPBOX_SHARE_URL` - AppBox short shareable URL to install uploaded application.   
- `APPBOX_IPA_URL`- Upload IPA file URL to download IPA file.   
- `APPBOX_MANIFEST_URL` - Manifest file URL for upload application.   

## 4. About AppBox
[AppBox](https://getappbox.com) is a tool for iOS developers to build and deploy Development, Ad-Hoc and In-house (Enterprise) applications directly to the devices from your Dropbox account. Also, available on [Github](https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation).

## 5. Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## 6. Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this [repository](https://github.com/getappbox/fastlane-plugin-appbox/issues/new).

## 7. Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

