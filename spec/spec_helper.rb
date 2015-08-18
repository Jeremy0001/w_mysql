require 'chefspec'
require 'chefspec/berkshelf'
require 'mymatchers'

ChefSpec::Coverage.start! do
  add_filter(%r{/vmware-tools/})
  add_filter(%r{/ntp/})
  add_filter(%r{/sudo/})
  add_filter(%r{/timezone-ii/})
  add_filter(%r{/memcached/})
  add_filter(%r{/apt/})
  add_filter(%r{/monit/})
  add_filter(%r{/apache2/})
  add_filter(%r{/php/})
  add_filter(%r{/phpmyadmin/})
  add_filter(%r{/build-essential/})
  add_filter(%r{/xdebug/})
  add_filter(%r{/git/})
  add_filter(%r{/varnish/})
  add_filter(%r{/apt-repo/})
  add_filter(%r{/percona/})
  add_filter(%r{/nfs/})
  add_filter(%r{/haproxy/})
  add_filter(%r{/keepalived/})  
end

RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '14.04'
  config.filter_run_excluding skip: true
end
