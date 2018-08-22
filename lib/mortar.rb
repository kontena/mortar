require "clamp"
require "mortar/version"
require "mortar/command"

autoload :K8s, "k8s-client"
autoload :YAML, "yaml"
autoload :ERB, "erb"
autoload :Rouge, "rouge"
autoload :RecursiveOpenStruct, "recursive-open-struct"

module Mortar
end