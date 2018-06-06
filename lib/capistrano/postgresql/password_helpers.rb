require 'securerandom'

module Capistrano
  module Postgresql
    module PasswordHelpers

      def generate_random_password
        SecureRandom.hex(10)
      end

      def pg_password_generate
        if fetch(:pg_ask_for_password)
          ask :pg_password, "Postgresql database password for the app: "
        elsif fetch(:pg_generate_random_password)
          set :pg_password, generate_random_password
        else
          set :pg_password, nil # Necessary for pg_template
        end
      end
    end
  end
end

