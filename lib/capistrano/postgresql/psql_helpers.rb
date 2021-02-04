module Capistrano
  module Postgresql
    module PsqlHelpers

      def psql(type, database, *args)
        if fetch(:pg_without_sudo)
          # Add the :pg_system_user to psql command since we aren't using sudo anymore
          cmd = [ :psql, "-d #{database}", *args.unshift("-U #{fetch(:pg_system_user)}") ]
        else
          cmd = [:sudo, "-i -u #{fetch(:pg_system_user)}", :psql, *args]
        end
        # Allow us to execute the different sshkit commands
        if type == 'test'
          test *cmd
        elsif type == 'capture'
          capture *cmd
        else
          execute *cmd
        end
      end

      def database_user_exists?
        psql 'test', fetch(:pg_system_db),"-p #{fetch(:pg_port)} -tAc", %Q{"SELECT 1 FROM pg_roles WHERE rolname='#{fetch(:pg_username)}';" | grep -q 1}
      end

      def database_user_password_different?
        current_password_md5 = psql 'capture', fetch(:pg_system_db),"-p #{fetch(:pg_port)} -tAc", %Q{"select passwd from pg_shadow WHERE usename='#{fetch(:pg_username)}';"}
        new_password_md5 = "md5#{Digest::MD5.hexdigest("#{fetch(:pg_password)}#{fetch(:pg_username)}")}"
        current_password_md5 == new_password_md5 ? false : true
      end

      def database_exists?
        psql 'test', fetch(:pg_system_db), "-p #{fetch(:pg_port)} -tAc", %Q{"SELECT 1 FROM pg_database WHERE datname='#{fetch(:pg_database)}';" | grep -q 1}
      end

    end
  end
end

