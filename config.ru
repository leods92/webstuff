require 'bundler'

Bundler.setup
Bundler.require
require 'rack/contrib/try_static'

use Rack::TryStatic,
    root: "public",
    urls: %w(/),
    try: %w(.html index.html /index.html)

run -> { [404, { "Content-Type" => "text/html" }, ["Not Found"] ]  }
