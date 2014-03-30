require 'securerandom'
require 'erb'

module Capistrano
  module Postgresql
    module HelperMethods

      def template(template_name)
        config_file = "#{fetch(:pg_templates_path)}/#{template_name}"
        # If there's no customized file in your rails app template directory,
        # proceed with the default.
        unless File.exists?(config_file)
          config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/postgresql/templates/#{template_name}")
        end
        StringIO.new ERB.new(File.read(config_file)).result(binding)
      end

      # This method is invoked only if `:pg_password` is not already
      # set in `config/#{:stage}/deploy.rb`. Directly setting
      # `:pg_password` has precedence.
      def ask_for_or_generate_password
        if fetch(:pg_ask_for_password)
          ask :pg_password, "Postgresql database password for the app: "
        else
          set :pg_password, generate_random_password
        end
      end

      def generate_random_password
        SecureRandom.hex(10)
      end

      def db_user_exists?(name)
        psql "-tAc", %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{name}';" | grep -q 1}
      end

      def database_exists?(db_name)
        psql "-tAc", %Q{"SELECT 1 FROM pg_database WHERE datname='#{db_name}';" | grep -q 1}
      end

      # returns true or false depending on the remote command exit status
      def psql(*args)
        test :sudo, '-u postgres psql', *args
      end

      def database_yml_file
        shared_path.join('config/database.yml')
      end

    end
  end
end

