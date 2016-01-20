require 'chefspec'
require 'chefspec/berkshelf'
require 'mymatchers'

ChefSpec::Coverage.start! do
  add_filter(%r{[\/\\]chef-sugar[\/\\]})
  add_filter(%r{[\/\\]mysql[\/\\]})
end

RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '14.04'
end
