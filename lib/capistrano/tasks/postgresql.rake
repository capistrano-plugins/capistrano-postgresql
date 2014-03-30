require 'capistrano/postgresql/helper_methods'

include Capistrano::Postgresql::HelperMethods

namespace :load do
  task :defaults do
    set :pg_database, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :pg_user,     -> { fetch(:pg_database) }
    set :pg_password, -> { ask_for_or_generate_password }
    set :pg_ask_for_password, false
    # template only settings (used in postgresql.yml.erb)
    set :pg_templates_path, 'config/deploy/templates'
    set :pg_pool,     5
    set :pg_encoding, 'unicode'
    set :pg_host,     'localhost'

    set :linked_files, fetch(:linked_files, []).push('config/database.yml')
  end
end

namespace :postgresql do

  desc 'Create DB user'
  task :create_db_user do
    on roles :db do
      next if db_user_exists? fetch(:pg_user)
      unless psql '-c', %Q{"CREATE user #{fetch(:pg_user)} WITH password '#{fetch(:pg_password)}';"}
        error 'postgresql: creating database user failed!'
        exit 1
      end
    end
  end

  desc 'Create database'
  task :create_database do
    on roles :db do
      next if database_exists? fetch(:pg_database)
      unless psql '-c', %Q{"CREATE database #{fetch(:pg_database)} owner #{fetch(:pg_user)};"}
        error 'postgresql: creating database failed!'
        exit 1
      end
    end
  end

  desc 'Generate database.yml'
  task :generate_database_yml do
    on roles :app do
      database_yml_file = shared_path.join('config/database.yml')
      next if test "[ -e #{database_yml_file} ]"
      upload! template('postgresql.yml.erb'), database_yml_file
    end
  end

  after 'deploy:started', 'postgresql:create_db_user'
  after 'deploy:started', 'postgresql:create_database'
  after 'deploy:started', 'postgresql:generate_database_yml'

end
