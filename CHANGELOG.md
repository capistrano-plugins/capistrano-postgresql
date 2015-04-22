# Changelog

### master

### v4.2.1, 2015-04-22
- change `on roles(:db, primary: true)` to the correct `on primary :db`

### v4.2.0, 2014-11-13
- add `pg_extensions` option and `add_extensions` or `remove_extensions` methods, to handle various extensions as needed (@twetzel)

### v4.1.0, 2014-10-08
- automatically set `pg_host` option to the IP address of primary `db` host when
  there are multiple release nodes (@bruno-)

### v4.0.0, 2014-10-06
- enable setting DB environment with `rails_env` option. If `rails_env` is not
  set, `stage` option is used as until now. (@bruno-)
- create a task that helps with the upgrade to gem version 4 (@bruno-)
- optionally create a hstore extension on the server (@rhomeister)
- `database.yml` is now copied to all release_roles (@rhomeister)
- introduce archetype `database.yml` that is stored on primary `db` node and
  is copied to all `release` nodes on `setup` task (@rhomeister)

### v3.0.0, 2014-04-11
- all the work is moved to the `setup` task

### v2.0.0, 2014-03-30
- shorten variable names: postgresql -> pg
- better helpers module separation
- lots of code styling updates
- lots of code improvements
- less layered and simpler code
- readme updates

### v1.0.0, 2014-03-19
- all the v1.0.0 features
