# Capistrano::PostgreSQL

**Note: this plugin works only with Capistrano 3.** Please check the capistrano
gem version you're using before installing this gem:
`$ bundle show | grep capistrano`
The plugin for Capistrano 2 [is here](https://github.com/bruno-/capistrano2-postgresql).

### About

Capistrano PostgreSQL plugin abstracts and speeds up common administration
tasks for PostgreSQL when deploying rails apps.

Here are the specific things this plugin does for your capistrano deployment
process:

* Creates a new PostgreSQL database and database user on the server
* Generates and populates `database.yml` file on all release nodes (using ssh)
* Support for multi-server setup: separate `db` and `app` nodes ( versions > 4.0 )

**Note**: gem version 4 introduces some breaking changes. If you installed gem
version 3 or below you might want to follow the
[upgrade instructions](https://github.com/capistrano-plugins/capistrano-postgresql/wiki/Upgrade-instructions-for-gem-version-4.0).

### Installation

Put the following in your application's `Gemfile`:

    group :development do
      gem 'capistrano', '~> 3.2.0'
      gem 'capistrano-postgresql', '~> 5.0.0'
    end

Then:

    $ bundle install

### Usage

In a standard RAILS app, you need to put the following in `Capfile` file:

```
require 'capistrano/postgresql' 
```

You need to include ONLY ONE of the following in your config/deploy/*.rb files:

```
set :pg_password, ENV['DATABASE_USER_PASSWORD']
set :pg_ask_for_password, true
set :pg_generate_random_password, true
```

Example config:

```
server 'growtrader.dev', user: 'growtrader', roles: %w{app db}
set :stage, :development
set :branch, 'development'
# ==================
# Postgresql setup
set :pg_without_sudo, false
set :pg_host, 'growtrader.dev'
set :pg_database, 'growtrader'
set :pg_username, 'growtrader'
#set :pg_generate_random_password, true
#set :pg_ask_for_password, true
set :pg_password, ENV['GROWTRADER_PGPASS']
set :pg_extensions, ['citext','hstore']
set :pg_encoding, 'UTF-8'
set :pg_pool, '100'
```

Finally, to setup the server(s), run:

    $ bundle exec cap production setup

### Requirements

* Be sure to remove `config/database.yml` from your application's version control.
* Your pg_hba.conf must include `local all all trust`
* Make sure the `deploy_to` path exists and has the right privileges on your servers. The ~ symbol (i.e. `~/myapp`) is not supported.
* Within your app/config/deploy/{env}.rb files, you need to specify at least one :app and one :db server. 
* If you have multiple :db role hosts, it's necessary to specify `:primary => true` on the end of your primary :db server.

### How it works

[How the plugin works](https://github.com/capistrano-plugins/capistrano-postgresql/wiki/How-it-works)

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

If something is not working for you, or you find a bug, please report it.

### Thanks

Here are other plugins and people this project was based upon:

* [Matt Bridges](https://github.com/mattdbridges) - capistrano postgresql tasks
from this plugin are heavily based on his
[capistrano-recipes repo](https://github.com/mattdbridges/capistrano-recipes).

### License

[MIT](LICENSE.md)
