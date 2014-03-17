To create local `database.yml.erb` template in a default path
"config/deploy/templates" type this in your shell:

    rails generate capistrano:postgresql:template

This is how you override the default path:

    rails generate capistrano:postgresql:template "config/templates"

If you override templates path, don't forget to set "templates_path" variable in your deploy.rb
