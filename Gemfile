source 'https://rubygems.org'

def darwin?
  RbConfig::CONFIG['host_os'] =~ /darwin/
end

def windows_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /mingw|mswin/i ? require_as : false
end

def linux_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /linux/ ? require_as : false
end

# Mac OS X
def darwin_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /darwin/ ? require_as : false
end

gem 'rails', '~> 6.1'

gem 'puma', '~> 5.6.2'

gem 'coffee-rails'

gem 'cloudflare-rails', '~> 2.4.0'

# gem 'rubyzip'
# gem 'zip-zip' # will load compatibility for old rubyzip API.
#
gem 'coppertone'

gem 'translit'

gem 'bootsnap', require: false

gem 'premailer-rails'
gem 'redcarpet'

# PDF
gem 'wicked_pdf'
# gem 'wkhtmltopdf-binary-edge', '~> 0.12.5.0'
gem 'wkhtmltopdf-binary'

gem 'truncate_html'

gem 'amo_crm', github: 'BrandyMint/amocrm'
# gem 'amo_crm', path: '../amocrm'

gem 'bitrix24_cloud_api', github: 'brandymint/bitrix24_cloud_api'

# feature
gem 'flipper', github: 'jnunemaker/flipper'
gem 'flipper-active_record', github: 'jnunemaker/flipper'
gem 'flipper-ui', github: 'jnunemaker/flipper'

gem 'country_select'

gem 'grape'
gem 'grape-entity'
gem 'grape-rails-cache'
gem 'grape-swagger'
gem 'grape-swagger-entity'
gem 'grape-swagger-representable'
gem 'gravatarify'
gem 'hashie-forbidden_attributes'

# Страые способы подключать swagger-ui в рельсы.
# Лежат тут чтобы знали то их уже пробовали
# gem 'grape-swagger-rails', github: 'BrandyMint/grape-swagger-rails'
# gem 'grape-swagger-ui'
# gem 'swagger-ui_rails'
gem 'swagger-ui_rails5', github: 'yunixon/swagger-ui_rails5'
# gem 'grape-swagger-ui'
gem 'rswag-ui'
# markdown для grape
gem 'kramdown'

gem 'counter_culture'
gem 'sorcery'

# Ломает порядок загрузки railtie и из-за
# него authority не ловит ошибки
# НЕ ВКЛЮЧАТЬ НИКОДА
# лежит тут как назидание потомкам
# gem 'grape-rails-routes'

gem 'rack-attack'
gem 'rack-utf8_sanitizer'

gem 'eu_central_bank'
gem 'money'
gem 'money-rails', '~> 1.15.0'
gem 'russian_central_bank', github: 'BrandyMint/russian_central_bank'

# Для постинг фото во vkontakte
gem 'multipart-post'

gem 'virtus'

# nullify nillify
gem 'strip_attributes'

gem 'unit'

gem 'simpleidn'

gem 'globalid'

gem 'activerecord-session_store', github: 'brandymint/activerecord-session_store'

gem 'activeadmin_addons'
gem 'active_median'
gem 'chartkick'
gem 'groupdate'
gem 'highcharts-rails'
gem 'hightop'

gem 'faraday', '~> 1.9.3'
gem 'faraday-detailed_logger'

gem 'moysklad', github: 'dapi/moysklad'
# gem 'moysklad', path: '../moysklad'

gem 'nokogiri-happymapper'

gem 'rack-traffic-logger', github: 'BrandyMint/rack-traffic-logger', branch: 'develop'

# Пакет работает именно в этом месте в Gemfile
# если опустить ниже - отваливается загрузка в production
gem 'rack-timeout', require: 'rack/timeout/base'

gem 'rack-request-id'

gem 'sidekiq', '< 7'
gem 'sidekiq-cron', '~> 1.4.0'
gem 'sidekiq-failures', github: 'mhfs/sidekiq-failures'
gem 'sidekiq-reset_statistics'
gem 'sidekiq-status'
gem 'sidekiq-unique-jobs'
# gem 'sidekiq-scheduler'

gem 'devise', '>= 4.6.0'

gem 'phone', github: 'BrandyMint/phone', branch: 'feature/russia'

gem 'gon'
gem 'pg-hstore'
# gem 'upsert'
gem 'active_record_upsert', github: 'jesjos/active_record_upsert'
gem 'google_drive', '~> 3.0.7'
gem 'hippie_csv'
gem 'roo'
gem 'roo-xls'

