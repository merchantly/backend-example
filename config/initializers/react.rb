config = Rails.application.config

config.react.addons = true
# config.react.react_js = lambda {File.read(::Rails.application.assets.resolve('react.js'))}

config.react.server_renderer_pool_size  = 20 # ExecJS doesn't allow more than one on MRI, but nodej allows ;)
config.react.server_renderer_timeout    = 2 # seconds
config.react.server_renderer = React::ServerRendering::BundleRenderer

if Rails.env.development?
  config.react.server_renderer_options = {
    files: ['server_rendering.js', 'store_app_prerender.development.js'], # files to load for prerendering
    replay_console: true, # if true, console.* will be replayed client-side
  }
else
  config.react.variant = :production
  config.react.server_renderer_options = {
    files: ['server_rendering.js', 'store_app_prerender.production.js'], # files to load for prerendering
    replay_console: false, # if true, console.* will be replayed client-side
  }
end
