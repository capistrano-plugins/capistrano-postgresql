require 'securerandom'
require 'erb'

module Capistrano
  module Postgresql
    module HelperMethods

      def database_yml_template(template_name, target)
        config_file = "#{fetch(:postgresql_templates_path)}/#{template_name}"
        # If there's no customized file in your rails app template directory,
        # proceed with the default.
        unless File.exists?(config_file)
          config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/postgresql/templates/#{template_name}")
        end
        upload! StringIO.new(ERB.new(File.read(config_file)).result(binding)), target
      end

      # This method is invoked only if `:postgresql_password` is not already
      # set in `config/#{:stage}/deploy.rb`. Directly setting
      # `:postgresql_password` has precedence.
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
        unless psql "-c", %Q{"CREATE user #{name} WITH password '#{password}';"}
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
        unless psql "-c", %Q{"CREATE database #{db_name} owner #{user_name};"}
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
        test :sudo, '-u postgres psql', *args
      end

      def remote_file_exists?(path)
        test "[ -e #{path} ]"
      end

    end
  end
end