gem 'ancestry' # tree
# Use postgresql as the database for ActiveRecord
gem 'pg'

# А он реально гдето используется?
gem 'pg_search'

gem 'ransack', '~> 2.4.2'

gem 'addressable'

gem 'settingslogic'

gem 'i18n', '~> 1.8.11'
gem 'i18n-active_record'
gem 'i18n-js'

# https://github.com/randym/activeadmin-axlsx
gem 'activeadmin'
gem 'activeadmin-sortable', github: 'BrandyMint/activeadmin-sortable', branch: 'feature/sortable_ui'

# acts_as_list replacement
# http://benw.me/posts/sortable-bootstrap-tables/
gem 'ranked-model', github: 'mixonic/ranked-model', ref: '93f4502b776ae527d42bba9ad29eecf7137c6a76'

gem 'russian'

# Авторизация и аутентификация
gem 'authority'

gem 'hashie', '~> 3.4'

# TODO определиться с выбором
gem 'workflow'
gem 'workflow-activerecord', '~> 4.1'

gem 'enumerize'

gem 'semver2'

# Never accidentally send emails to real people from your staging environment.
gem 'recipient_interceptor'

gem 'aws-sdk'
gem 'mini_magick'

gem 'carrierwave', '~> 2.2.2'
gem 'carrierwave-aws', '~> 1.5.0'

# Контроллеры
gem 'has_scope'
gem 'inherited_resources'

gem 'active_link_to'

# Need for draper
gem 'activemodel-serializers-xml'
gem 'draper', '~> 3.1.0'

gem 'simple-navigation', '~> 3.14.0'
gem 'simple-navigation-bootstrap'

gem 'simple_form'

gem 'bootstrap-kaminari-views'
gem 'kaminari'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'haml-rails'
gem 'liquid'

gem 'liquid-rails', git: 'https://github.com/Shoplio/liquid-rails'

gem 'nprogress-rails'

# High performance memcached client for Ruby
gem 'dalli', '~> 3.2.1'

gem 'hiredis'
gem 'redis', require: ['redis', 'redis/connection/hiredis']

gem 'ruby-progressbar'

gem 'bugsnag'

gem 'sassc-rails'
# inspina
gem 'bootstrap-sass', '~> 3.2'
gem 'font-awesome-rails'

gem 'dropzonejs-rails'
gem 'switchery-rails'

# В операторской в меню
# Несовместим с новым sprockets
# gem 'ionicons-rails'
gem 'font-ionicons-rails'

gem 'sprockets'
gem 'sprockets-rails'

gem 'non-digest-assets'

gem 'react-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

gem 'mini_racer', '~> 0.3.1'

# TODO выпилить в пользу selectize
gem 'select2-rails'

gem 'babosa', git: 'https://github.com/norman/babosa'
gem 'best_in_place', git: 'https://github.com/mmotherwell/best_in_place'
gem 'cocoon'
gem 'friendly_id'
gem 'geocoder'
gem 'geoip'
gem 'meta-tags'
gem 'public_suffix'
gem 'thumbor_rails', '1.2.0'
gem 'validates'

gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-vkontakte'
gem 'omniauth-walletone'
gem 'omniauth-yandex'

gem 'vkontakte_api', github: '7even/vkontakte_api'

gem 'convead_client', github: 'Convead/convead_api_ruby_client'

# Уйти в пользу ActiveModel
gem 'mimemagic', github: 'mimemagicrb/mimemagic'
gem 'mime-types' # , ['~> 2.6', '>= 2.6.1'], require: 'mime/types/columnar'
gem 'reform'
gem 'reform-rails'

gem 'sitemap_generator'

gem 'datetimepicker-rails', github: 'zpaulovics/datetimepicker-rails', branch: 'master', submodules: true
gem 'momentjs-rails' # Used for datetimepicker in operator scope

gem 'jquery-minicolors-rails'
# Математические операции над rgb
gem 'color'

gem 'cloud_payments', github: 'platmart/cloud_payments'

gem 'valid_email', require: 'valid_email/validate_email'

gem 'http_accept_language'

gem 'file_validators', '~> 2.3.0'

gem 'fast_jsonapi'

# http://stackoverflow.com/questions/18693718/weak-etags-in-rails
# http://akshaykarle.github.io/blog/2014/09/17/rails-caching-with-nginx/
gem 'rails_weak_etags'

