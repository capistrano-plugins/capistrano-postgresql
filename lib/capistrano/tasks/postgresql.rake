require 'capistrano/postgresql/helper_methods'
require 'capistrano/postgresql/password_helpers'
require 'capistrano/postgresql/psql_helpers'

include Capistrano::Postgresql::HelperMethods
include Capistrano::Postgresql::PasswordHelpers
include Capistrano::Postgresql::PsqlHelpers

namespace :load do
  task :defaults do
    # Options necessary for database.yml creation (pg_template|helper_methods.rb)
    set :pg_env, -> { fetch(:rails_env) || fetch(:stage) }
    set :pg_encoding, 'unicode'
    set :pg_database, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :pg_pool, 5
    set :pg_username, -> { fetch(:pg_database) }
    set :pg_password, nil
    set :pg_socket, ''
    set :pg_host, -> do # for multiple release nodes automatically use server hostname (IP?) in the database.yml
      release_roles(:all).count == 1 && release_roles(:all).first == primary(:db) ? 'localhost' : primary(:db).hostname
    end
    set :pg_port, 5432
    set :pg_timeout, 5000 # 5 seconds (rails default)
    # General settings
    set :pg_without_sudo, false # issues/22 | Contributed by snake66
    set :pg_system_user, 'postgres'
    set :pg_ask_for_password, false
    set :pg_system_db, 'postgres'
    set :pg_use_hstore, false
    set :pg_extensions, []
    set :pg_templates_path, 'config/deploy/templates'
  end
end

