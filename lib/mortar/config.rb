# frozen_string_literal: true

module Mortar
  class Config
    class ConfigError < StandardError; end

    def self.load(path)
      cfg = YAML.safe_load(File.read(path))

      raise ConfigError, "Failed to load config, check config file syntax" unless cfg.is_a? Hash
      raise ConfigError, "Failed to load config, overlays needs to be an array" if cfg.key?('overlays') && !cfg['overlays'].is_a?(Array)

      if cfg.key?('labels')
        raise ConfigError, "Failed to load config, labels needs to be a hash" if !cfg['labels'].is_a?(Hash)
        raise ConfigError, "Failed to load config, label values need to be strings" if cfg['labels'].values.any? { |value| !value.is_a?(String) }
      end

      new(
        variables: cfg['variables'] || {},
        overlays: cfg['overlays'] || [],
        labels: cfg['labels'] || {}
      )
    end

    def initialize(variables: {}, overlays: [], labels: {})
      @variables = variables
      @overlays = overlays
      @labels = labels
    end

    # @param other [Hash]
    # @return [RecursiveOpenStruct]
    def variables(other = {})
      hash = @variables.dup
      hash.deep_merge!(other)
      RecursiveOpenStruct.new(hash, recurse_over_arrays: true)
    end

    # @param other [Array<Object>]
    # @return [Array<Object>]
    def overlays(other = [])
      return @overlays unless other

      (@overlays + other).uniq.compact
    end

    # @param other [Hash]
    # @return [RecursiveOpenStruct]
    def labels(other = {})
      hash = @labels.dup
      hash.merge!(other)
      RecursiveOpenStruct.new(hash)
    end
  end
end
