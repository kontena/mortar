# frozen_string_literal: true

require_relative "command"
require_relative "mixins/client_helper"
require_relative "mixins/tty_helper"

module Mortar
  class DescribeCommand < Mortar::Command
    include Mortar::ClientHelper
    include Mortar::TTYHelper
    include Mortar::ResourceHelper

    parameter "NAME", "deployment name"

    option ["-o", "--output"], "OUTPUT", "Output format", default: 'table'

    def execute
      resources = client.list_resources(labelSelector: { LABEL => name }).select{ |r|
        r.metadata.labels&.dig(LABEL) == name
      }.uniq{ |r|
        # Kube api returns same object from many api versions...
        "#{r.kind}/#{r.metadata.name}/#{r.metadata.namespace}"
      }.sort{ |a, b| # Sort resources so that non namespaced objects are outputted firts
        if a.metadata.namespace == b.metadata.namespace
          1
        elsif a.metadata.namespace.nil? && !b.metadata.namespace.nil?
          -1
        else
          0
        end
      }

      case output
      when 'table'
        table(resources)
      when 'yaml'
        puts resources_output(resources)
      when 'json'
        puts json_output(resources)
      else
        signal_usage_error "Unknown output format: #{output}"
      end
    end

    def table(resources)
      table = TTY::Table.new %w(NAMESPACE KIND NAME), []
      resources.each do |r|
        table << [r.metadata.namespace || '', r.kind, r.metadata.name]
      end
      puts table.render(:basic)
    end

    def json_output(resources)
      json = JSON.pretty_generate(resources.map(&:to_hash))
      return json unless $stdout.tty?

      lexer = Rouge::Lexers::JSON.new
      rouge = Rouge::Formatters::Terminal256.new(Rouge::Themes::Github.new)
      rouge.format(lexer.lex(json))
    end
  end
end
