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
        unless prompt.ask("enter '#{pastel.cyan(name)}' to confirm yank:") == name
          signal_error("confirmation did not match #{pastel.cyan(name)}.")
        end
      end

      K8s::Stack.new(
        name, [],
        debug: debug?,
        label: LABEL,
        checksum_annotation: CHECKSUM_ANNOTATION
      ).prune(client, keep_resources: false)

      puts "yanked #{pastel.cyan(name)} successfully!" if $stdout.tty?

    rescue TTY::Reader::InputInterrupt
    end
  end
end