module Mortar
  module ResourceHelper
    # @param filename [String] file path
    # @return [Array<K8s::Resource>]
    def from_files(path)
      Dir.glob("#{path}/*.{yml,yaml,yml.erb,yaml.erb}").sort.map { |file|
          self.from_file(file)
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
      stat = File.stat(src)
      if stat.directory?
        resources = from_files(src)
      else
        resources = from_file(src)
      end

      resources
    end

    # Checks if the two resource refer to the same resource. Two resources refer to same only if following match:
    # - namespace
    # - apiVersion
    # - kind
    # - name (in metadata)
    # @param a [K8s::Resource]
    # @param b [K8s::Resource]
    # @return [TrueClass]
    def same_resource?(a, b)
      return true if a.namespace == b.namespace && a.apiVersion == b.apiVersion && a.kind == b.kind && a.metadata[:name] == b.metadata[:name]

      false
    end
  end
end