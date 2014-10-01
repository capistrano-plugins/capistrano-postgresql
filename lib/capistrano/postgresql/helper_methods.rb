require 'erb'

module Capistrano
  module Postgresql
    module HelperMethods

      def pg_template(template_name)
        config_file = "#{fetch(:pg_templates_path)}/#{template_name}"
        # If there's no customized file in your rails app template directory,
        # proceed with the default.
        unless File.exists?(config_file)
          default_config_path = "../../generators/capistrano/postgresql/templates/#{template_name}"
          config_file = File.join(File.dirname(__FILE__), default_config_path)
        end
        StringIO.new ERB.new(File.read(config_file)).result(binding)
      end

      # location of database.yml file on clients
      def database_yml_file
        shared_path.join('config/database.yml')
      end

      # location of archetypical database.yml file created on primary db role when user and
      # database are first created
      def archetype_database_yml_file
        deploy_path.join("db/database.yml")
      end
    end
  end
end

