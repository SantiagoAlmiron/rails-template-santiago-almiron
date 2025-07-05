# Matar Spring en MacOS
run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemas generales
inject_into_file "Gemfile", before: "group :development, :test do" do
  <<~RUBY
    gem "bootstrap", "~> 5.3"
    gem "devise"
    gem "autoprefixer-rails"
    gem "font-awesome-sass", "~> 6.1"
    gem "simple_form", github: "heartcombo/simple_form"
    gem "sassc-rails"
    gem "haml-rails"

  RUBY
end

# Gemas de development y test
inject_into_file "Gemfile", after: "group :development, :test do" do
  <<~RUBY

    gem 'dotenv-rails'
    gem 'faker'
    gem 'factory_bot_rails'
    gem 'rubocop', require: false
    gem 'rubocop-rails', require: false
    gem 'rubocop-rspec', require: false

  RUBY
end

# Borrar estilos y bajar estilos base de Le Wagon
run "rm -rf app/assets/stylesheets"
run "rm -rf vendor"
run "curl -L https://github.com/lewagon/rails-stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm -f stylesheets.zip && rm -f app/assets/rails-stylesheets-master/README.md"
run "mv app/assets/rails-stylesheets-master app/assets/stylesheets"

# Layout viewport fix
gsub_file(
  "app/views/layouts/application.html.erb",
  '<meta name="viewport" content="width=device-width,initial-scale=1">',
  '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">'
)

# Flashes (HAML ya los convertimos después)
file "app/views/shared/_flashes.html.erb", <<~HTML
  <% if notice %>
    <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
      <%= notice %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% end %>
HTML

# Navbar (descargamos en .erb, lo convertimos a .haml después)
run "curl -L https://raw.githubusercontent.com/lewagon/awesome-navbars/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb"

# README
file "README.md", <<~MARKDOWN, force: true
  Rails app generated with a custom template based on [lewagon/rails-templates](https://github.com/lewagon/rails-templates), MIT licensed.
MARKDOWN

# Generators
environment <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

# General config
environment 'config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"'

after_bundle do
  # Simple Form + Pages controller
  rails_command "db:drop db:create db:migrate"
  generate("simple_form:install", "--bootstrap")
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")
  route 'root to: "pages#home"'

  # .gitignore
  append_file ".gitignore", <<~TXT
    .env*
    *.swp
    .DS_Store
  TXT

  # Devise
  generate("devise:install")
  generate("devise", "User")

  # Application controller con autenticación
  file "app/controllers/application_controller.rb", <<~RUBY, force: true
    class ApplicationController < ActionController::Base
      before_action :authenticate_user!
    end
  RUBY

  # Devise views
  rails_command "db:migrate"
  generate("devise:views")

  # Cambiar "cancel my account" link por button
  link_to = <<~HTML
    <p>Unhappy? <%= link_to "Cancel my account", registration_path(resource_name), data: { confirm: "Are you sure?" }, method: :delete %></p>
  HTML
  button_to = <<~HTML
    <div class="d-flex align-items-center">
      <div>Unhappy?</div>
      <%= button_to "Cancel my account", registration_path(resource_name), data: { confirm: "Are you sure?" }, method: :delete, class: "btn btn-link" %>
    </div>
  HTML
  gsub_file("app/views/devise/registrations/edit.html.erb", link_to, button_to)

  # Pages controller (skip autenticación en home)
  file "app/controllers/pages_controller.rb", <<~RUBY, force: true
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:home]

      def home; end
    end
  RUBY

  # Action mailer
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: "development"
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: "production"

  # Bootstrap y Popper
  append_file "config/importmap.rb", <<~RUBY
    pin "bootstrap", to: "bootstrap.min.js", preload: true
    pin "@popperjs/core", to: "popper.js", preload: true
  RUBY

  append_file "config/initializers/assets.rb", <<~RUBY
    Rails.application.config.assets.precompile += %w(bootstrap.min.js popper.js)
  RUBY

  append_file "app/javascript/application.js", <<~JS
    import "@popperjs/core"
    import "bootstrap"
  JS

  append_file "app/assets/config/manifest.js", <<~JS
    //= link popper.js
    //= link bootstrap.min.js
  JS

  # Plataforma Linux para Heroku
  run "bundle lock --add-platform x86_64-linux"

  # Archivo .env
  run "touch .env"

  # FactoryBot config con RSpec
  inject_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
    <<~RUBY
      config.include FactoryBot::Syntax::Methods
    RUBY
  end

  # CONVERTIR TODO .erb a .haml
  puts "*"*50
  puts "*"*50
  puts "Converting all .erb files to .haml..."
  puts "*"*50
  puts "*"*50
  run "bundle exec rails haml:erb2haml"

  # BORRAR los archivos .erb originales
  run "find app/views -name '*.erb' -delete"

  # Inyectar navbar y flashes en layout Haml
  inject_into_file "app/views/layouts/application.html.haml", after: "%body" do
    <<~HAML

      = render 'shared/navbar'
      = render 'shared/flashes'
    HAML
  end

  # Git
  git :init
  git add: "."
  git commit: "-m 'Initial commit from custom template (100% HAML)'"
end
