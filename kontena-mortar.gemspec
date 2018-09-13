
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mortar/version"

Gem::Specification.new do |spec|
  spec.name          = "kontena-mortar"
  spec.version       = Mortar::VERSION
  spec.authors       = ["Kontena, Inc"]
  spec.email         = ["info@kontena.io"]

  spec.summary       = "Kubernetes manifest shooter"
  spec.description   = "Kubernetes manifest shooter"
  spec.homepage      = "https://github.com/kontena/mortar"
  spec.license       = "Apache-2.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.post_install_message = "To install shell auto-completions, use:\n  mortar install-completions"

  spec.add_runtime_dependency "clamp", "~> 1.3"
  spec.add_runtime_dependency "k8s-client", "~> 0.4.1"
  spec.add_runtime_dependency "rouge", "~> 3.2"
  spec.add_runtime_dependency "deep_merge", "~> 1.2"
  spec.add_runtime_dependency "pastel", "~> 0.7.2"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.57"
end

