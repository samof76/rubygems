# frozen_string_literal: true

module Bundler
  class EnvironmentPreserver
    INTENTIONALLY_NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL".freeze
    BUNDLER_KEYS = %w[
      BUNDLE_BIN_PATH
      BUNDLE_GEMFILE
      BUNDLER_VERSION
      GEM_HOME
      GEM_PATH
      MANPATH
      PATH
      RB_USER_INSTALL
      RUBYLIB
      RUBYOPT
    ].map(&:freeze).freeze
    BUNDLER_PREFIX = "BUNDLER_ORIG_".freeze

    def self.from_env
      new(env_to_hash(ENV), BUNDLER_KEYS)
    end

    def self.env_to_hash(env)
      to_hash = env.to_hash
      return to_hash unless Gem.win_platform?

      to_hash.each_with_object({}) {|(k,v), a| a[k.upcase] = v }
    end

    # @param env [Hash]
    # @param keys [Array<String>]
    def initialize(env, keys)
      @original = env
      @keys = keys
      @prefix = BUNDLER_PREFIX
    end

    # Adds a backup of bundler-related keys to ENV
    def backup
      @keys.each do |key|
        value = ENV[key]
        if !value.nil? && !value.empty?
          ENV[@prefix + key] ||= value
        elsif value.nil?
          ENV[@prefix + key] ||= INTENTIONALLY_NIL
        end
      end
    end

    # @return [Hash]
    def restore
      env = @original.clone
      @keys.each do |key|
        value_original = env[@prefix + key]
        next if value_original.nil? || value_original.empty?
        if value_original == INTENTIONALLY_NIL
          env.delete(key)
        else
          env[key] = value_original
        end
        env.delete(@prefix + key)
      end
      env
    end
  end
end
