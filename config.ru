require 'bundler'

Bundler.setup
Bundler.require
require 'rack/contrib/try_static'

use Rack::TryStatic,
    root: "_site",
    urls: %w(/),
    try: %w(.html index.html /index.html)

run ->(env) { [404, { "Content-Type" => "text/html" }, ["Not Found"] ]  }
