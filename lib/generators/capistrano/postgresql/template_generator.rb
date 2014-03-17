module Capistrano
  module Postgresql
    module Generators
      class TemplateGenerator < Rails::Generators::Base

        desc "Create local postgresql.yml.erb (database.yml on the server) template file for customization"
        source_root File.expand_path('../templates', __FILE__)
        argument :templates_path, type: :string,
          default: "config/deploy/templates",
          banner: "path to templates"

        def copy_template
          copy_file "postgresql.yml.erb", "#{templates_path}/postgresql.yml.erb"
        end

      end
    end
  end
end
