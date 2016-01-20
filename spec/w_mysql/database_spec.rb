require_relative '../spec_helper'

describe 'w_mysql::database' do

  context 'with default setting' do

    let(:web_apps) do
      [
        { vhost: {main_domain: 'example.com'}, connection_domain: { webapp_domain: 'webapp.example.com' }, mysql: [ { db: 'db1', user: 'user', password: 'pw' } ] },
        { vhost: {main_domain: 'ex.com'}, connection_domain: { webapp_domain: 'webapp.example.com' }, mysql: [ { db: ['db2', 'db3', 'db4'], user: 'user', password: 'pw' } ] },
        { vhost: {main_domain: 'vhost-without-connectiondomain-and-mysql.com'}}
      ]
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['w_common']['web_apps'] = web_apps
        node.set['dbhosts']['webapp_ip'] = ['1.1.1.1', '2.2.2.2']
        node.automatic['hostname'] = 'dbhost.example.com'
      end.converge(described_recipe)
    end

    before do
      stub_command("mysqladmin --user=root --password='' version").and_return(true)
      stub_data_bag_item("w_mysql", "root_credential").and_return('id' => 'root_credential', 'root_password' => 'rootpassword')
    end

    ['dbhost.example.com', 'localhost', '%'].each do |empty_user_host|
      it "delete default anonymous user @ #{empty_user_host}" do
        expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"DELETE FROM mysql.user WHERE user='' AND host='#{empty_user_host}';\"")
      end
    end

    it "update root host from % to localhost" do
        expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"UPDATE mysql.user SET host='localhost' WHERE user='root' AND host='%';\"")
    end

    ['dbhost.example.com', '192.168.33.1', '127.0.0.1', '::1'].each do |root_host|
      it "apply root password on @#{root_host}" do
        expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"UPDATE mysql.user SET password=password('rootpassword') WHERE user='root' AND host='#{root_host}';\"")
      end
    end

    it 'Create a mysql database for webapp' do
      expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"CREATE DATABASE IF NOT EXISTS db1;\"")
      expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"CREATE DATABASE IF NOT EXISTS db2;\"")
      expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"CREATE DATABASE IF NOT EXISTS db3;\"")
      expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"CREATE DATABASE IF NOT EXISTS db4;\"")
    end

    ['example.com', 'ex.com'].each do |vhost|
      ['db1', 'db2', 'db3', 'db4'].each do |webapp_db|

        webapp_hosts = []

        webapp_hosts << '1.1.1.1'
        webapp_hosts << '2.2.2.2'

        ['1.1.1.1', '2.2.2.2'].each_index do |index|
          webapp_hosts << index.to_s + 'webapp.example.com'
        end

        webapp_hosts << 'localhost'

        webapp_hosts.each do |webapp_user_host|
          it "Create a mysql user for webapp if not exist, and grant access of #{webapp_db} to user user at host #{webapp_user_host} for vhost #{vhost}" do
            expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"GRANT ALL ON #{webapp_db}.* TO 'user'@'#{webapp_user_host}' IDENTIFIED BY 'pw';\"")
          end
        end
      end
    end

    it 'create user previleges for db1 for 0webapp.example.com' do
      expect(chef_run).to run_execute("mysql -uroot -p'rootpassword' -h'127.0.0.1' -e \"GRANT ALL ON db1.* TO 'user'@'0webapp.example.com' IDENTIFIED BY 'pw';\"")
    end

    it 'flush privileges' do
      expect(chef_run).to run_execute("mysqladmin -uroot -p'rootpassword' -h'127.0.0.1' reload")
    end
  end
end