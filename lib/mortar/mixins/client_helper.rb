module Mortar
  module ClientHelper
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
      token = Base64.strict_decode64(token)

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
    rescue ArgumentError
      signal_usage_error "KUBE_TOKEN env doesn't seem to be base64 encoded!"
    end
  end
end