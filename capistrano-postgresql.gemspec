# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/postgresql/version'

Gem::Specification.new do |gem|
  gem.name          = "capistrano-postgresql"
  gem.version       = Capistrano::Postgresql::VERSION
  gem.authors       = ["Bruno Sutic"]
  gem.email         = ["bruno.sutic@gmail.com"]
  gem.description   = <<-EOF.gsub(/^\s+/, '')
    Capistrano tasks for PostgreSQL configuration and management for Rails
    apps. Manages `database.yml` template on the server.

    Works with Capistrano 3 (only!). For Capistrano 2 support see:
    https://github.com/bruno-/capistrano2-postgresql
  EOF
  gem.summary       = %q{Creates application database user and `database.yml` on the server. No SSH login required!}
  gem.homepage      = "https://github.com/capistrano-plugins/capistrano-postgresql"

  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]

  gem.add_dependency 'capistrano', '>= 3.0'

  gem.add_development_dependency "rake"
end
