module Mortar
  class InstallCompletionsCommand < Mortar::Command
    include Mortar::TTYHelper

    DEFAULT_PATHS = [
      '/etc/bash_completion.d/mortar.bash',
      '/usr/local/etc/bash_completion.d/mortar.bash',
      '/usr/share/zsh/site-functions/_mortar',
      '/usr/local/share/zsh/site-functions/_mortar',
      '/usr/local/share/zsh-completions/_mortar',
      File.join(Dir.home, '.bash_completion.d', 'mortar.bash')
    ].freeze

    COMPLETION_FILE_PATH = File.expand_path(
      '../../opt/bash-completion.sh',
      Pathname.new(__dir__).realpath
    ).freeze

    banner 'Installs bash/zsh auto completion script'

    option '--remove', :flag, 'Remove completion script from known locations'

    def execute
      return uninstall if remove?

      installed = []

      DEFAULT_PATHS.each do |path|
        if File.directory?(File.dirname(path))
          begin
            FileUtils.ln_sf(COMPLETION_FILE_PATH, path)
            installed << path
          rescue Errno::EACCES, Errno::EPERM
          end
        end
      end

      if installed.empty?
        warn "Installation failed"
        warn "Try with sudo or set up user bash completions in ~/.bash_completion to include files from ~/.bash_completion.d"
        exit 1
      else
        puts "Completions installed to:"
        installed.each do |path|
          puts "  - #{path}"
        end
        puts
        puts "The completions will be reloaded when you start a new shell."
        puts "To load now, use:"
        puts pastel.cyan("  source \"#{COMPLETION_FILE_PATH}\"")
        exit 0
      end
    end

    def uninstall
      failures = false
      DEFAULT_PATHS.each do |path|
        begin
          if File.exist?(path)
            File.unlink(path)
            puts "Removed #{path}"
          end
        rescue Errno::EACCESS, Errno::EPERM
          failures = true
          warn "Failed to remove #{path} : permission denied"
        end
      end
      exit 1 unless failures
    end
  end
end
