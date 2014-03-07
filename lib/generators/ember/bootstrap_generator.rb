require 'generators/ember/generator_helpers'

module Ember
  module Generators
    class BootstrapGenerator < ::Rails::Generators::Base
      APP_FOLDERS = %W{models controllers views routes components templates templates/components mixins}
      CONFIG_FOLDERS = %W{serializers}

      include Ember::Generators::GeneratorHelpers

      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a default Ember.js folder layout in app/ and config/"

      class_option :app_path, :type => :string, :aliases => "-a", :default => false, :desc => "Custom ember app path"
      class_option :config_path, :type => :string, :aliases => "-c", :default => false, :desc => "Custom ember config path"
      class_option :test_path, :type => :string, :aliases => "-t", :default => false, :desc => "Custom ember test path"
      class_option :app_name, :type => :string, :aliases => "-n", :default => false, :desc => "Custom ember app name"

      def create_app_dir_layout
        create_layout(APP_FOLDERS)
      end

      def create_config_dir_layout
        create_layout(CONFIG_FOLDERS, config_path)
      end

      def create_router_file
        template "router.es6", "#{config_path}/router.es6"
      end

      def create_application_file
        template "application.js.erb", "#{config_path}/application.js"
      end

      def create_ember_adapter_file
        copy_file "adapters/application.es6.erb", "#{config_path}/adapters/application.es6.erb"
      end

      def create_ember_environment_files
        copy_file "environment.js.erb", "#{config_path}/environment.js.erb"
        copy_file "environments/development.js.erb", "#{config_path}/environments/development.js.erb"
        copy_file "environments/production.js.erb", "#{config_path}/environments/production.js.erb"
        copy_file "environments/test.js.erb", "#{config_path}/environments/test.js.erb"
      end

      def create_utils_csrf_file
        template "csrf.js", "#{config_path}/initializers/csrf.js"
      end

      def remove_turbolinks
        remove_turbolinks_from_gemfile
        remove_turbolinks_from_layout
      end

      def remove_jbuilder
        remove_jbuilder_from_gemfile
      end

      def add_greedy_rails_route
        insert_into_file 'config/routes.rb', before: /^end$/ do
          "\n" +
          "  # Uncomment when using 'history' as the location in Ember's router\n" +
          "  # get '*foo', :to => 'landing#index'\n"
        end
      end

      def add_custom_paths
        if app_path != configuration.paths.app
          insert_into_file 'config/application.rb', before: /\s\send\nend/ do
            "    config.ember.paths.app = '#{app_path}'\n"
          end
        end

        if config_path != configuration.paths.config
          insert_into_file 'config/application.rb', before: /\s\send\nend/ do
            "    config.ember.paths.config = '#{config_path}'\n"
          end
        end
      end

      def add_teaspoon_files
        copy_file "initializers/teaspoon.rb", "config/initializers/teaspoon.rb"
        copy_file "test/teaspoon_env.rb", "#{test_path}/teaspoon_env.rb"
        copy_file "test/test_helper.js", "#{test_path}/test_helper.js"
        empty_directory "#{test_path}/integration"
      end

      private

      def create_layout(directories, path = app_path)
        directories.each do |dir|
          empty_directory "#{path}/#{dir}"
          create_file "#{path}/#{dir}/.gitkeep" unless options[:skip_git]
        end
      end

      def remove_turbolinks_from_layout
        path = Pathname.new(destination_root).join('app','views','layouts','application.html.erb')
        return unless path.exist?

        gsub_file path, /(?:, "data-turbolinks-track" => true)/, ''
      end

      def remove_gem_from_gemfile(gem)
        path = Pathname.new(destination_root).join('Gemfile')
        return unless path.exist?

        gsub_file path, /(?:#.+$\n)?gem ['|"]#{gem}.*['|"].*\n\n?/, ''
      end

      def remove_turbolinks_from_gemfile
        remove_gem_from_gemfile(:turbolinks)
      end

      def remove_jbuilder_from_gemfile
        remove_gem_from_gemfile(:jbuilder)
      end
    end
  end
end
