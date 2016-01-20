root_password   = data_bag_item('w_mysql', 'root_credential')['root_password']
db_host         = node['hostname'].downcase

## security config
# clean up empty user
[db_host, 'localhost', '%'].each do |empty_user_host|
  execute "delete default anonymous user @#{empty_user_host}" do
    command "mysql -uroot -p'#{root_password}' -h'127.0.0.1' -e \"DELETE FROM mysql.user WHERE user='' AND host='#{empty_user_host}';\""
    action :run
  end
end

#change host % to localhost for root access
execute "update root host from % to #{db_host}" do
  command "mysql -uroot -p'#{root_password}' -h'127.0.0.1' -e \"UPDATE mysql.user SET host='localhost' WHERE user='root' AND host='%';\""
  action :run
end

# apply root password on all hosts
[db_host, '192.168.33.1', '127.0.0.1', '::1'].each do |root_host|
  execute "apply root password on @#{root_host}" do
    command "mysql -uroot -p'#{root_password}' -h'127.0.0.1' -e \"UPDATE mysql.user SET password=password('#{root_password}') WHERE user='root' AND host='#{root_host}';\""
    action :run
  end
end

node['w_common']['web_apps'].each do |web_app|

  next unless web_app.has_key?('mysql')

  vhost = web_app['vhost']['main_domain']
  webapp_host     = web_app['connection_domain']['webapp_domain']

  if web_app['mysql'].instance_of?(Chef::Node::ImmutableArray) then
    databases = web_app['mysql']
  else
    databases = []
    databases << web_app['mysql']
  end

  databases.each do |database|

    if database['db'].instance_of?(Chef::Node::ImmutableArray) then
      webapp_dbs = database['db']
    else
      webapp_dbs = []
      webapp_dbs << database['db']
    end

    webapp_username = database['user']
    webapp_password = database['password']

    webapp_dbs.each do |webapp_db|

      execute "Create a mysql database #{webapp_db} for webapp #{vhost}" do
        command "mysql -uroot -p'#{root_password}' -h'127.0.0.1' -e \"CREATE DATABASE IF NOT EXISTS #{webapp_db};\""
        action :run
      end

      webapp_hosts = []

      node['dbhosts']['webapp_ip'].each do |webapp_ip|
        webapp_hosts << webapp_ip
      end

      node['dbhosts']['webapp_ip'].each_index do |index|
        webapp_hosts << index.to_s + web_app['connection_domain']['webapp_domain']
      end

      webapp_hosts << 'localhost'

      webapp_hosts.each do |webapp_user_host|
        execute "Create a mysql user for webapp if not exist, and grant access of #{webapp_db} to user #{webapp_username} at host #{webapp_user_host} for vhost #{vhost}" do
          command "mysql -uroot -p'#{root_password}' -h'127.0.0.1' -e \"GRANT ALL ON #{webapp_db}.* TO '#{webapp_username}'@'#{webapp_user_host}' IDENTIFIED BY '#{webapp_password}';\""
          action :run
        end
      end
    end
  end
end

execute 'flush privileges' do
  command "mysqladmin -uroot -p'#{root_password}' -h'127.0.0.1' reload"
  action :run
end
