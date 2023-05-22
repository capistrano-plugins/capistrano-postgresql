require 'erb'

module Capistrano
  module Postgresql
    module HelperMethods

      def extension_exists?(extension)
        psql 'test', fetch(:pg_database), '-tAc', %Q{"SELECT 1 FROM pg_extension WHERE extname='#{extension}';" | grep -q 1}
      end

      def remove_extensions
        if Array( fetch(:pg_extensions) ).any?
          on roles :db do
            # remove in reverse order if extension is present
            Array( fetch(:pg_extensions) ).reverse.each do |ext|
              next if [nil, false, ""].include?(ext)
              psql 'execute', fetch(:pg_database), '-c', %Q{"DROP EXTENSION IF EXISTS #{ext};"} if extension_exists?(ext)
            end
          end
        end
      end

      def generate_database_yml_io
        StringIO.open do |s|
          s.puts "#{fetch(:pg_env)}:"
          {
              adapter: 'postgresql',
              encoding: fetch(:pg_encoding),
              database: fetch(:pg_database),
              pool: fetch(:pg_pool),
              username: fetch(:pg_username),
              password: fetch(:pg_password),
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
          raise('Regeneration of archetype database.yml need the original file to update from.') if archetype_file.nil?
          raise('Cannot update a custom postgresql.yml.erb file.') if File.exist?(config_file) # Skip custom postgresql.yml.erb if we're updating. It's not supported
          # Update yml file from settings
          generate_database_yml_io
        else
          if File.exist?(config_file) # If there is a customized file in your rails app template directory, use it and convert any ERB
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

