# frozen_string_literal: true

module Mortar
  module TTYHelper
    # @return [Pastel]
    def pastel
      @pastel ||= Pastel.new
    end
  end
end
