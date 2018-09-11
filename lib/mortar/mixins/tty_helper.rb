module Mortar
  module TTYHelper
    # @return [TTY::Prompt]
    def prompt
      @prompt ||= TTY::Prompt.new
    end

    # @return [Pastel]
    def pastel
      @pastel ||= Pastel.new
    end
  end
end