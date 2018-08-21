require "clamp"
require "base64"
require_relative "yaml_file"

Clamp.allow_options_after_parameters = true

module Mortar
  class Command < Clamp::Command
    banner "mortar - Kubernetes manifest shooter"

    option ['-v', '--version'], :flag, "print mortar version" do
      puts "mortar #{Mortar::VERSION}"
      exit 0
    end
    option ["-d", "--debug"], :flag, "debug"

    parameter "NAME", "deployment name"
    parameter "SRC", "source folder"

    LABEL = 'mortar.kontena.io/shot'
    CHECKSUM_ANNOTATION = 'mortar.kontena.io/shot-checksum'

    def execute
      signal_usage_error("#{src} is not a directory") unless File.exist?(src)
      stat = File.stat(src)
      signal_usage_error("#{src} is not a directory") unless stat.directory?

      resources = from_files(src)

      #K8s::Logging.verbose!
      K8s::Stack.new(
        name, resources,
        debug: debug?,
        label: LABEL, 
        checksum_annotation: CHECKSUM_ANNOTATION
      ).apply(client)
      puts "pushed #{name} successfully!"
    end

    # @param filename [String] file path
    # @return [Array<K8s::Resource>]
    def from_files(path)
      Dir.glob("#{path}/*.{yml,yaml}").sort.map { |file| self.from_file(file) }.flatten
    end

    # @param filename [String] file path
    # @return [K8s::Resource]
    def from_file(filename)
      K8s::Resource.new(YamlFile.new(filename).load)
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
              token: ENV['KUBE_TOKEN']
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
  end
end