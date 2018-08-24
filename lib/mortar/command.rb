require "clamp"
require "base64"
require_relative "yaml_file"
require_relative "resource_helper"

Clamp.allow_options_after_parameters = true

module Mortar
  class Command < Clamp::Command
    include Mortar::ResourceHelper

    banner "mortar - Kubernetes manifest shooter"

    parameter "NAME", "deployment name"
    parameter "SRC", "source folder"

    option ["--var"], "VAR", "set template variables", multivalued: true
    option ["-d", "--debug"], :flag, "debug"
    option ["--output"], :flag, "only output generated yaml"
    option ["--prune"], :flag, "automatically delete removed resources"
    option ['-v', '--version'], :flag, "print mortar version" do
      puts "mortar #{Mortar::VERSION}"
      exit 0
    end
    option ["--overlay"], "OVERLAY", "overlay dirs", multivalued: true

    LABEL = 'mortar.kontena.io/shot'
    CHECKSUM_ANNOTATION = 'mortar.kontena.io/shot-checksum'

    def execute
      signal_usage_error("#{src} does not exist") unless File.exist?(src)
      resources = process_overlays
      if output?
        puts resources_output(resources)
        exit
      end

      K8s::Stack.new(
        name, resources,
        debug: debug?,
        label: LABEL,
        checksum_annotation: CHECKSUM_ANNOTATION
      ).apply(client, prune: prune?)

      puts "shot #{name} successfully!" if $stdout.tty?
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
          {key.to_sym => value}
        end
      end.inject(&:deep_merge)
    end

    # @return [K8s::Client]
    def client
      return @client if @client

      if ENV['KUBE_TOKEN'] && ENV['KUBE_CA'] && ENV['KUBE_SERVER']
        @client = K8s::Client.new(K8s::Transport.config(build_kubeconfig_from_env))
      elsif ENV['KUBECONFIG']
        @client = K8s::Client.config(K8s::Config.load_file(ENV['KUBECONFIG']))
      elsif File.exist?(File.join(Dir.home, '.kube', 'config'))
        @client = K8s::Client.config(K8s::Config.load_file(File.join(Dir.home, '.kube', 'config')))
      else
        @client = K8s::Client.in_cluster_config
      end
    end

    # @return [K8s::Config]
    def build_kubeconfig_from_env
      token = ENV['KUBE_TOKEN']
      begin
        token = Base64.strict_decode64(token)
      rescue ArgumentError # raised if token is not base64 encoded
      end
      K8s::Config.new(
        clusters: [
          {
            name: 'kubernetes',
            cluster: {
              server: ENV['KUBE_SERVER'],
              certificate_authority_data: ENV['KUBE_CA']
            }
          }
        ],
        users: [
          {
            name: 'mortar',
            user: {
              token: token
            }
          }
        ],
        contexts: [
          {
            name: 'mortar',
            context: {
              cluster: 'kubernetes',
              user: 'mortar'
            }
          }
        ],
        preferences: {},
        current_context: 'mortar'
      )
    end

    # Stringifies all hash keys
    # @return [Hash]
    def stringify_hash(hash)
      JSON.load(JSON.dump(hash))
    end
  end
end