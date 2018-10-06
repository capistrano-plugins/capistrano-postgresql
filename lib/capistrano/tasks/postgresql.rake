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
    set :pg_generate_random_password, nil
    set :pg_ask_for_password, nil
    set :pg_password, -> { pg_password_generate }
    set :pg_socket, ''
    set :pg_host, -> do # for multiple release nodes automatically use server hostname (IP?) in the database.yml
      release_roles(:all).count == 1 && release_roles(:all).first == primary(:db) ? 'localhost' : primary(:db).hostname
    end
    set :pg_port, 5432
    set :pg_timeout, 5000 # 5 seconds (rails default)
    # General settings
    set :pg_without_sudo, false # issues/22 | Contributed by snake66
    set :pg_system_user, 'postgres'
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
      execute :rm, database_yml_file if test "[ -e #{database_yml_file} ]"
    end
    on primary :db do
      execute :rm, archetype_database_yml_file if test "[ -e #{archetype_database_yml_file} ]"
    end
    on roles :db do
      psql'execute', fetch(:pg_system_db), '-c', %Q{"DROP database \\"#{fetch(:pg_database)}\\";"} if database_exists?
      psql 'execute', fetch(:pg_system_db),'-c', %Q{"DROP user \\"#{fetch(:pg_username)}\\";"}if database_user_exists?
      remove_extensions
    end
    puts 'Removed database.yml from all hosts, Database, Database User, and Removed Extensions'
  end

  task :remove_app_database_yml_files do
    # We should never delete archetype files. The generate_database_yml_archetype task will handle updates
    on release_roles :app do
        execute :rm, database_yml_file if test "[ -e #{database_yml_file} ]"
    end
  end

  desc 'Remove pg_extension from postgresql db'
  task :remove_extensions do
    remove_extensions
  end

  desc 'Add pg_extension to postgresql db'
  task :add_extensions do
    on roles :db do
      if Array( fetch(:pg_extensions) ).any?
        Array( fetch(:pg_extensions) ).each do |ext|
          next if [nil, false, ''].include?(ext)
          psql 'execute', fetch(:pg_database), '-c', %Q{"CREATE EXTENSION IF NOT EXISTS #{ext};"}unless extension_exists?(ext)
        end
      end
    end
  end

  desc 'Create or update pg_username in database'
  task :create_database_user do
    on roles :db do
      unless database_user_exists?
        # If you use CREATE USER instead of CREATE ROLE the LOGIN right is granted automatically; otherwise you must specify it in the WITH clause of the CREATE statement.
        psql 'execute', fetch(:pg_system_db), '-c', %Q{"CREATE USER \\"#{fetch(:pg_username)}\\" PASSWORD}, redact("'#{fetch(:pg_password)}'"), %Q{;"}
      end
      if database_user_password_different?
        # Ensure updating the password in your deploy/ENV.rb files updates the user, server side
        psql 'execute', fetch(:pg_system_db), '-c', %Q{"ALTER USER \\"#{fetch(:pg_username)}\\" WITH PASSWORD}, redact("'#{fetch(:pg_password)}'"), %Q{;"}
      end
    end
  end

  desc 'Create database'
  task :create_database do
    on roles :db do
      unless database_exists?
        psql 'execute', fetch(:pg_system_db), '-c', %Q{"CREATE DATABASE \\"#{fetch(:pg_database)}\\" OWNER \\"#{fetch(:pg_username)}\\";"}
      end
    end
  end

  # This task creates the archetype database.yml file on the primary db server. This is done once when a new DB user is created.
  desc 'Generate database.yml archetype'
  task :generate_database_yml_archetype do
    on primary :db do
      if test "[ -e #{archetype_database_yml_file} ]" # Archetype already exists. Just update values that changed. Make sure we don't overwrite it to protect generated passwords.
        upload!(
            StringIO.new(pg_template(true, download!(archetype_database_yml_file))),
            archetype_database_yml_file
        )
        # Net::SCP.upload!(
        #     self.host.hostname,
        #     self.host.user,
        #     StringIO.new(pg_template(true, download!(archetype_database_yml_file))),
        #     archetype_database_yml_file,
        #     ssh: { port: self.host.port }
        # )
      else
        execute :mkdir, '-pv', File.dirname(archetype_database_yml_file)
        upload!(
            StringIO.new(pg_template),
            archetype_database_yml_file
        )
        # Net::SCP.upload!(
        #     self.host.hostname,
        #     self.host.user,
        #     StringIO.new(pg_template),
        #     archetype_database_yml_file,
        #     ssh: { port: self.host.port }
        # )
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
      upload!(
          StringIO.new(database_yml_contents),
          database_yml_file
      )
      # Net::SCP.upload!(
      #     self.host.hostname,
      #     self.host.user,
      #     StringIO.new(database_yml_contents),
      #     database_yml_file,
      #     ssh: { port: self.host.port }
      # )
    end
  end

  task :database_yml_symlink do
    set :linked_files, fetch(:linked_files, []).push('config/database.yml')
  end

  after 'deploy:started', 'postgresql:database_yml_symlink'

  desc 'Postgresql setup tasks'
  task :setup do
    puts "* ===== Postgresql Setup ===== *\n"
    puts " All psql commands will be run #{fetch(:pg_without_sudo) ? 'without sudo' : 'with sudo'}\n You can modify this in your app/config/deploy/#{fetch(:rails_env)}.rb by setting the pg_without_sudo boolean.\n"
    if release_roles(:app).empty?
      warn " WARNING: There are no servers in your app/config/deploy/#{fetch(:rails_env)}.rb with a :app role... Skipping Postgresql setup."
    else
      if release_roles(:db).empty? # Test to be sure we have a :db role host
        warn " WARNING: There is no server in your app/config/deploy/#{fetch(:rails_env)}.rb with a :db role... Skipping Postgresql setup."
      elsif !fetch(:pg_password) && !fetch(:pg_generate_random_password) && !fetch(:pg_ask_for_password)
        warn " WARNING: There is no :pg_password set in your app/config/deploy/#{fetch(:rails_env)}.rb.\n  If you don't wish to set it, 'set :pg_generate_random_password, true' or 'set :pg_ask_for_password, true' are available!"
      elsif fetch(:pg_generate_random_password) && fetch(:pg_ask_for_password)
        warn " WARNING: You cannot have both :pg_generate_random_password and :pg_ask_for_password enabled in app/config/deploy/#{fetch(:rails_env)}.rb."
      else
        invoke 'postgresql:remove_app_database_yml_files' # Deletes old yml files from all servers. Allows you to avoid having to manually delete the files on your app servers to get a new pool size for example. Don't touch the archetype file to avoid deleting generated passwords.
        invoke 'postgresql:create_database_user'
        invoke 'postgresql:create_database'
        invoke 'postgresql:add_extensions'
        invoke 'postgresql:generate_database_yml_archetype'
        invoke 'postgresql:generate_database_yml'
      end
    end
    puts "* ============================= *"
  end
end

desc 'Server setup tasks'
task :setup do
  invoke 'postgresql:setup'
end
