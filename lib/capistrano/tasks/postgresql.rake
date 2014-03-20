require 'capistrano/postgresql/helper_methods'

include Capistrano::Postgresql::HelperMethods

namespace :load do
  task :defaults do
    set :postgresql_database,   -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :postgresql_user,       -> { fetch(:postgresql_database) }
    set :postgresql_password,   -> { ask_for_or_generate_password }
    set :postgresql_ask_for_password, false
    set :postgresql_default_tasks,    true

    # template only settings (used in postgresql.yml.erb)
    set :postgresql_templates_path,   "config/deploy/templates"
    set :postgresql_pool,     5
    set :postgresql_encoding, "unicode"
    set :postgresql_host,     "localhost"
  end
end

namespace :postgresql do

  desc "Print all the variables"
  task :debug do
    puts "postgresql_database:         #{fetch(:postgresql_database)}"
    puts "postgresql_user:             #{fetch(:postgresql_user)}"
    puts "postgresql_password:         #{fetch(:postgresql_password)}"
    puts "postgresql_ask_for_password: #{fetch(:postgresql_ask_for_password)}"
    puts "postgresql_default_tasks:    #{fetch(:postgresql_default_tasks)}"
    puts "postgresql_pool:             #{fetch(:postgresql_pool)}"
    puts "postgresql_encoding:         #{fetch(:postgresql_encoding)}"
    puts "postgresql_host              #{fetch(:postgresql_host)}"
  end

  # This task never runs automatically
  # desc "Drop a database for this application"
  task :drop_database do
    on roles(:db) do
      psql "-c", %Q{"DROP database #{fetch(:postgresql_database)};"}
    end
  end

  # This task never runs automatically
  # desc "Delete database user for this application"
  task :delete_db_user do
    on roles(:db) do
      psql "-c", %Q{"DROP user #{fetch(:postgresql_user)};"}
    end
  end

  # this task never runs automatically
  # desc "Delete `config/database.yml` from the shared path on the server"
  task :delete_database_yml do
    on roles(:app) do
      database_yml_path = shared_path.join("config/database.yml")
      if remote_file_exists? database_yml_path
        execute :rm, database_yml_path
      end
    end
  end

  # this task never runs automatically. DANGEROUS! Destroys database on the server!
  # desc "Removes application database, DB user and removes `database.yml` from the server"
  task remove_all: [:drop_database, :delete_db_user, :delete_database_yml]


  desc "Create a database for this application"
  task :create_database do
    on roles(:db) do
      ensure_db_user_created fetch(:postgresql_user), fetch(:postgresql_password)
      ensure_database_created fetch(:postgresql_database), fetch(:postgresql_user)
    end
  end

  desc "Generate the database.yml configuration file"
  task :generate_database_yml do
    on roles(:app) do
      database_yml_path = shared_path.join("config/database.yml")
      if remote_file_exists? database_yml_path
        info "postgresql: database.yml already exists in the shared path"
      else
        info "postgresql: generating database.yml in shared path"
        execute :mkdir, "-p", shared_path.join("config")
        database_yml_template "postgresql.yml.erb", database_yml_path
      end
    end
  end

  desc "Adds `config/database.yml` to the linked_files array"
  task :ensure_database_yml_symlink do
    on roles(:app) do
      if fetch(:linked_files).nil?
        set :linked_files, ["config/database.yml"]
      elsif !fetch(:linked_files).include? "config/database.yml"
        fetch(:linked_files) << "config/database.yml"
      end
    end
  end

  after "deploy:started", "postgresql:started" do
    # `postgresql_default_tasks` true by default -> capistrano-postgresql tasks
    # run automatically on deploy
    if fetch(:postgresql_default_tasks)
      invoke "postgresql:create_database"
      invoke "postgresql:generate_database_yml"
      invoke "postgresql:ensure_database_yml_symlink"
    end
  end

end
