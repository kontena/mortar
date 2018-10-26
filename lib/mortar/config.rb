# frozen_string_literal: true

module Mortar
  class Config
    class ConfigError < StandardError; end

    def self.load(path)
      cfg = YAML.safe_load(File.read(path))

      raise ConfigError, "Failed to load config, check config file syntax" unless cfg.is_a? Hash
      raise ConfigError, "Failed to load config, overlays needs to be an array" if cfg.key?('overlays') && !cfg['overlays'].is_a?(Array)

      new(variables: cfg['variables'] || {}, overlays: cfg['overlays'] || [])
    end

    def initialize(variables: {}, overlays: [])
      @variables = variables
      @overlays = overlays
    end

    # @return [RecursiveOpenStruct]
    def variables(other = {})
      hash = @variables.dup
      hash.deep_merge!(other)
      RecursiveOpenStruct.new(hash, recurse_over_arrays: true)
    end

    def overlays(other = [])
      return @overlays unless other

      (@overlays + other).uniq.compact
    end
  end
end
