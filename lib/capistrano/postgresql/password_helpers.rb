require 'securerandom'

module Capistrano
  module Postgresql
    module PasswordHelpers

      def generate_random_password
        SecureRandom.hex(10)
      end

      # This method is invoked only if `:pg_password` is not already
      # set in `config/#{:stage}/deploy.rb`. Directly setting
      # `:pg_password` has precedence.
      def ask_for_or_generate_password
        if fetch(:pg_ask_for_password)
          ask :pg_password, "Postgresql database password for the app: "
        else
          set :pg_password, generate_random_password
        end
      end

    end
  end
end

