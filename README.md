# AppBox Plugin for Fastlane

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-appbox)

## 1. Getting Started

**Step 1** - This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-appbox`, add it to your project by running:

```bash
fastlane add_plugin appbox
```

**Step 2** - Download the latest version of AppBox from [here](https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases) or [here](https://getappbox.com/download) and install it into `/Applications` directory of you mac. Now, open AppBox and login with your Dropbox account.

**Step 3** - Define appbox action in your project Fastfile with emails and message. Here the available params for appbox plugins - 

- `emails` (Required | String) - Comma-separated list of email address that should receive application installation link.
- `message` (Optional | String) - Attach personal message in the email. Supported Keywords:  
    >The {PROJECT_NAME} - For Project Name,    
    >{BUILD_VERSION} - For Build Version, and   
    >{BUILD_NUMBER} - For Build Number.
- `appbox_path` (Optional | String) - If you've setup AppBox in the different directory then you need to mention that here. Default is `/Applications/AppBox.app`
- `keep_same_link` (Optional | Bool) - This feature will keep same short URL for all future build/IPA uploaded with same bundle identifier. If this option is enabled, you can also download the previous build with the same URL. Read more [here](https://docs.getappbox.com/Features/keepsamelink/). 
- `dropbox_folder_name` (Optional | String) - You can change the link by providing a Custom Dropbox Folder Name. By default folder name will be the application bundle identifier. So, AppBox will keep the same link for the IPA file available in the same folder. Read more [here](https://docs.getappbox.com/Features/keepsamelink/).


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
        emails: 'you@example.com,'someoneelse@example.com',
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
        message: '{PROJECT_NAME} - {BUILD_VERSION}({BUILD_NUMBER}) is ready to test.',
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
        message: '{PROJECT_NAME} - {BUILD_VERSION}({BUILD_NUMBER}) is ready to test.',
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
        message: '{PROJECT_NAME} - {BUILD_VERSION}({BUILD_NUMBER}) is ready to test.',
        keep_same_link: true,
        dropbox_folder_name: 'Fastlane-Demo-Keep-Same-Link',
    )
  end
end
```

#### 6. Upload IPA file where AppBox available at some custom path instead of macOS Application Directory.

```rb
default_platform(:ios)

platform :ios do
  lane :gymbox do
    gym
    appbox(
        emails: 'you@example.com,'someoneelse@example.com',
        appbox_path:'/Users/vineetchoudhary/Desktop/AppBox3.4.0/AppBox.app',
    )
  end
end
```

#### Note
When you run this for the first time, a pop-up will appear stating that "Terminal.app" wants to access data from other apps. You must allow this to copy the IPA file to the Appbox temporary directory, enabling Appbox to access and upload it.
![](/AppBox-Fastlane-Demo-Project/images/terminal-permission.webp)

## 3. Supported AppBox link access via Fastlane SharedValues
- `APPBOX_SHARE_URL` - AppBox short shareable URL to install uploaded application.   
- `APPBOX_IPA_URL`- Upload IPA file URL to download IPA file.   
- `APPBOX_MANIFEST_URL` - Manifest file URL for upload application.   

## 4. About AppBox
[AppBox](https://getappbox.com) is a tool for iOS developers to build and deploy Development, Ad-Hoc and In-house (Enterprise) applications directly to the devices from your Dropbox account. Also, available on [Github](https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation).

## 5. Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## 6. Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this [repository](https://github.com/getappbox/fastlane-plugin-appbox/issues/new).

## 6. Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

