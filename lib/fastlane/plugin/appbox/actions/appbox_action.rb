require "json"
require 'fastlane/action'
require_relative '../helper/appbox_helper'

module Fastlane
  module Actions
    module SharedValues
      APPBOX_IPA_URL = :APPBOX_IPA_URL
      APPBOX_SHARE_URL = :APPBOX_SHARE_URL
      APPBOX_MANIFEST_URL = :APPBOX_MANIFEST_URL
      APPBOX_LONG_SHARE_URL = :APPBOX_LONG_SHARE_URL
    end

    class AppboxAction < Action
      def self.run(params)
        #emails param
        if params[:emails]
          emails = params[:emails]
          UI.message("Emails - #{emails}")
        end

        #developer personal message param
        if params[:message]
          message = params[:message]
          UI.message("Message - #{message}")
        end

        #keep same linkparam
        if params[:keep_same_link]
          keep_same_link = params[:keep_same_link]
          UI.message("Keep Same Link - #{keep_same_link}")
        end

        #custom dropbox folder name
        if params[:dropbox_folder_name]
          dropbox_folder_name = params[:dropbox_folder_name]
          UI.message("Dropbox folder name - #{dropbox_folder_name}")
        end

        #AppBox Path
        if params[:appbox_path]
          appbox_path = "#{params[:appbox_path]}/Contents/MacOS/AppBox"
        else
          appbox_path =  "/Applications/AppBox.app/Contents/MacOS/AppBox"
        end

        #Check if AppBox exist at given path 
        if File.file?(appbox_path)
          UI.message("")
          UI.message("AppBox Path - #{appbox_path}")

          ipa_path = Actions.lane_context[ Actions::SharedValues::IPA_OUTPUT_PATH ]
          ipa_file_name = File.basename(ipa_path)
          UI.message("IPA PATH - #{ipa_path}")

          # Copy ipa file into AppBox temporary directory
          appbox_data_dir = File.expand_path("~/Library/Containers/com.developerinsider.AppBox/Data")
          appbox_temp_path = File.join(appbox_data_dir, "tmp")
          UI.message("Copying IPA file to AppBox temporary directory - #{appbox_temp_path}")
          FileUtils.cp ipa_path, appbox_temp_path
          temp_ipa_path = File.join(appbox_temp_path, ipa_file_name)

          # Start AppBox
          UI.message("")
          UI.message("Starting AppBox...")
          UI.message("Upload process will start soon. Upload process might take a few minutes. Please don't interrupt the script.")
          if dropbox_folder_name
            exit_status = system("exec #{appbox_path} ipa='#{temp_ipa_path}' email='#{emails}' message='#{message}' keepsamelink=#{keep_same_link} dbfolder='#{dropbox_folder_name}'")
          else
            exit_status = system("exec #{appbox_path} ipa='#{temp_ipa_path}' email='#{emails}' message='#{message}' keepsamelink='#{keep_same_link}'")
          end

          # Print upload status
          if exit_status
            UI.success("Successfully uploaded the IPA file to DropBox. Check below summary for more details.")
            # Check if share url file exist and print value
            share_url_file_path = File.join(appbox_data_dir, "Documents", ".appbox_share_value.json")
            if File.file?(share_url_file_path)
              file = File.read(share_url_file_path)
              share_urls_values = JSON.parse(file)

              Actions.lane_context[SharedValues::APPBOX_IPA_URL] = share_urls_values['APPBOX_IPA_URL']
              Actions.lane_context[SharedValues::APPBOX_SHARE_URL] = share_urls_values['APPBOX_SHARE_URL']
              Actions.lane_context[SharedValues::APPBOX_MANIFEST_URL] = share_urls_values['APPBOX_MANIFEST_URL']

              FastlaneCore::PrintTable.print_values(config: share_urls_values, hide_keys: [], title: "Summary for AppBox")
            end
            clean_temporary_files(appbox_temp_path)
            UI.success('AppBox finished successfully')
          else 
            clean_temporary_files(appbox_temp_path)
            UI.error('AppBox finished with errors')
            UI.message('Please feel free to open an issue on the project GitHub page. Please include a description of what is not working right with your issue. https://github.com/getappbox/fastlane-plugin-appbox/issues/new')
            exit
          end
        else
          UI.error("AppBox not found at path #{appbox_path}. Please download (https://getappbox.com/download) and install appbox first. ")
          exit
        end
        
      end

      # Delete all files/folders in AppBox temporary directory
      def self.clean_temporary_files(appbox_temp_path)
        UI.message("Cleaning AppBox temporary directory - #{appbox_temp_path}")
        if File.directory?(appbox_temp_path)
          Dir.foreach(appbox_temp_path) do |file|
            next if file == '.' or file == '..'
            file_path = File.join(appbox_temp_path, file)
            if File.file?(file_path)
              File.delete(file_path)
            else
              FileUtils.rm_rf(file_path)
            end
          end
        end
      end

      def self.output
        [
          ['APPBOX_IPA_URL', 'Upload IPA file URL to download IPA file.'],
          ['APPBOX_MANIFEST_URL', 'Manifest file URL for upload application.'],
          ['APPBOX_SHARE_URL', 'AppBox short shareable URL to install uploaded application.'],
          ['APPBOX_LONG_SHARE_URL', 'AppBox long shareable URL to install uploaded application.']
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
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :appbox_path,
                                       env_name: "FL_APPBOX_PATH",
                                       description: "If you've setup AppBox in the different directory then you need to mention that here. Default is '/Applications/AppBox.app'",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_APPBOX_MESSAGE",
                                       description: "Attach personal message in the email. Supported Keywords: The {PROJECT_NAME} - For Project Name, {BUILD_VERSION} - For Build Version, and {BUILD_NUMBER} - For Build Number",
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
        ]
      end

      def self.is_supported?(platform)
        [:ios].include? platform
      end
    end
  end
end
