# frozen_string_literal: true

require "clamp"

module Mortar
  class Command < Clamp::Command
    LABEL = 'mortar.kontena.io/shot'
    CHECKSUM_ANNOTATION = 'mortar.kontena.io/shot-checksum'

    option ["-d", "--debug"], :flag, "debug"
  end
end
