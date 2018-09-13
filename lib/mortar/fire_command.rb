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
    option ["--output"], :flag, "only output generated yaml"
    option ["--prune"], :flag, "automatically delete removed resources"
    option ["--overlay"], "OVERLAY", "overlay dirs", multivalued: true

    def execute
      signal_usage_error("#{src} does not exist") unless File.exist?(src)
      resources = process_overlays

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
      resources = load_resources(src)

      overlay_list.each do |overlay|
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

    # @param resources [Array<K8s::Resource>]
    # @return [String]
    def resources_output(resources)
      yaml = ''
      resources.each do |resource|
        yaml << ::YAML.dump(stringify_hash(resource.to_hash))
      end
      return yaml unless $stdout.tty?

      lexer = Rouge::Lexers::YAML.new
      rouge = Rouge::Formatters::Terminal256.new(Rouge::Themes::Github.new)
      rouge.format(lexer.lex(yaml))
    end

    # @return [RecursiveOpenStruct]
    def variables_struct
      return @variables_struct if @variables_struct

      set_hash = {}
      var_list.each do |var|
        k, v = var.split("=", 2)
        set_hash[k] = v
      end
      RecursiveOpenStruct.new(dotted_path_to_hash(set_hash))
    end

    def dotted_path_to_hash(hash)
      hash.map do |pkey, pvalue|
        pkey.to_s.split(".").reverse.inject(pvalue) do |value, key|
          { key.to_sym => value }
        end
      end.inject(&:deep_merge)
    end

    # Stringifies all hash keys
    # @return [Hash]
    def stringify_hash(hash)
      JSON.parse(JSON.dump(hash))
    end
  end
end
