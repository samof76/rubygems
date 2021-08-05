# frozen_string_literal: true

RSpec.describe Bundler::EnvironmentPreserver do
  describe "#backup" do
    before do
      preserver = described_class.new(env, ["foo"])
      @previous_env = ENV.to_hash
      preserver.backup
    end

    let(:env) do
      ENV["foo"] = "my-foo"
      ENV["bar"] = "my-bar"
      described_class.env_to_hash(ENV)
    end

    it "should create backup entries" do
      expect(ENV["BUNDLER_ORIG_foo"]).to eq("my-foo")
    end

    it "should keep the original entry" do
      expect(ENV["foo"]).to eq("my-foo")
    end

    it "should not create backup entries for unspecified keys" do
      expect(ENV.key?("BUNDLER_ORIG_bar")).to eq(false)
    end

    it "should not affect the original env" do
      expect(ENV.keys.sort - ["BUNDLER_ORIG_foo"]).to eq(@previous_env.keys.sort)
    end

    context "when a key is empty" do
      let(:env) do
        ENV["foo"] = ""
        described_class.env_to_hash(ENV)
      end

      it "should not create backup entries" do
        expect(ENV).not_to have_key "BUNDLER_ORIG_foo"
      end
    end

    context "when an original key is set" do
      let(:env) do
        ENV["foo"] = "my-foo"
        ENV["BUNDLER_ORIG_foo"] = "orig-foo"
        described_class.env_to_hash(ENV)
      end

      it "should keep the original value in the BUNDLER_ORIG_ variable" do
        expect(ENV["BUNDLER_ORIG_foo"]).to eq("orig-foo")
      end

      it "should keep the variable" do
        expect(ENV["foo"]).to eq("my-foo")
      end
    end
  end

  describe "#restore" do
    let(:preserver) { described_class.new(env, ["foo"]) }

    subject { preserver.restore }

    context "when an original key is set" do
      let(:env) { { "foo" => "my-foo", "BUNDLER_ORIG_foo" => "orig-foo" } }

      it "should restore the original value" do
        expect(subject["foo"]).to eq("orig-foo")
      end

      it "should delete the backup value" do
        expect(subject.key?("BUNDLER_ORIG_foo")).to eq(false)
      end
    end

    context "when no original key is set" do
      let(:env) { { "foo" => "my-foo" } }

      it "should keep the current value" do
        expect(subject["foo"]).to eq("my-foo")
      end
    end

    context "when the original key is empty" do
      let(:env) { { "foo" => "my-foo", "BUNDLER_ORIG_foo" => "" } }

      it "should keep the current value" do
        expect(subject["foo"]).to eq("my-foo")
      end
    end
  end
end