namespace :postgresql do

  desc 'Steps to upgrade the gem to version 4.0'
  task :upgrade4 do
    on roles :db do
      execute :mkdir, '-pv', File.dirname(archetype_database_yml_file)
      execute :cp, database_yml_file, archetype_database_yml_file
    end
  end

  # undocumented, for a reason: drops database. Use with care!
  task :remove_all do
    on release_roles :all do
      if test "[ -e #{database_yml_file} ]"
        execute :rm, database_yml_file
      end
    end

    on primary :db do
      if test "[ -e #{archetype_database_yml_file} ]"
        execute :rm, archetype_database_yml_file
      end
    end

    on roles :db do
      psql '-c', %Q{"DROP database \\"#{fetch(:pg_database)}\\";"}
      psql '-c', %Q{"DROP user \\"#{fetch(:pg_username)}\\";"}
    end
  end

  task :remove_app_database_yml_files do
    # We should never delete archetype files. The generate_database_yml_archetype task will handle updates
    on release_roles :app do
      if test "[ -e #{database_yml_file} ]"
        execute :rm, database_yml_file
      end
    end
  end

  desc 'Remove pg_extension from postgresql db'
  task :remove_extensions do
    next unless Array( fetch(:pg_extensions) ).any?
    on roles :db do
      # remove in reverse order if extension is present
      Array( fetch(:pg_extensions) ).reverse.each do |ext|
        psql_on_app_db '-c', %Q{"DROP EXTENSION IF EXISTS #{ext};"} unless [nil, false, ""].include?(ext)
      end
    end
  end

  desc 'Add the hstore extension to postgresql'
  task :add_hstore do
    next unless fetch(:pg_use_hstore)
    on roles :db do
      psql_on_app_db '-c', %Q{"CREATE EXTENSION IF NOT EXISTS hstore;"}
    end
  end

  desc 'Add pg_extension to postgresql db'
  task :add_extensions do
    next unless Array( fetch(:pg_extensions) ).any?
    on roles :db do
      Array( fetch(:pg_extensions) ).each do |ext|
        next if [nil, false, ''].include?(ext)
        if psql_on_app_db '-c', %Q{"CREATE EXTENSION IF NOT EXISTS #{ext};"}
          puts "- Added extension #{ext} to #{fetch(:pg_database)}"
        else
          error "postgresql: adding extension #{ext} failed!"
          exit 1
        end
      end
    end
  end

  desc 'Create database'
  task :create_database do
    on roles :db do
      next if database_exists?
      unless psql_on_db fetch(:pg_system_db), '-c', %Q{"CREATE DATABASE \\"#{fetch(:pg_database)}\\" OWNER \\"#{fetch(:pg_username)}\\";"}
        error 'postgresql: creating database failed!'
        exit 1
      end
    end
  end

  desc 'Create DB user'
  task :create_db_user do
    on roles :db do
      next if db_user_exists?
      # If you use CREATE USER instead of CREATE ROLE the LOGIN right is granted automatically; otherwise you must specify it in the WITH clause of the CREATE statement.
      unless psql_on_db fetch(:pg_system_db), '-c', %Q{"CREATE USER \\"#{fetch(:pg_username)}\\" PASSWORD '#{fetch(:pg_password)}';"}
        error "postgresql: creating database user \"#{fetch(:pg_username)}\" failed!"
        exit 1
      end
    end
  end

  # This task creates the archetype database.yml file on the primary db server. This is done once when a new DB user is created.
  desc 'Generate database.yml archetype'
  task :generate_database_yml_archetype do
    on primary :db do
      if test "[ -e #{archetype_database_yml_file} ]" # Archetype already exists. Just update values that changed. Make sure we don't overwrite it to protect generated passwords.
        Net::SCP.upload!(self.host.hostname, self.host.user,StringIO.new(pg_template(true, download!(archetype_database_yml_file))),archetype_database_yml_file)
      else
        ask_for_or_generate_password if fetch(:pg_password).nil? || fetch(:pg_ask_for_password) == true # Avoid setting a random password or one from user prompt
        execute :mkdir, '-pv', File.dirname(archetype_database_yml_file)
        Net::SCP.upload!(self.host.hostname,self.host.user,StringIO.new(pg_template),archetype_database_yml_file)
      end
    end
  end

  # This task copies the archetype database file on the primary db server to all clients. This is done on every setup, to ensure new servers get a copy as well.
  desc 'Copy archetype database.yml from primary db server to clients'
  task :generate_database_yml do
    database_yml_contents = nil
    on primary :db do
      database_yml_contents = download! archetype_database_yml_file
    end

    on release_roles :all do
      execute :mkdir, '-pv', File.dirname(database_yml_file)
      Net::SCP.upload!(self.host.hostname, self.host.user, StringIO.new(database_yml_contents), database_yml_file)
    end
  end

  task :database_yml_symlink do
    set :linked_files, fetch(:linked_files, []).push('config/database.yml')
  end

  after 'deploy:started', 'postgresql:database_yml_symlink'

  desc 'Postgresql setup tasks'
  task :setup do
    puts "* ============================= * \n All psql commands will be run #{fetch(:pg_without_sudo) ? 'without sudo' : 'with sudo'}\n You can modify this in your app/config/deploy/#{fetch(:rails_env)}.rb by setting the pg_without_sudo boolean \n* ============================= *"
    if release_roles(:app).empty?
      puts "There are no servers in your app/config/deploy/#{fetch(:rails_env)}.rb with a :app role... Skipping Postgresql setup."
    else
      invoke 'postgresql:remove_app_database_yml_files' # Deletes old yml files from all servers. Allows you to avoid having to manually delete the files on your app servers to get a new pool size for example. Don't touch the archetype file to avoid deleting generated passwords.
      if release_roles(:db).empty? # Test to be sure we have a :db role host
        puts "There is no server in your app/config/deploy/#{fetch(:rails_env)}.rb with a :db role... Skipping Postgresql setup."
      else
        invoke 'postgresql:create_db_user'
        invoke 'postgresql:create_database'
        invoke 'postgresql:add_hstore'
        invoke 'postgresql:add_extensions'
        invoke 'postgresql:generate_database_yml_archetype'
        invoke 'postgresql:generate_database_yml'
      end
    end
  end
end

desc 'Server setup tasks'
task :setup do
  invoke "postgresql:setup"
end
