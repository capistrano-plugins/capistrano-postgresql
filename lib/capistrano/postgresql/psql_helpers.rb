module Capistrano
  module Postgresql
    module PsqlHelpers

      def psql(*args)
        # Reminder: -u #{fetch(:pg_system_user)} seen below differs slightly from -U, an option on the psql command: https://www.postgresql.org/docs/9.6/static/app-psql.html
        args.unshift("-U #{fetch(:pg_system_user)}") if fetch(:pg_without_sudo) # Add the :pg_system_user to psql command since we aren't using sudo anymore
        # test :sudo, "-u #{fetch(:pg_system_user)} psql", *args
        cmd = [ :psql, *args ]
        cmd = [ :sudo, "-u #{fetch(:pg_system_user)}", *cmd ] unless fetch(:pg_without_sudo)
        test *cmd.flatten
      end

      # Runs psql on the application database
      def psql_on_app_db(*args)
        psql_on_db(fetch(:pg_database), *args)
      end

      def db_user_exists?(name)
        psql_on_db '-tAc', %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{name}';" | grep -q 1}
      end

      def database_exists?(db_name)
        psql_on_db '-tAc', %Q{"SELECT 1 FROM pg_database WHERE datname='#{db_name}';" | grep -q 1}
      end

      private

        def psql_on_db(db_name, *args)
          cmd = [ :psql, "-d #{db_name}", *args ]
          cmd = [ :sudo, "-u #{fetch(:pg_system_user)}", *cmd ] unless fetch(:pg_without_sudo)
          test *cmd.flatten
          #test :sudo, "-u #{fetch(:pg_system_user)} psql -d #{db_name}", *args
        end

    end
  end
end

