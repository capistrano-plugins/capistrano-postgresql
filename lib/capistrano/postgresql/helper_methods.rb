require 'erb'

module Capistrano
  module Postgresql
    module HelperMethods

      def generate_database_yml_io(password=fetch(:pg_password))
        StringIO.open do |s|
          s.puts "#{fetch(:pg_env)}:"
          {
              adapter: 'postgresql',
              encoding: fetch(:pg_encoding),
              database: fetch(:pg_database),
              pool: fetch(:pg_pool),
              username: fetch(:pg_username),
              password: password,
              host: fetch(:pg_host),
              socket: fetch(:pg_socket),
              port: fetch(:pg_port),
              timeout: fetch(:pg_timeout)
          }.each { |option_name,option_value| s.puts "  #{option_name}: #{option_value}" } # Yml does not support tabs. There are two spaces leading the config option line
          s.string
        end
      end

      def pg_template(update=false,archetype_file=nil)
        config_file = "#{fetch(:pg_templates_path)}/postgresql.yml.erb"
        if update
          raise('Updates need the original file to update from.') if archetype_file.nil?
          raise('Cannot update a custom postgresql.yml.erb file.') if File.exists?(config_file) # Skip custom postgresql.yml.erb if we're updating. It's not supported
          # Update yml file from settings
          if fetch(:pg_password).nil? && fetch(:pg_ask_for_password) == false # User isn't generating a random password or wanting to set it manually from prompt
            current_password = archetype_file.split("\n").grep(/password/)[0].split('password:')[1].strip
            generate_database_yml_io(current_password)
          else
            generate_database_yml_io
          end
        else
          if File.exists?(config_file) # If there is a customized file in your rails app template directory, use it and convert any ERB
            StringIO.new ERB.new(File.read(config_file)).result(binding)
          else # Else there's no customized file in your rails app template directory, proceed with the default.
            # Build yml file from settings
            ## We build the file line by line to avoid overwriting existing files
            generate_database_yml_io
          end
        end

      end

      # location of database.yml file on clients
      def database_yml_file
        raise(":deploy_to in your app/config/deploy/#{fetch(:rails_env)}.rb file cannot contain ~") if shared_path.to_s.include?('~') # issues/27
        shared_path.join('config/database.yml')
      end

      # location of archetypal database.yml file created on primary db role when user and database are first created
      def archetype_database_yml_file
        raise(":deploy_to in your app/config/deploy/#{fetch(:rails_env)}.rb file cannot contain ~") if shared_path.to_s.include?('~') # issues/27
        deploy_path.join('db/database.yml')
      end
    end
  end
end

