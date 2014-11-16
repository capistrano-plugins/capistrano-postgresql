# Capistrano::PostgreSQL

**Note: this plugin works only with Capistrano 3.** Plase check the capistrano
gem version you're using before installing this gem:
`$ bundle show | grep capistrano`

Plugin for Capistrano 2 [is here](https://github.com/bruno-/capistrano2-postgresql).

### About

Capistrano PostgreSQL plugin abstracts and speeds up common administration
tasks for PostgreSQL when deploying rails apps.

Here are the specific things this plugin does for your capistrano deployment
process:

* creates a new PostgreSQL database and database user on the server
* generates and populates `database.yml` file on all release nodes
  (no need to ssh to the server and do this manually!)
* zero-config
* support for multi-server setup: separate `db` and `app` nodes (from version 4.0)

**Note**: gem version 4 introduces some breaking changes. If you installed gem
version 3 or below you might want to follow the
[upgrade instructions](https://github.com/capistrano-plugins/capistrano-postgresql/wiki/Upgrade-instructions-for-gem-version-4.0).

### Installation

Put the following in your application's `Gemfile`:

    group :development do
      gem 'capistrano', '~> 3.2.0'
      gem 'capistrano-postgresql', '~> 4.2.0'
    end

Then:

    $ bundle install

### Usage

If you're deploying a standard rails app, all you need to do is put
the following in `Capfile` file:

    require 'capistrano/postgresql'

Make sure the `deploy_to` path exists and has the right privileges on the
server (i.e. `/var/www/myapp`).<br/>
Or just install
[capistrano-safe-deploy-to](https://github.com/capistrano-plugins/capistrano-safe-deploy-to)
plugin and don't think about it.

To setup the server(s), run:

    $ bundle exec cap production setup

### Gotchas

Be sure to remove `config/database.yml` from your application's version control.

### How it works

[How the plugin works](https://github.com/capistrano-plugins/capistrano-postgresql/wiki/How-it-works)
wiki page contains a list of actions the plugin executes.

Read it only if you want to learn more about the plugin internals.

### Configuration

A full
[list of configuration options](https://github.com/capistrano-plugins/capistrano-postgresql/wiki/Configuration-options).

The list can be overwhelming so consult it only if you're looking for something
specific.

### Customizing the `database.yml` template

[Wiki page about the database.yml format](https://github.com/capistrano-plugins/capistrano-postgresql/wiki/Customizing-the-database.yml-template).

### More Capistrano automation?

Check out [capistrano-plugins](https://github.com/capistrano-plugins) github org.

### Contributing and bug reports

Contributions and improvements are very welcome.

If something is not working for you, or you find a bug please report it.

### Thanks

Here are other plugins and people this project was based upon:

* [Matt Bridges](https://github.com/mattdbridges) - capistrano postgresql tasks
from this plugin are heavily based on his
[capistrano-recipes repo](https://github.com/mattdbridges/capistrano-recipes).

### License

[MIT](LICENSE.md)
