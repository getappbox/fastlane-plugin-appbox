describe Fastlane::Actions::AppboxAction do
  let(:ipa) { File.expand_path("../AppBox-Fastlane-Demo-Project/AppBox-Fastlane-Demo.ipa", __dir__) }

  let(:share_values) do
    { "APPBOX_SHARE_URL" => "https://appbox.me/AbCdEf",
      "APPBOX_IPA_URL" => "https://dl.example/app.ipa",
      "APPBOX_MANIFEST_URL" => "https://dl.example/manifest.plist" }
  end

  # Capture the argv the action would run, without running anything.
  def run_with(params, ipa_path: ipa, exit_code: 0, exported: nil)
    captured = nil
    allow(Fastlane::Actions::AppboxAction).to receive(:`).with("which appboxcli").and_return("/usr/local/bin/appboxcli\n")
    allow(Fastlane::Actions::AppboxAction).to receive(:run_cli) do |args|
      captured = args
      exit_code
    end
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(ipa_path).and_return(true)
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(/\.appbox_share_value\.json\z/).and_return(!exported.nil?)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(/\.appbox_share_value\.json\z/).and_return(exported.to_json) if exported
    allow(FastlaneCore::PrintTable).to receive(:print_values)
    Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::IPA_OUTPUT_PATH] = ipa_path
    [:APPBOX_SHARE_URL, :APPBOX_IPA_URL, :APPBOX_MANIFEST_URL].each { |key| Fastlane::Actions.lane_context.delete(key) }

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

  describe "install-page settings" do
    it "leaves every setting to the CLI when none is set" do
      args = run_with({})
      expect(args.grep(/moredetails|ipalink|previousversions|chunksize/)).to be_empty
    end

    it "passes each toggle as its flag when on" do
      args = run_with({ more_details: true, ipa_link: true, previous_versions: true })
      expect(args).to include("--moredetails", "--ipalink", "--previousversions")
    end

    it "passes each toggle as its --no- flag when off" do
      args = run_with({ more_details: false, ipa_link: false, previous_versions: false })
      expect(args).to include("--no-moredetails", "--no-ipalink", "--no-previousversions")
      expect(args).not_to(include("--moredetails", "--ipalink", "--previousversions"))
    end

    it "passes the chunk size in MB" do
      args = run_with({ chunk_size: 50 })
      expect(args[args.index("--chunksize") + 1]).to eq("50")
    end

    it "reads the settings from their environment variables" do
      ENV["FL_APPBOX_MORE_DETAILS"] = "false"
      ENV["FL_APPBOX_CHUNK_SIZE"] = "25"
      begin
        args = run_with({})
        expect(args).to include("--no-moredetails")
        expect(args[args.index("--chunksize") + 1]).to eq("25")
      ensure
        ENV.delete("FL_APPBOX_MORE_DETAILS")
        ENV.delete("FL_APPBOX_CHUNK_SIZE")
      end
    end

    it "rejects a chunk size outside 1-150 MB" do
      [0, 151].each do |size|
        expect { FastlaneCore::Configuration.create(described_class.available_options, { chunk_size: size }) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /chunk_size must be between 1 and 150 MB/)
      end
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

    it "points at the AppBox version when an upload using install-page settings fails" do
      allow(FastlaneCore::UI).to receive(:important)
      expect { run_with({ more_details: true }, exit_code: 64) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /AppBox upload failed/)
      expect(FastlaneCore::UI).to have_received(:important).with(/need AppBox 4\.1\.0 or later/)
    end
  end

  describe "exit codes" do
    it "exports the links when the upload succeeds" do
      run_with({}, exported: share_values)
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPBOX_SHARE_URL]).to eq("https://appbox.me/AbCdEf")
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPBOX_IPA_URL]).to eq("https://dl.example/app.ipa")
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPBOX_MANIFEST_URL]).to eq("https://dl.example/manifest.plist")
    end

    # 111 means the build is live and only the email failed, so the lane must keep its links.
    it "treats 111 as a live build: exports the links and logs the email failure without failing the lane" do
      allow(FastlaneCore::UI).to receive(:error)
      expect { run_with({ emails: "qa@example.com" }, exit_code: 111, exported: share_values) }.not_to(raise_error)
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPBOX_SHARE_URL]).to eq("https://appbox.me/AbCdEf")
      expect(FastlaneCore::UI).to have_received(:error).with(/build is live, but AppBox couldn't send the email to qa@example\.com/)
    end

    it "fails the lane on any other non-zero exit code" do
      [1, 118, 127].each do |code|
        expect { run_with({}, exit_code: code) }.to raise_error(FastlaneCore::Interface::FastlaneError, /AppBox upload failed/)
      end
    end

    it "fails the lane when the CLI could not run at all" do
      expect { run_with({}, exit_code: nil) }.to raise_error(FastlaneCore::Interface::FastlaneError, /AppBox upload failed/)
    end

    it "reads the real exit code of the process it runs" do
      expect(described_class.run_cli(["sh", "-c", "exit 111"])).to eq(111)
      expect(described_class.run_cli(["sh", "-c", "exit 0"])).to eq(0)
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
                            :slack_webhook_url, :ms_teams_webhook_url, :webhook_message,
                            :more_details, :ipa_link, :previous_versions, :chunk_size)
    end

    it "supports iOS only" do
      expect(described_class.is_supported?(:ios)).to be true
      expect(described_class.is_supported?(:android)).to be false
    end
  end
end
