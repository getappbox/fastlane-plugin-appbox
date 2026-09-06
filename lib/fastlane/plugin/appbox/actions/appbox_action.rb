require "json"
require "shellwords"
require 'fastlane/action'
require_relative '../helper/appbox_helper'

module Fastlane
  module Actions
    module SharedValues
      APPBOX_IPA_URL = :APPBOX_IPA_URL
      APPBOX_SHARE_URL = :APPBOX_SHARE_URL
      APPBOX_MANIFEST_URL = :APPBOX_MANIFEST_URL
    end

    class AppboxAction < Action
      def self.run(params)
        # custom dropbox folder name
        if params[:dropbox_folder_name]
          dropbox_folder_name = params[:dropbox_folder_name]
          UI.message("Dropbox folder name - #{dropbox_folder_name}")
        end

        # AppBox CLI
        appboxcli = "appboxcli"
        appboxcli_path = `which #{appboxcli}`.strip
        if appboxcli_path.empty?
          UI.user_error!("AppBox CLI not found. Install it from AppBox Preferences > General, or read more here - https://docs.getappbox.com/CommandLineInterface/")
        end

        ipa_path = Actions.lane_context[Actions::SharedValues::IPA_OUTPUT_PATH]
        if ipa_path.nil? || ipa_path.to_s.empty?
          UI.user_error!("No IPA found. Run `gym`/`build_app` before `appbox`, or set lane_context[SharedValues::IPA_OUTPUT_PATH] yourself.")
        end
        UI.user_error!("IPA not found at #{ipa_path}") unless File.exist?(ipa_path)
        UI.message("IPA PATH - #{ipa_path}")

        # Start AppBox
        UI.message("")
        UI.message("Starting AppBox...")
        UI.message("Upload process will start soon. Upload process might take a few minutes. Please don't interrupt the script.")

        # Built as an argv array and run without a shell, so a value containing a
        # quote or a space cannot break the command.
        args = [appboxcli, "--ipa", ipa_path.to_s]

        if params[:emails]
          args += ["--emails", params[:emails].to_s]
          UI.message("Emails - #{params[:emails]}")
        end

        if params[:message]
          args += ["--message", params[:message].to_s]
          UI.message("Message - #{params[:message]}")
        end

        if params[:keep_same_link] == true
          args << "--keepsamelink"
          UI.message("Keep Same Link - #{params[:keep_same_link]}")
        end

        if dropbox_folder_name
          args += ["--dbfolder", dropbox_folder_name.to_s]
          UI.message("Dropbox Folder Name - #{dropbox_folder_name}")
        end

        if params[:slack_webhook_url]
          args += ["--slackwebhook", params[:slack_webhook_url].to_s]
          UI.message("Slack Webhook URL - #{params[:slack_webhook_url]}")
        end

        if params[:ms_teams_webhook_url]
          args += ["--msteamswebhook", params[:ms_teams_webhook_url].to_s]
          UI.message("MS Teams Webhook URL - #{params[:ms_teams_webhook_url]}")
        end

        if params[:webhook_message]
          UI.important("webhook_message is deprecated and ignored since AppBox 4 - the notification text is generated from the build.")
        end

        UI.message("AppBox Command - #{Shellwords.join(args)}")

        # Execute without a shell.
        exit_status = system(*args)

        # Print upload status
        if exit_status
          UI.success("Successfully uploaded the IPA file to DropBox. Check below summary for more details.")
          # Check if share url file exist and print value
          share_url_file_path = File.join(File.expand_path('~'), ".appbox_share_value.json")
          if File.file?(share_url_file_path)
            file = File.read(share_url_file_path)
            share_urls_values = JSON.parse(file)
            Actions.lane_context[SharedValues::APPBOX_IPA_URL] = share_urls_values['APPBOX_IPA_URL']
            Actions.lane_context[SharedValues::APPBOX_SHARE_URL] = share_urls_values['APPBOX_SHARE_URL']
            Actions.lane_context[SharedValues::APPBOX_MANIFEST_URL] = share_urls_values['APPBOX_MANIFEST_URL']
            FastlaneCore::PrintTable.print_values(config: share_urls_values, hide_keys: [], title: "Summary for AppBox")
          end
          UI.success('AppBox finished successfully')
        else
          UI.error('AppBox finished with errors')
          UI.user_error!('AppBox upload failed. Please feel free to open an issue on the project GitHub page, including a description of what is not working. https://github.com/getappbox/fastlane-plugin-appbox/issues/new')
        end
      end

      def self.output
        [
          ['APPBOX_IPA_URL', 'Upload IPA file URL to download IPA file.'],
          ['APPBOX_MANIFEST_URL', 'Manifest file URL for upload application.'],
          ['APPBOX_SHARE_URL', 'AppBox short shareable URL to install uploaded application.']
        ]
      end

      def self.description
        "Deploy Development, Ad-Hoc and In-house (Enterprise) iOS applications directly to the devices from your Dropbox account."
      end

      def self.authors
        ["Vineet Choudhary"]
      end

      def self.details
        "Deploy Development, Ad-Hoc and In-house (Enterprise) iOS applications directly to the devices from your Dropbox account."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :emails,
                                       env_name: "FL_APPBOX_EMAILS",
                                       description: "Comma-separated list of email address that should receive application installation link",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_APPBOX_MESSAGE",
                                       description: "A personal message shown under \"Message from the developer\" in the email, e.g. 'Here is the latest build.'. Sent exactly as written; AppBox 4 does not substitute the {BUILD_NAME}/{BUILD_VERSION}/{BUILD_NUMBER} placeholders AppBox 3 supported",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :keep_same_link,
                                       env_name: "FL_APPBOX_KEEP_SAME_LINK",
                                       description: "This feature will keep same short URL for all future build/IPA uploaded with same bundle identifier. If this option is enabled, you can also download the previous build with the same URL. Read more here - https://docs.getappbox.com/Features/keepsamelink/",
                                       optional: true,
                                       default_value: false,
                                       is_string: false),

          FastlaneCore::ConfigItem.new(key: :dropbox_folder_name,
                                       env_name: "FL_APPBOX_DB_FOLDER_NAME",
                                       description: "You can change the link by providing a Custom Dropbox Folder Name. By default folder name will be the application bundle identifier. So, AppBox will keep the same link for the IPA file available in the same folder. Read more here - https://docs.getappbox.com/Features/keepsamelink/",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :slack_webhook_url,
                                       env_name: "FL_APPBOX_SLACK_WEBHOOK_URL",
                                       description: "Slack Incoming Webhook URL to send notification to a Slack channel",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :ms_teams_webhook_url,
                                       env_name: "FL_APPBOX_MS_TEAMS_WEBHOOK_URL",
                                       description: "Microsoft Teams Incoming Webhook URL to send notification to a Teams channel",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :webhook_message,
                                       env_name: "FL_APPBOX_WEBHOOK_MESSAGE",
                                       description: "Deprecated and ignored since AppBox 4, which generates the notification text from the build. Accepted, with a warning, so existing Fastfiles keep working",
                                       optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
