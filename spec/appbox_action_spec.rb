describe Fastlane::Actions::AppboxAction do
  let(:ipa) { File.expand_path("../AppBox-Fastlane-Demo-Project/AppBox-Fastlane-Demo.ipa", __dir__) }

  # Capture the argv the action would run, without running anything.
  def run_with(params, ipa_path: ipa)
    captured = nil
    allow(Fastlane::Actions::AppboxAction).to receive(:`).with("which appboxcli").and_return("/usr/local/bin/appboxcli\n")
    allow(Fastlane::Actions::AppboxAction).to receive(:system) do |*args|
      captured = args
      true
    end
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(ipa_path).and_return(true)
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(/\.appbox_share_value\.json\z/).and_return(false)
    Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::IPA_OUTPUT_PATH] = ipa_path

    config = FastlaneCore::Configuration.create(described_class.available_options, params)
    described_class.run(config)
    captured
  end

  describe "the command it builds" do
    it "always passes the IPA path" do
      expect(run_with({})).to eq(["appboxcli", "--ipa", ipa])
    end

    it "passes each option through as its own argument" do
      args = run_with({ emails: "a@example.com", message: "ready", dropbox_folder_name: "MyFolder" })
      expect(args).to include("--emails", "a@example.com")
      expect(args).to include("--message", "ready")
      expect(args).to include("--dbfolder", "MyFolder")
    end

    it "sends keepsamelink as a bare flag only when enabled" do
      expect(run_with({ keep_same_link: true })).to include("--keepsamelink")
      expect(run_with({ keep_same_link: false })).not_to(include("--keepsamelink"))
    end

    it "passes the webhook URLs" do
      args = run_with({ slack_webhook_url: "https://hooks.slack.com/x",
                        ms_teams_webhook_url: "https://teams.example/y" })
      expect(args).to include("--slackwebhook", "https://hooks.slack.com/x")
      expect(args).to include("--msteamswebhook", "https://teams.example/y")
    end

    it "accepts webhook_message but no longer forwards it to the CLI" do
      args = run_with({ webhook_message: "anything at all" })
      expect(args).not_to(include("--webhookmessage"))
      expect(args).not_to(include("anything at all"))
    end

    # The old implementation interpolated into a single-quoted shell string, so
    # an apostrophe produced a command the shell could not parse at all.
    it "survives a value containing quotes and spaces" do
      args = run_with({ message: "Build ready - don't miss it", dropbox_folder_name: "My Folder" })
      expect(args[args.index("--message") + 1]).to eq("Build ready - don't miss it")
      expect(args[args.index("--dbfolder") + 1]).to eq("My Folder")
    end

    it "runs without a shell, so no argument needs escaping" do
      args = run_with({ message: "a; rm -rf /" })
      expect(args.first).to eq("appboxcli")
      expect(args[args.index("--message") + 1]).to eq("a; rm -rf /")
    end
  end

  describe "failure handling" do
    it "raises a fastlane error when the CLI is missing" do
      allow(Fastlane::Actions::AppboxAction).to receive(:`).with("which appboxcli").and_return("\n")
      config = FastlaneCore::Configuration.create(described_class.available_options, {})
      expect { described_class.run(config) }.to raise_error(FastlaneCore::Interface::FastlaneError, /AppBox CLI not found/)
    end

    it "raises when no IPA is in the lane context" do
      allow(Fastlane::Actions::AppboxAction).to receive(:`).with("which appboxcli").and_return("/usr/local/bin/appboxcli\n")
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::IPA_OUTPUT_PATH] = nil
      config = FastlaneCore::Configuration.create(described_class.available_options, {})
      expect { described_class.run(config) }.to raise_error(FastlaneCore::Interface::FastlaneError, /No IPA found/)
    end

    it "raises when the IPA path does not exist" do
      allow(Fastlane::Actions::AppboxAction).to receive(:`).with("which appboxcli").and_return("/usr/local/bin/appboxcli\n")
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::IPA_OUTPUT_PATH] = "/nope/missing.ipa"
      config = FastlaneCore::Configuration.create(described_class.available_options, {})
      expect { described_class.run(config) }.to raise_error(FastlaneCore::Interface::FastlaneError, /IPA not found/)
    end
  end

  describe "the action's contract" do
    it "exports the three AppBox URLs" do
      expect(described_class.output.map(&:first))
        .to contain_exactly("APPBOX_IPA_URL", "APPBOX_MANIFEST_URL", "APPBOX_SHARE_URL")
    end

    it "offers every option the AppBox CLI accepts" do
      expect(described_class.available_options.map(&:key))
        .to contain_exactly(:emails, :message, :keep_same_link, :dropbox_folder_name,
                            :slack_webhook_url, :ms_teams_webhook_url, :webhook_message)
    end

    it "supports iOS only" do
      expect(described_class.is_supported?(:ios)).to be true
      expect(described_class.is_supported?(:android)).to be false
    end
  end
end
