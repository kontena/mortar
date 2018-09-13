# frozen_string_literal: true

require "clamp"
require_relative "fire_command"
require_relative "yank_command"
require_relative "install_completions_command"

Clamp.allow_options_after_parameters = true

module Mortar
  class RootCommand < Clamp::Command
    banner "mortar - Kubernetes manifest shooter"

    option ['-v', '--version'], :flag, "print mortar version" do
      puts "mortar #{Mortar::VERSION}"
      exit 0
    end

    subcommand "fire", "Fire a shot (of k8s manifests)", FireCommand
    subcommand "yank", "Yank a shot (of k8s manifests)", YankCommand

    subcommand "install-completions", "Install shell autocompletions", InstallCompletionsCommand
  end
end
