require 'rake-pipeline'
require 'rake-pipeline/middleware'
require 'rack/streaming_proxy'

use Rack::StreamingProxy do |request|
  if request.path.start_with?('/biologica/') || request.path.start_with?('/resources/')
    "http://geniverse.dev.concord.org#{request.path}"
  end
end

use Rake::Pipeline::Middleware, 'Assetfile' # This is the path to your Assetfile
run Rack::Directory.new('build') # This should match whatever your Assetfile's output directory is
