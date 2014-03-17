require 'securerandom'
require 'erb'

def database_yml_template(template_name, target)
  config_file = "#{fetch(:postgresql_templates_path)}/#{template_name}"
  # If there's no customized file in your rails app template directory,
  # proceed with the default.
  unless File.exists?(config_file)
    config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/postgresql/templates/#{template_name}")
  end
  upload! StringIO.new(ERB.new(File.read(config_file)).result(binding)), target
end

# This method is invoked only if `:postgresql_password` is not already set in
# `config/deploy.rb`. Directly setting `:postgresql_password` has precedence.
def ask_for_or_generate_password
  if fetch(:postgresql_ask_for_password)
    ask :postgresql_password, "Postgresql database password for the app: "
  else
    set :postgresql_password, generate_random_password
  end
end

def generate_random_password
  SecureRandom.hex(10)
end

def db_user_exists?(name)
  psql "-tAc", %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{name}';" | grep -q 1}
end

def create_db_user(name, password)
  if psql "-c", %Q{"CREATE user #{name} WITH password '#{password}';"}
    info "postgresq: database user '#{name}' created"
  else
    error "postgresql: creating database user failed!"
    exit 1
  end
end

def ensure_db_user_created(name, password)
  unless db_user_exists?(name)
    create_db_user(name, password)
  end
end

def database_exists?(db_name)
  psql "-tAc", %Q{"SELECT 1 FROM pg_database WHERE datname='#{db_name}';" | grep -q 1}
end

def create_database(db_name, user_name)
  if psql "-c", %Q{"CREATE database #{db_name} owner #{user_name};"}
    info "postgresql: database '#{db_name}' created"
  else
    error "postgresql: creating database '#{db_name}' failed!"
    exit 1
  end
end

def ensure_database_created(db_name, user_name)
  unless database_exists?(db_name)
    create_database(db_name, user_name)
  end
end

# returns true or false depending on the remote command exit status
def psql(*args)
  test :sudo, "-u postgres psql", *args
end

def remote_file_exists?(path)
  test "[ -e #{path} ]"
end

namespace :load do
  task :defaults do
    set :postgresql_database,   -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :postgresql_user,       -> { fetch(:postgresql_database) }
    set :postgresql_password,   -> { ask_for_or_generate_password }
    set :postgresql_ask_for_password, false
    set :postgresql_default_tasks,    true
    set :postgresql_templates_path,   "config/deploy/templates"

    # template only settings (used in postgresql.yml.erb)
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