# Использовался только в Viber-клиенте
gem 'http'
gem 'ru_propisju'

gem 'http_logger'

gem 'auto_logger', github: 'BrandyMint/auto_logger'

gem 'logstash-logger'

gem 'noty_flash', github: 'BrandyMint/noty_flash'

gem 'influxdb'
gem 'savon', '~> 2.12.0'

gem 'activerecord-nulldb-adapter'

gem 'barby'
gem 'chunky_png'

gem 'keycloak'

gem 'postgres-copy'

gem 'find_with_order'

# NewRelic за неделю 100 GB бесплатных данных заполнил
# и просит дальше платить
# gem 'newrelic_rpm'

# source 'http://insecure.rails-assets.org' do
source 'https://rails-assets.org' do
  gem 'rails-assets-clipboard'
  gem 'rails-assets-dropzone', '~> 5.5'
  gem 'rails-assets-es5-shim', '~> 4.5.13'
  gem 'rails-assets-jsoneditor', '~> 6.2.1'
  gem 'rails-assets-modernizr', '~> 2.8.3'
  gem 'rails-assets-noty'
  gem 'rails-assets-selectize'
  gem 'rails-assets-StickyTableHeaders'
  gem 'rails-assets-sweetalert', '1.1.3'
  gem 'rails-assets-switchery', '~> 0.8.2'
end

group :development do
  gem 'rails_performance'
  gem 'solargraph', '~> 0.44.2'
  # Для rubocop
  gem 'ast', require: false
  gem 'foreman'
  gem 'parser', require: false # ENV['RAILS_ENV'] == 'rubocop'
  gem 'powerpack', require: false
  gem 'rainbow', require: false

  gem 'overcommit'
  # gem 'http_logger'

  # Mission: Easy custom autocompletion for arguments, methods and beyond. Accomplished for irb and any other readline-like console environments.
  gem 'better_errors'
  gem 'bond'

  #  necessary to use Better Errors' advanced features (REPL, local/instance variable inspection, pretty stack frame names).
  gem 'binding_of_caller'

  # Еще есть варинт с mailtrap.io
  gem 'letter_opener'
  gem 'letter_opener_web'
end

group :test, :development do
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'

  # gem 'spring-commands-rubocop'
  gem 'parallel_tests'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'ruby-prof', '>= 0.16.0', require: false
  gem 'scss_lint', require: false

  gem 'byebug'
  gem 'factory_bot_rails', '~> 5'
  gem 'growl', require: darwin_only('growl')
  gem 'rb-fsevent', require: darwin_only('rb-fsevent')
  gem 'rb-inotify', require: linux_only('rb-inotify')
  gem 'rspec-collection_matchers'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'ruby_gntp'
  gem 'vcr', require: false

  # Show failing specs instantly
  gem 'rspec-instafail', require: false

  gem 'guard'
  gem 'listen'
  gem 'terminal-notifier-guard', '~> 1.7.0', require: darwin_only('terminal-notifier-guard')

  gem 'guard-rails'
  gem 'guard-rspec'
end

group :test do
  gem 'rails-controller-testing', github: 'rails/rails-controller-testing'
  gem 'test-prof'
  gem 'webmock'
  # Sidekiq 5.2 conflict
  # gem 'fakeredis', require: 'fakeredis/rspec'
  gem 'email_spec', '>= 1.2.1'

  gem 'rack_session_access'

  gem 'database_cleaner'

  gem 'capybara'
  gem 'capybara-email'
  gem 'capybara-screenshot'
end

group :production, :staging do
  gem 'sd_notify'
end

group :deploy do
  gem 'capistrano', require: false
  gem 'capistrano3-puma', github: 'seuros/capistrano-puma', require: false
  gem 'capistrano-db-tasks', require: false
  gem 'capistrano-dotenv', require: false
  gem 'capistrano-faster-assets', require: false
  gem 'capistrano-git-with-submodules', require: false
  gem 'capistrano-maintenance', require: false
  gem 'capistrano-nvm', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-secrets-yml', require: false
  gem 'capistrano-shell', require: false
  gem 'capistrano-systemd-multiservice', github: 'brandymint/capistrano-systemd-multiservice', require: false
  gem 'capistrano-yarn', require: false
end

gem 'dotenv'
gem 'dotenv-rails', require: 'dotenv/rails-now'

gem 'bundler-audit', '~> 0.7.0'
