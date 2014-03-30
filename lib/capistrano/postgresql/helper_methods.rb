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

    end
  end
end

