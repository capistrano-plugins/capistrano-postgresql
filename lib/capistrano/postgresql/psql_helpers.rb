module Capistrano
  module Postgresql
    module PsqlHelpers

      # returns true or false depending on the remote command exit status
      def psql(*args)
        psql_on_db(fetch(:pg_system_db), *args)
      end

      # Runs psql on the application database
      def psql_on_app_db(*args)
        psql_on_db(fetch(:pg_database), *args)
      end

      def db_user_exists?(name)
        psql '-tAc', %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{name}';" | grep -q 1}
      end

      def database_exists?(db_name)
        psql '-tAc', %Q{"SELECT 1 FROM pg_database WHERE datname='#{db_name}';" | grep -q 1}
      end

      private
      def psql_on_db(db_name, *args)
        test :sudo, "-u #{fetch(:pg_system_user)} psql -d #{db_name}", *args
      end
    end
  end
end

