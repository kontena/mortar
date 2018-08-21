
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mortar/version"

Gem::Specification.new do |spec|
  spec.name          = "mortar"
  spec.version       = Mortar::VERSION
  spec.authors       = ["Kontena, Inc"]
  spec.email         = ["info@kontena.io"]

  spec.summary       = "Kubernetes manifest shooter"
  spec.description   = "Kubernetes manifest shooter"
  spec.homepage      = "https://github.com/kontena/k8s-mortar"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "clamp", "~> 1.3"
  spec.add_runtime_dependency "k8s-client", "~> 0.3"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
