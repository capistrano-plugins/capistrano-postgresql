# Capistrano 2 PostgreSQL

**Note: this plugin works only with Capistrano 2.** Plase check the capistrano
gem version you're using before installing this gem:
`$ bundle show | grep capistrano`

Plugin for Capistrano 3 coming soon.

### About

Capistrano 2 PostgreSQL plugin abstracts and speeds up common administration
tasks for PostgreSQL when deploying rails applications.

Here are the specific things this plugin does for your rails app capistrano
deployment process:

* creates a new PostgreSQL database and database user on the server
* generates and populates `database.yml` file with the right data on the server
  (no need to ssh to the server and do this manually!)
* no config necessary (or it's kept to a minimum)

### Installation

Put the following in your application's `Gemfile`:

    group :development do
      gem 'capistrano2-postgresql', require: false
    end

Install the gem with:

    $ bundle install

### Standard usage

If you're deploying a standard rails app, all that you need to do is put
the following in `config/deploy.rb` file:

    require "capistrano-postgresql"

Easy, right?

Check below to see what happens in the background.

### How it works

The following tasks run automatically after `cap deploy:setup`:

* `postgresql:create_database` creates a postgresql user and a database for
  your app. Password for the user is automatically generated and used in the
  next step.

* `postgresql:setup` it creates a `database.yml` file and copies it to
  `#{shared_path}/config/database.yml` on the server.

The following task runs automatically after `cap deploy:cold` and each
`cap deploy`:

* `postgresql:symlink` ensures the `database.yml` from the previous step is
  always symlinked to `config/database.yml` for new app release.

The above tasks are all you need for getting rails app to work with PostgreSQL.

### Gotchas

Be sure to remove `database.yml` from your application's version control.

### Configuration

This plugin should just work with no configuration whatsoever. However,
customization is possible. Here's the list of options and the defaults for each
option:

* `set :postgresql_user`<br/>
Name of the database user. Defaults to `"#{capistrano_user}_#{application}"`
which is most likely something like `deploy_myapp`.

* `set :postgresql_database`<br/>
Name of the database for your app. Defaults to `#{application}`.

* `set :postgresql_password`<br/>
Password for the database user. By default this option is not set and
**new random password** is generated each time you create a new database.
If you set this option to `"some_secure_password"` - that will be the db
password. Keep in mind that having a hardcoded password in `deploy.rb` (or
anywhere in version control) is a bad practice.
I recommend sticking to the default and generating a new secure and random
password each time a database is generated. That way you don't have to worry
about it or try to remember it.

* `set :postgresql_ask_for_password`, default `false`<br/>
Set this option to `true` if you want to be prompted for the password when
database user is created. This is safer than setting the password via
`postgresql_password`, but the downside is you have to choose and remember
yet another fricking password.<br/>
`postgresql_password` option has precedence. If it is set,
`postgresql_ask_for_password` is ignored.

* `set :postgresql_default_tasks`<br/>
This task determines whether capistrano tasks from this plugin are executed
automatically during capistrano deploy process. Defaults to `true`. Tasks that
are run automatically are: `postgresql:create_database`, `postgresql:setup` and
`postgresql:symlink`.

`database.yml` template-only settings:

* `set :postgresql_pool`<br/>
Pool config in `database.yml` template. Defaults to `5`.

* `set :postgresql_host`<br/>
`hostname` config in `database.yml` template. Defaults to `localhost`.

* `set :postgresql_encoding`<br/>
`encogind` config in `database.yml` template. Defaults to `unicode`.

### Customizing the `database.yml` template

This is the default `database.yml` template that gets copied to the capistrano
shared directory on the server:

```yml
production:
  adapter: postgresql
  encoding: <%= postgresql_encoding %>
  database: <%= postgresql_database %>
  pool: <%= postgresql_pool %>
  username: <%= postgresql_user %>
  password: '<%= postgresql_password %>'
  host: <%= postgresql_host %>
```

If for any reason you want to edit or tweak this template, you can copy it to
`config/deploy/templates/postgresql.yml.erb` with this command:

    rails g capistrano:postgresql:template

After you edit this newly created file in your repo, it will be used as a
template for `database.yml` on the server.

You can configure the template location. For example:
`set :templates_path, "config"` and the template will be copied to
`config/postgresql.yml.erb`.

### Contributing and bug reports

Contributions and improvements are very welcome. Just open a pull request and
I'll look it up shortly.

If something is not working for you, or you find a bug please report it.

### Thanks

Here are other plugins and people this project was based upon:

* [Matt Bridges](https://github.com/mattdbridges) - capistrano postgresql tasks
from this plugin are heavily based on his
[capistrano-recipes repo](https://github.com/mattdbridges/capistrano-recipes).

* [Kalys Osmonom](https://github.com/kalys) - his
[capistrano-nginx-unicorn](https://github.com/kalys/capistrano-nginx-unicorn)
gem structure was an inspiration for this plugin. A lot of the features were
directly copied from his project (example: `database.yml` template generator).

### License

[MIT](LICENSE.md)
