root_password   = data_bag_item('w_mysql', 'root_credential')['root_password']
db_host         = node['hostname'].downcase

## security config
# clean up empty user
[db_host, 'localhost', '%'].each do |empty_user_host|
  execute "delete default anonymous user @#{empty_user_host}" do
    command "mysql -uroot -p'#{root_password}' -h #{db_host} -e \"DELETE FROM mysql.user WHERE user='' AND host='#{empty_user_host}';\""
    action :run
  end
end

#change host % to localhost for root access
execute "update root host from % to #{db_host}" do
  command "mysql -uroot -p'#{root_password}' -h #{db_host} -e \"UPDATE mysql.user SET host='localhost' WHERE user='root' AND host='%';\""
  action :run
end

# apply root password on all hosts
[db_host, '192.168.33.1', '127.0.0.1', '::1', '%'].each do |root_host|
  execute "apply root password on @#{root_host}" do
    command "mysql -uroot -p'#{root_password}' -h #{db_host} -e \"UPDATE mysql.user SET password=password('#{root_password}') WHERE user='root' AND host='#{root_host}';\""
    action :run
  end
end
  
node['w_common']['web_apps'].each do |web_app|

  vhost = web_app['vhost']['main_domain']
  webapp_host     = web_app['connection_domain']['webapp_domain']

  Chef::Log.info("web_app['mysql'].class: #{web_app['mysql'].class}")

  if web_app['mysql'].instance_of?(Chef::Node::ImmutableArray) then
    Chef::Log.info("web_app['mysql'] is detected as Array #{web_app['mysql']}")
    databases = web_app['mysql']
  else
    Chef::Log.info("web_app['mysql'] is detected as non Array #{web_app['mysql']}")
    databases = []
    databases << web_app['mysql']
  end

  Chef::Log.info("databases.inspect: #{databases.inspect}")

  databases.each do |database|

    ## attributes
    webapp_db       = database['db']
    webapp_username = database['user']
    webapp_password = database['password']

    ## webapp related config
    execute "Create a mysql database #{webapp_db} for webapp #{vhost}" do
      command "mysql -uroot -p'#{root_password}' -h #{db_host} -e \"CREATE DATABASE IF NOT EXISTS #{webapp_db};\""
      action :run
    end

    webapp_hosts = []

    node['dbhosts']['webapp_ip'].each_index do |index|
      webapp_hosts << index.to_s + web_app['connection_domain']['webapp_domain']
    end

    webapp_hosts << 'localhost'

    webapp_hosts.each do |webapp_user_host|
      execute "Create a mysql user for webapp if not exist, and grant access of #{webapp_db} to user #{webapp_username} at host #{webapp_user_host} for vhost #{vhost}" do
        command "mysql -uroot -p'#{root_password}' -h #{db_host} -e \"GRANT ALL ON #{webapp_db}.* TO '#{webapp_username}'@'#{webapp_user_host}' IDENTIFIED BY '#{webapp_password}';\""
        action :run
      end
    end
  end
end

execute 'flush privileges' do
  command "mysqladmin -uroot -p'#{root_password}' -h #{db_host} reload"
  action :run
end