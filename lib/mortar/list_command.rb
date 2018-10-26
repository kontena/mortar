# frozen_string_literal: true

require_relative "command"
require_relative "mixins/client_helper"
require_relative "mixins/tty_helper"

module Mortar
  class ListCommand < Mortar::Command
    include Mortar::ClientHelper
    include Mortar::TTYHelper

    option ['-q', '--quiet'], :flag, "only output shot names"

    def execute
      shots = Hash.new(0)

      client.list_resources(labelSelector: LABEL).select{ |r|
        r.metadata.labels&.dig(LABEL)
      }.uniq{ |r|
        # Kube api returns same object from many api versions...
        "#{r.kind}/#{r.metadata.name}/#{r.metadata.namespace}"
      }.each do |resource|
        shot_name = resource.metadata.labels&.dig(LABEL)
        shots[shot_name] += 1
      end

      if quiet?
        shots.each_key do |k|
          puts k
        end
      else
        table = TTY::Table.new %w(NAME RESOURCES), shots.to_a
        puts table.render(:basic)
      end
    end
  end
end
