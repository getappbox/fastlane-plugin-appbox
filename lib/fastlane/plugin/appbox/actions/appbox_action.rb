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
      # Install-page toggles: option key, appboxcli flag, log label. Unset ones are
      # left out so the CLI falls back to the AppBox app setting, then its default.
      INSTALL_PAGE_TOGGLES = [
        [:more_details, "moredetails", "More Details"],
        [:ipa_link, "ipalink", "IPA Link"],
        [:previous_versions, "previousversions", "Previous Versions"]
      ].freeze

      # appboxcli's exit code when the build is live but the email could not be sent.
      EMAIL_FAILED_EXIT_CODE = 111

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

        page_args = install_page_args(params)
        args += page_args

        UI.message("AppBox Command - #{Shellwords.join(args)}")

        exit_code = run_cli(args)

        # Print upload status
        if [0, EMAIL_FAILED_EXIT_CODE].include?(exit_code)
          UI.success("Successfully uploaded the IPA file to DropBox. Check below summary for more details.")
          export_share_values
          if exit_code == EMAIL_FAILED_EXIT_CODE
            UI.error("The build is live, but AppBox couldn't send the email to #{params[:emails]}. Share APPBOX_SHARE_URL from the summary above with your testers.")
          else
            UI.success('AppBox finished successfully')
          end
        else
          UI.error('AppBox finished with errors')
          unless page_args.empty?
            UI.important("more_details, ipa_link, previous_versions and chunk_size need AppBox 4.1.0 or later. If the CLI reported an unknown option, update AppBox.")
          end
          UI.user_error!('AppBox upload failed. Please feel free to open an issue on the project GitHub page, including a description of what is not working. https://github.com/getappbox/fastlane-plugin-appbox/issues/new')
        end
      end

      # Runs appboxcli without a shell and returns its exit code.
      def self.run_cli(args)
        system(*args)
        $?.exitstatus
      end

      def self.export_share_values
        share_url_file_path = File.join(File.expand_path('~'), ".appbox_share_value.json")
        return unless File.file?(share_url_file_path)

        share_urls_values = JSON.parse(File.read(share_url_file_path))
        Actions.lane_context[SharedValues::APPBOX_IPA_URL] = share_urls_values['APPBOX_IPA_URL']
        Actions.lane_context[SharedValues::APPBOX_SHARE_URL] = share_urls_values['APPBOX_SHARE_URL']
        Actions.lane_context[SharedValues::APPBOX_MANIFEST_URL] = share_urls_values['APPBOX_MANIFEST_URL']
        FastlaneCore::PrintTable.print_values(config: share_urls_values, hide_keys: [], title: "Summary for AppBox")
      end

      def self.install_page_args(params)
        args = []

        INSTALL_PAGE_TOGGLES.each do |key, flag, label|
          next if params[key].nil?

          args << (params[key] ? "--#{flag}" : "--no-#{flag}")
          UI.message("#{label} - #{params[key]}")
        end

        if params[:chunk_size]
          args += ["--chunksize", params[:chunk_size].to_s]
          UI.message("Chunk Size - #{params[:chunk_size]} MB")
        end

        args
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
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :more_details,
                                       env_name: "FL_APPBOX_MORE_DETAILS",
                                       description: "Show the expanded build details on the install page (minimum iOS version, supported devices, build type, IPA size and provisioning profile). Unset uses the AppBox app setting, then on. Requires AppBox 4.1.0 or later",
                                       optional: true,
                                       type: Fastlane::Boolean),

          FastlaneCore::ConfigItem.new(key: :ipa_link,
                                       env_name: "FL_APPBOX_IPA_LINK",
                                       description: "Show the direct IPA download link on the install page. Unset uses the AppBox app setting, then off. Requires AppBox 4.1.0 or later",
                                       optional: true,
                                       type: Fastlane::Boolean),

          FastlaneCore::ConfigItem.new(key: :previous_versions,
                                       env_name: "FL_APPBOX_PREVIOUS_VERSIONS",
                                       description: "Keep earlier builds listed on the install page. Unset uses the AppBox app setting, then on. Requires AppBox 4.1.0 or later",
                                       optional: true,
                                       type: Fastlane::Boolean),

          FastlaneCore::ConfigItem.new(key: :chunk_size,
                                       env_name: "FL_APPBOX_CHUNK_SIZE",
                                       description: "Dropbox upload chunk size in MB, from 1 to 150. Unset uses the AppBox app setting, then 100. Requires AppBox 4.1.0 or later",
                                       optional: true,
                                       type: Integer,
                                       verify_block: proc do |value|
                                         UI.user_error!("chunk_size must be between 1 and 150 MB, got #{value}") unless (1..150).cover?(value)
                                       end)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
