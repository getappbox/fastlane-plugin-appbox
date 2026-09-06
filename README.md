# AppBox Plugin for Fastlane

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-appbox)
[![Test](https://github.com/getappbox/fastlane-plugin-appbox/actions/workflows/test.yml/badge.svg)](https://github.com/getappbox/fastlane-plugin-appbox/actions/workflows/test.yml)

## 1. Getting Started

### 1.1. Add appbox plugin to your project 
This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-appbox`, add it to your project by running:

```bash
fastlane add_plugin appbox
```

### 1.2. Install AppBox (if you haven't already)
Install AppBox using one of the following methods:

- **Direct Install:**
  ```bash
  curl -s https://getappbox.com/install.sh | bash
  ```

- **Homebrew:**
  ```bash
  brew install --cask appbox
  ```

Now, open AppBox and login with your Dropbox account.

### 1.3. Configure your Fastfile

Define appbox action in your project Fastfile with emails and message. Here the available params for appbox plugins - 

| Parameter | Type | Description |
| --- | --- | --- |
| `emails` | String (Optional) | Comma-separated list of email address that should receive application installation link. |
| `message` | String (Optional) | A personal message shown under "Message from the developer" in the email, such as `'Here is the latest build.'`. |
| `keep_same_link` | Bool (Optional) | This feature will keep same short URL for all future build/IPA uploaded with same bundle identifier. Read more [here](https://docs.getappbox.com/Features/keepsamelink/). |
| `slack_webhook_url` | String (Optional) | Slack Incoming Webhook URL to post a notification to a Slack channel. |
| `ms_teams_webhook_url` | String (Optional) | Microsoft Teams Incoming Webhook URL to post a notification to a Teams channel. |
| `webhook_message` | String (Optional) | **Deprecated and ignored since AppBox 4**, which generates the notification text from the build itself. |
| `dropbox_folder_name` | String (Optional) | You can change the link by providing a Custom Dropbox Folder Name. Read more [here](https://docs.getappbox.com/Features/keepsamelink/). |


## 2. Supported AppBox link access via Fastlane SharedValues

- `APPBOX_SHARE_URL` - AppBox short shareable URL to install uploaded application.   
- `APPBOX_IPA_URL`- Upload IPA file URL to download IPA file.   
- `APPBOX_MANIFEST_URL` - Manifest file URL for upload application.   

## 3. Demo Fastfile with a lane `gymbox` with Different Options

### 3.1. Upload IPA file and Send an email to single email.

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

### 3.2. Upload IPA file and Send email to multiple commas separated emails.

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

### 3.3. Upload IPA file and Send email with a custom message.

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

### 3.4. Upload IPA file and keep the same link for all future upload IPAs.

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

### 3.5. Upload IPA file and keep the same link for all future upload IPAs in Custom Dropbox folder.

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

## 4. About AppBox
[AppBox](https://getappbox.com) is a tool for iOS developers to build and deploy Development, Ad-Hoc and In-house (Enterprise) applications directly to the devices from your Dropbox account. Also, available on [Github](https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation).

## 5. Example
Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## 6. Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this [repository](https://github.com/getappbox/fastlane-plugin-appbox/issues/new).

## 7. Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

