# Rails Template by Santiago Almiron

Quickly bootstrap a modern Rails 7 app using this custom template based on [Le Wagon's Rails templates](https://github.com/lewagon/rails-templates).

This template builds on the original `devise.rb` template and includes the following:

## Features

- ✅ Rails 7-ready
- 🔐 Devise with `User` model and authentication
- 💅 Bootstrap 5.3, Font Awesome 6, Simple Form (with Bootstrap)
- ⚙️ dotenv for managing environment variables
- 🧪 RSpec + FactoryBot + Faker for testing
- 🧹 Rubocop + Rubocop-Rails + Rubocop-RSpec for code linting
- 🧱 Layout, flash messages, and navbar from Le Wagon
- 📝 HAML as template engine (including auto-conversion tools)
- 🚀 Heroku-friendly (Linux platform locked)
- 🔧 Smart generator configuration and cleaned-up defaults

## Usage

To generate a new Rails app using this template, run:

```bash
rails new \
  -d postgresql \
  -m https://raw.githubusercontent.com/SantiagoAlmiron/rails-template-santiago-almiron/refs/heads/master/template.rb \
  YOUR_APP_NAME
