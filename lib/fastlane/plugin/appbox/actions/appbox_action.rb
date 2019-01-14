require 'fastlane/action'
require_relative '../helper/appbox_helper'

module Fastlane
  module Actions
    class AppboxAction < Action
      def self.run(params)
        UI.message(params)

        ipa_path = Actions.lane_context[ Actions::SharedValues::IPA_OUTPUT_PATH ]
        UI.message("IPA PATH - #{ipa_path}")

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
          UI.message("AppBox Path - #{appbox_path}")

          # Start AppBox
          UI.message("Starting AppBox...")
          if dropbox_folder_name
            exit_status = system("exec #{appbox_path} ipa='#{ipa_path}' email='#{emails}' message='#{message}' keepsamelink=#{keep_same_link} dbfolder='#{dropbox_folder_name}'")
          else
            exit_status = system("exec #{appbox_path} ipa='#{ipa_path}' email='#{emails}' message='#{message}' keepsamelink='#{keep_same_link}'")
          end

          # Print upload status
          if exit_status
            UI.success('AppBox finished successfully')
          else 
            UI.error('AppBox finished with errors')
            UI.message('Please feel free to open an issue on the project GitHub page. Please include a description of what is not working right with your issue. https://github.com/getappbox/fastlane-plugin-appbox/issues/new')
            exit
          end
        else
          UI.error("AppBox not found at path #{appbox_path}. Please download (https://getappbox.com/download) and install appbox first. ")
          exit
        end
        
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
