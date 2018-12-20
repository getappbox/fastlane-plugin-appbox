# AppBox Plugin for Fastlane

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-appbox)

## 1. Getting Started

**Step 1** - This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-appbox`, add it to your project by running:

```bash
fastlane add_plugin appbox
```

**Step 2** - Download the latest version of AppBox from [here](https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases) or [here](https://getappbox.com/download) and install it into `/Applications` directory of you mac. Now, open AppBox and login with your Dropbox account.

**Step 3** - Define appbox action in your project Fastfile with emails and message. Here the available params for appbox plugins - 

- `emails` (Required) - Comma-separated list of email address that should receive application installation link.
- `message` (Optional) - Attach personal message in the email. Supported Keywords:  
    >The {PROJECT_NAME} - For Project Name,    
    >{BUILD_VERSION} - For Build Version, and   
    >{BUILD_NUMBER} - For Build Number.
- `appbox_path` (Optional) - If you've setup AppBox in the different directory then you need to mention that here. Default is `/Applications/AppBox.app`


## 2. Demo Fastfile with a lane `gymbox`

```rb
default_platform(:ios)

platform :ios do
  desc "Generate IPA file and Create an sharable link using AppBox"
  lane :gymbox do
    gym
    appbox(
        emails: 'youemail@example.com',
        message: '{PROJECT_NAME} - {BUILD_VERSION}({BUILD_NUMBER}) is ready to test.'
    )
  end
end
```

![](/AppBox-Fastlane-Demo-Project/AppBoxFastlane.gif)


## 3. About AppBox
[AppBox](https://getappbox.com) is a tool for iOS developers to build and deploy Development, Ad-Hoc and In-house (Enterprise) applications directly to the devices from your Dropbox account. Also, available on [Github](https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation).

## 4. Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## 5. Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this repository.

## 6. Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

