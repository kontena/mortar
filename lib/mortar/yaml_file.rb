# frozen_string_literal: true

module Mortar
  # Reads YAML files and optionally performs ERB evaluation
  class YamlFile
    class Namespace
      def initialize(variables)
        variables.each do |key, value|
          singleton_class.send(:define_method, key) { value }
        end
      end

      def with_binding(&block)
        yield binding
      end
    end

    ParseError = Class.new(StandardError)

    attr_reader :content, :filename

    # @param input [String,IO] A IO/File object, a path to a file or string content
    # @param override_filename [String] use string as the filename for parse errors
    def initialize(input, override_filename: nil)
      @filename = override_filename
      if input.respond_to?(:read)
        @content = input.read
        @filename ||= input.respond_to?(:path) ? input.path : input.to_s
      else
        @filename ||= input.to_s
        @content = File.read(input)
      end
    end

    # @return [Array<Hash>]
    def load(variables = {})
      result = YAML.load_stream(read(variables), @filename)
      if result.is_a?(String)
        raise ParseError, "File #{"#{@filename} " if @filename}does not appear to be in YAML format"
      end

      result
    rescue Psych::SyntaxError => ex
      raise ParseError, ex.message
    end

    def dirname
      File.dirname(@filename)
    end

    def basename
      File.basename(@filename)
    end

    def read(variables = {})
      Namespace.new(variables).with_binding do |ns_binding|
        ERB.new(@content, nil, '%<>-').tap { |e| e.location = [@filename, nil] }.result(ns_binding)
      end
    rescue StandardError, ScriptError => ex
      raise ParseError, "#{ex.class.name} : #{ex.message} (#{ex.backtrace.first.gsub(/:in `with_binding'/, '')})"
    end
  end
end
