require_relative '../spec_helper'

describe 'w_mysql::default' do

  context 'with default setting' do

    let(:web_apps) do
      [
        { vhost: {main_domain: 'examplewebsite.com'}, connection_domain: { webapp_domain: 'webapp.examplewebsite.com' }, mysql: [ { db: 'db1', user: 'user', password: 'pw' } ] },
        { vhost: {main_domain: 'ex.com'}, connection_domain: { webapp_domain: 'webapp.examplewebsite.com' }, mysql: [ { db: 'db2', user: 'user', password: 'pw' } ] }
      ]
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['w_common']['web_apps'] = web_apps
        node.set['dbhosts']['webapp_ip'] = ['1.1.1.1', '2.2.2.2']
        node.automatic['hostname'] = '0db.examplewebsite.com'
      end.converge(described_recipe)
    end

    before do
      stub_data_bag_item("w_mysql", "root_credential").and_return('id' => 'root_credential', 'root_password' => 'ilikerandompasswords')
    end

    it 'installs package mysql-server, mysql-client and starts mysql service' do
        expect(chef_run).to create_mysql_service('default').with(bind_address: '0.0.0.0', data_dir: '/data/db', initial_root_password: 'ilikerandompasswords')
        expect(chef_run).to create_mysql_client('default')
    end

    it 'enables firewall' do
      expect(chef_run).to install_firewall('default')
      expect(chef_run).to create_firewall_rule('mysql').with(port: 3306)
    end
  end
end