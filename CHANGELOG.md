# Changelog

### master

## v6.0.0, 2018-07-09
- Fix for pg_without_sudo; Wasn't adding -U to args
- New feature that will ALTER USER/Password with any change to pg_password. Random passwords will cause each cap setup to run the ALTER USER, but that's fine as a user should technically only be using setup initially. It's not that hard to obtain the new password if this happens.
- New redaction for logging of passwords & SSHKIT 1.17.0 in gemspec
- README updates

## v5.0.1, 2018-06-05
- Quick fix for fetch(:pg_database) on extension adding

## v5.0.0, 2018-06-05
- Code cleanup
- Removal of legacy add hstore method
- Using execute and test properly so we can see what the gem is doing in the STDOUT
- Expanded remove_all task to actually cover everything
- Added deploy config option pg_generate_random_password, instead of using it by default when pg_password is excluded
- issues/53: Bug fixed for updates to the archetype when using random password
- projects/1: Prep for RSPEC testing project

## v4.9.1, 2018-06-04
- Added back set :pg_ask_for_password, false and ask_for_or_generate_password

## v4.8.0, 2017-12-28
- issues/47: Added new pg_template helper code to handle maintaining the randomly generated password, :pg_ask_for_password, and user set pg_password
- Added the rest of the supported options for the database.yml
- pull/46 (Thanks to Tom Prats / tomprats): Fix for pg_host when localhost is used
- Removed system_user as it's not necessary if server values are defined properly in config/deploy/* files
- General cleanup of notes

## v4.7.0, 2017-12-19
- Fixed create database and user tasks to use (:pg_system_db) and psql_on_db

## v4.6.1, 2017-12-15
- Removing require 'pry' (silly mistake)

## v4.6.0, 2017-12-10
- :pg_without_sudo added (thanks to snake66) so you can run remote psql commands on environments without sudo available.
- Fixed exists? methods, removing the need for arguments
- Printing sudo status to capistrano STDOUT

## v4.4.1, 2017-10-26
- Switched back from CREATE ROLE to CREATE USER (so LOGIN rights are granted automatically)

## v4.4.0, 2017-10-26
- :remove_yml_files task added to clean up old files on remote server

## v4.3.1, 2017-10-21
- Fixed quoting on CREATE USER so we can include integers in usernames & Quoted other values like CREATE DATABASE so they can include integers too
- Changed to createuser convention "CREATE ROLE" instead of USER (v4.4.1 reversed this)

## v4.3.0, 2017-10-21
- issues/27: raise on :deploy_to with ~ in it
- Net::SCP.upload! to replace old upload! for using :system_user
- issues/31 : psql -> psql_simple so user can be created regardless of database existence
- General cleanup

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
