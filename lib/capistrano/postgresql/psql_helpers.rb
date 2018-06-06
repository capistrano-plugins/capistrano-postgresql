module Capistrano
  module Postgresql
    module PsqlHelpers

      def psql(type, database, *args)
        cmd = [ :psql, "-d #{database}", *args ]
        if fetch(:pg_without_sudo)
          args.unshift("-U #{fetch(:pg_system_user)}") # Add the :pg_system_user to psql command since we aren't using sudo anymore
        else
          cmd = [:sudo, "-i -u #{fetch(:pg_system_user)}", *cmd]
        end
        if type == 'test'
          test *cmd.flatten
        else
          execute *cmd.flatten
        end
      end

      def database_user_exists?
        psql 'test', fetch(:pg_system_db),'-tAc', %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{fetch(:pg_username)}';" | grep -q 1}
      end

      def database_exists?
        psql 'test', fetch(:pg_system_db), '-tAc', %Q{"SELECT 1 FROM pg_database WHERE datname='#{fetch(:pg_database)}';" | grep -q 1}
      end

    end
  end
end

