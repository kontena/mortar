# frozen_string_literal: true

require "clamp"
require "deep_merge"
require "mortar/version"
require "mortar/root_command"

autoload :K8s, "k8s-client"
autoload :YAML, "yaml"
autoload :ERB, "erb"
autoload :Rouge, "rouge"
autoload :RecursiveOpenStruct, "recursive-open-struct"
autoload :Pastel, "pastel"
autoload :Pathname, "pathname"
autoload :FileUtils, "fileutils"

require "extensions/recursive_open_struct/each"

module Mortar
end
