root_password = data_bag_item('w_mysql', 'root_credential')['root_password']

mysql_service 'default' do
  bind_address '0.0.0.0'
  data_dir '/data/db'
  initial_root_password root_password
  action [:create, :start]
end

mysql_client 'default'

include_recipe 'w_mysql::database'

firewall 'default'

firewall_rule 'mysql' do
  port 3306
end