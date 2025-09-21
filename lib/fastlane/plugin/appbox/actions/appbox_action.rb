require "json"
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

        #custom dropbox folder name
        if params[:dropbox_folder_name]
          dropbox_folder_name = params[:dropbox_folder_name]
          UI.message("Dropbox folder name - #{dropbox_folder_name}")
        end

        #AppBox CLI
        appboxcli = "appboxcli"
        appboxcli_path = `which #{appboxcli}`.strip
        if appboxcli_path.empty?
          UI.error("AppBox CLI not found. Please install AppBox CLI first. Read more here - https://docs.getappbox.com/Installation/MacOS/#command-line-interface-cli")
          exit
        end

        ipa_path = Actions.lane_context[ Actions::SharedValues::IPA_OUTPUT_PATH ]
        ipa_file_name = File.basename(ipa_path)
        UI.message("IPA PATH - #{ipa_path}")

        # Start AppBox
        UI.message("")
        UI.message("Starting AppBox...")
        UI.message("Upload process will start soon. Upload process might take a few minutes. Please don't interrupt the script.")

        command = "#{appboxcli} --ipa '#{ipa_path}'"

        #Add emails param in command
        if params[:emails]
          command << " --emails '#{params[:emails]}'"
          UI.message("Emails - #{params[:emails]}")
        end

        #Add message param in command
        if params[:message]
          command << " --message '#{params[:message]}'"
          UI.message("Message - #{params[:message]}")
        end

        #Add Keep Same Link param in command
        if params[:keep_same_link] == true
          command << " --keepsamelink"
          UI.message("Keep Same Link - #{params[:keep_same_link]}")
        end

        #Add dropbox folder name param in command
        if dropbox_folder_name
          command << " --dbfolder '#{dropbox_folder_name}'"
          UI.message("Dropbox Folder Name - #{dropbox_folder_name}")
        end

        #Add Slack Webhook URL param in command
        if params[:slack_webhook_url]
          command << " --slackwebhook '#{params[:slack_webhook_url]}'"
          UI.message("Slack Webhook URL - #{params[:slack_webhook_url]}")
        end

        #Add MS Teams Webhook URL param in command
        if params[:ms_teams_webhook_url]
          command << " --msteamswebhook '#{params[:ms_teams_webhook_url]}'"
          UI.message("MS Teams Webhook URL - #{params[:ms_teams_webhook_url]}")
        end

        #Add Webhook Message param in command
        if params[:webhook_message]
          command << " --webhookmessage '#{params[:webhook_message]}'"
          UI.message("Webhook Message - #{params[:webhook_message]}")
        end

        UI.message("AppBox Command - #{command}")
        
        # Execute command
        exit_status = system("exec #{command}")
        
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
          UI.message('Please feel free to open an issue on the project GitHub page. Please include a description of what is not working right with your issue. https://github.com/getappbox/fastlane-plugin-appbox/issues/new')
          exit
        end
      end

      def self.output
        [
          ['APPBOX_IPA_URL', 'Upload IPA file URL to download IPA file.'],
          ['APPBOX_MANIFEST_URL', 'Manifest file URL for upload application.'],
          ['APPBOX_SHARE_URL', 'AppBox short shareable URL to install uploaded application.'],
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
                                       description: "Attach personal message in the email. Supported Keywords: The {BUILD_NAME} - For Build Name, {BUILD_VERSION} - For Build Version, and {BUILD_NUMBER} - For Build Number",
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
                                       description: "Custom message to send along with Slack or Microsoft Teams notification. Supported Keywords: {BUILD_NAME}, {BUILD_VERSION}, {BUILD_NUMBER}, {SHARE_URL}",
                                       optional: true),
        ]
      end

      def self.is_supported?(platform)
        [:ios].include? platform
      end
    end
  end
end
