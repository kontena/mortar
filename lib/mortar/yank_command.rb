require_relative "command"
require_relative "mixins/client_helper"
require_relative "mixins/tty_helper"

module Mortar
  class YankCommand < Mortar::Command
    include Mortar::ClientHelper
    include Mortar::TTYHelper

    parameter "NAME", "deployment name"

    option ["--force"], :flag, "use force"

    def execute
      unless force?
        if $stdin.tty?
          print "enter '#{pastel.cyan(name)}' to confirm yank: "
          begin
            signal_error("confirmation did not match #{pastel.cyan(name)}.") unless $stdin.gets.chomp == name
          rescue Interrupt
            puts
            puts "Canceled"
            return
          end
        else
          signal_usage_error '--force required when running in a non-interactive mode'
        end
      end

      K8s::Stack.new(
        name, [],
        debug: debug?,
        label: LABEL,
        checksum_annotation: CHECKSUM_ANNOTATION
      ).prune(client, keep_resources: false)

      puts "yanked #{pastel.cyan(name)} successfully!" if $stdout.tty?
    end
  end
end