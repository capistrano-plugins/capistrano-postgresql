module Capistrano
  module Postgresql
    module PsqlHelpers

      # returns true or false depending on the remote command exit status
      def psql(*args)
        test :sudo, '-u postgres psql', *args
      end

      def db_user_exists?(name)
        psql '-tAc', %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{name}';" | grep -q 1}
      end

      def database_exists?(db_name)
        psql '-tAc', %Q{"SELECT 1 FROM pg_database WHERE datname='#{db_name}';" | grep -q 1}
      end

    end
  end
end

