require "clamp"
require "deep_merge"
require "mortar/version"
require "mortar/command"

autoload :K8s, "k8s-client"
autoload :YAML, "yaml"
autoload :ERB, "erb"
autoload :Rouge, "rouge"
autoload :RecursiveOpenStruct, "recursive-open-struct"

require "extensions/recursive_open_struct/each"

module Mortar
end