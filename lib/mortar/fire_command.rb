# frozen_string_literal: true

require "base64"
require_relative "command"
require_relative "yaml_file"
require_relative "mixins/resource_helper"
require_relative "mixins/client_helper"
require_relative "mixins/tty_helper"

module Mortar
  class FireCommand < Mortar::Command
    include Mortar::ResourceHelper
    include Mortar::ClientHelper
    include Mortar::TTYHelper

    parameter "SRC", "source file or directory"
    parameter "NAME", "deployment name"

    option ["--var"], "VAR", "set template variables", multivalued: true
    option ["--label"], "LABEL", "extra labels that are set to all resources", multivalued: true
    option ["--output"], :flag, "only output generated yaml"
    option ["--[no-]prune"], :flag, "automatically delete removed resources", default: true
    option ["--overlay"], "OVERLAY", "overlay dirs", multivalued: true
    option ["-c", "--config"], "CONFIG", "variable and overlay configuration file"

    def default_config
      %w{shot.yml shot.yaml}.find { |path|
        File.readable?(path)
      }
    end

    def load_config
      if config
        signal_usage_error("Cannot read config file from #{path}") unless File.readable?(config)

        @configuration = Config.load(config)
      else
        # No config provided nor the default config file present
        @configuration = Config.new(variables: {}, overlays: [])
      end
    end

    def execute
      signal_usage_error("#{src} does not exist") unless File.exist?(src)

      load_config

      resources = process_overlays
      resources = inject_extra_labels(resources, process_extra_labels)

      if output?
        puts resources_output(resources)
        exit
      end

      if resources.empty?
        warn 'nothing to do!'
        exit
      end

      K8s::Stack.new(
        name, resources,
        debug: debug?,
        label: LABEL,
        checksum_annotation: CHECKSUM_ANNOTATION
      ).apply(client, prune: prune?)

      puts "shot '#{pastel.cyan(name)}' successfully!" if $stdout.tty?
    end

    def process_overlays
      # Reject any resource that do not have kind set
      # Basically means the config or other random yml files found
      resources = load_resources(src).reject { |r| r.kind.nil? }
      @configuration.overlays(overlay_list).each do |overlay|
        overlay_resources = from_files(overlay)
        overlay_resources.each do |overlay_resource|
          match = false
          resources = resources.map { |r|
            if same_resource?(r, overlay_resource)
              match = true
              r.merge(overlay_resource.to_hash)
            else
              r
            end
          }
          resources << overlay_resource unless match
        end
      end

      resources
    end

    # @return [Hash]
    def extra_labels
      return @extra_labels if @extra_labels

      @extra_labels = {}
      label_list.each do |label|
        key, value = label.split('=')
        @extra_labels[key] = value
      end

      @extra_labels
    end

    # @return [Hash]
    def process_extra_labels
      @configuration.labels(extra_labels)
    end

    # @param resources [Array<K8s::Resource>]
    # @param labels [Hash]
    # @return [Array<K8s::Resource>]
    def inject_extra_labels(resources, labels)
      resources.map { |resource|
        resource.merge(
          metadata: {
            labels: labels.to_hash
          }
        )
      }
    end

    # @return [RecursiveOpenStruct]
    def variables_struct
      @variables_struct ||= @configuration.variables(variables_hash)
    end

    def variables_hash
      set_hash = {}
      var_list.each do |var|
        k, v = var.split("=", 2)
        set_hash[k] = v
      end

      dotted_path_to_hash(set_hash)
    end

    def dotted_path_to_hash(hash)
      h = hash.map do |pkey, pvalue|
        pkey.to_s.split(".").reverse.inject(pvalue) do |value, key|
          { key.to_s => value }
        end
      end
      # Safer to return just empty hash instead of nil
      return {} if h.empty?

      h.inject(&:deep_merge)
    end
  end
end
