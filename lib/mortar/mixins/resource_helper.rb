# frozen_string_literal: true

module Mortar
  module ResourceHelper
    # @param filename [String] file path
    # @return [Array<K8s::Resource>]
    def from_files(path)
      Dir.glob("#{path}/*.{yml,yaml,yml.erb,yaml.erb}").sort.map { |file|
        from_file(file)
      }.flatten
    end

    # @param filename [String] file path
    # @return [Array<K8s::Resource>]
    def from_file(filename)
      variables = { name: name, var: variables_struct }
      resources = YamlFile.new(filename).load(variables)
      resources.map { |r| K8s::Resource.new(r) }
    rescue Mortar::YamlFile::ParseError => exc
      signal_usage_error exc.message
    end

    def load_resources(src)
      File.directory?(src) ? from_files(src) : from_file(src)
    end

    # Checks if the two resource refer to the same resource. Two resources refer to same only if following match:
    # - namespace
    # - apiVersion
    # - kind
    # - name (in metadata)
    # @param a [K8s::Resource]
    # @param b [K8s::Resource]
    # @return [TrueClass]
    def same_resource?(resource_a, resource_b)
      resource_a.namespace == resource_b.namespace &&
        resource_a.apiVersion == resource_b.apiVersion &&
        resource_a.kind == resource_b.kind &&
        resource_a.metadata[:name] == resource_b.metadata[:name]
    end
  end
end
