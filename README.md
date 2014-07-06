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
* generates and populates `database.yml` file
  (no need to ssh to the server and do this manually!)
* zero-config

### Installation

Put the following in your application's `Gemfile`:

    group :development do
      gem 'capistrano', '~> 3.1'
      gem 'capistrano-postgresql', '~> 3.0'
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
[capistrano-safe-deploy-to](https://github.com/bruno-/capistrano-safe-deploy-to)
plugin and don't think about it.

To setup the server, run:

    $ bundle exec cap production setup

Easy, right?

Check below to see what happens in the background.

### How it works

Check here for the full capistrano deployment flow
[http://capistranorb.com/documentation/getting-started/flow/](http://capistranorb.com/documentation/getting-started/flow/).

The following tasks run during the `setup` task:

* `postgresql:create_db_user`<br/>
creates a postgresql user. Password for the user is automatically generated and
used in the next steps.
* `postgresql:create_database`<br/>
creates database for your app.
* `postgresql:generate_database_yml`<br/>
creates a `database.yml` file and copies it to
`#{shared_path}/config/database.yml` on the server.

Also, the plugin ensures `config/database.yml` is symlinked from `shared_path`.
The above tasks are all you need for getting a Rails app to work with PostgreSQL.

### Gotchas

Be sure to remove `config/database.yml` from your application's version control.

### Configuration

This plugin should just work with no configuration whatsoever. However,
configuration is possible. Put all your configs in capistrano stage files i.e.
`config/deploy/production.rb`.

Here's the list of options and the defaults for each option:

* `set :pg_database`<br/>
Name of the database for your app. Defaults to `#{application}_#{stage}`,
example: `myface_production`.

* `set :pg_user`<br/>
Name of the database user. Defaults to whatever is set for `pg_database`
option.

* `set :pg_password`<br/>
Password for the database user. By default this option is not set and a
**new random password** is generated each time you create a new database.<br/>
If you set this option to `"some_secure_password"` - that will be the db user's
password. Keep in mind that having a hardcoded password in `deploy.rb` (or
anywhere in version control) is a bad practice.<br/>
I recommend sticking to the default and generating a new secure and random
password each time a db user is generated. That way you don't have to worry
about it or try to remember it.

* `set :pg_ask_for_password`<br/>
Default `false`. Set this option to `true` if you want to be prompted for the
password when database user is created. This is safer than setting the password
via `pg_password`. The downside is you have to choose and remember
yet another fricking password.<br/>
`pg_password` option has precedence. If it is set,
`pg_ask_for_password` is ignored.

* `set :pg_system_user`<br/>
Default `postgres`. Set this option to the user that owns the postgres process
on your system. Normally the default is fine, but for instance on FreeBSD the
default prostgres user is `pgsql`.

* `set :pg_system_db`<br/>
Default `postgres`. Set this if the system database don't have the standard name.
Usually there should be no reason to change this from the default.

`database.yml` template-only settings:

* `set :pg_pool`<br/>
Pool config in `database.yml` template. Defaults to `5`.

* `set :pg_host`<br/>
`hostname` config in `database.yml` template. Defaults to `localhost`.

* `set :pg_encoding`<br/>
`encoding` config in `database.yml` template. Defaults to `unicode`.

### Customizing the `database.yml` template

This is the default `database.yml` template that gets copied to the capistrano
shared directory on the server:

```yml
<%= fetch :stage %>:
  adapter: postgresql
  encoding: <%= pg_encoding %>
  database: <%= pg_database %>
  pool: <%= pg_pool %>
  username: <%= pg_user %>
  password: '<%= pg_password %>'
  host: <%= pg_host %>
```

If for any reason you want to edit or tweak this template, you can copy it to
`config/deploy/templates/postgresql.yml.erb` with this command:

    $ bundle exec rails g capistrano:postgresql:template

After you edit this newly created file in your repo, it will be used as a
template for `database.yml` on the server.

You can configure the template location. For example:
`set :pg_templates_path, "config"` and the template will be copied to
`config/postgresql.yml.erb`.

### More Capistrano automation?

If you'd like to streamline your Capistrano deploys, you might want to check
these zero-configuration, plug-n-play plugins:

- [capistrano-unicorn-nginx](https://github.com/bruno-/capistrano-unicorn-nginx)<br/>
no-configuration unicorn and nginx setup with sensible defaults
- [capistrano-rbenv-install](https://github.com/bruno-/capistrano-rbenv-install)<br/>
would you like Capistrano to install rubies for you?
- [capistrano-safe-deploy-to](https://github.com/bruno-/capistrano-safe-deploy-to)<br/>
if you're annoyed that Capistrano does **not** create a deployment path for the
app on the server (default `/var/www/myapp`), this is what you need!

### Contributing and bug reports

Contributions and improvements are very welcome. Just open a pull request and
I'll look it up shortly.

If something is not working for you, or you find a bug please report it.

### Thanks

Here are other plugins and people this project was based upon:

* [Matt Bridges](https://github.com/mattdbridges) - capistrano postgresql tasks
from this plugin are heavily based on his
[capistrano-recipes repo](https://github.com/mattdbridges/capistrano-recipes).

### License

[MIT](LICENSE.md)
