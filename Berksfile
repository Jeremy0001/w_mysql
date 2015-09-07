# -*- mode: ruby -*-
# vi: set ft=ruby :
source 'https://supermarket.chef.io'

cookbook 'ubuntu'
cookbook 'apt'
cookbook 'apt-repo', git: 'https://github.com/sometimesfood/chef-apt-repo.git'
cookbook 'git'
cookbook 'monit', git: 'https://github.com/phlipper/chef-monit.git'
cookbook 'firewall', git: 'https://github.com/opscode-cookbooks/firewall.git', ref: '3c4832f3498141287981a8687855531b0d746fc9'
cookbook 'ntp'
cookbook 'sudo'
cookbook 'timezone-ii'

cookbook 'mysql'

group :wrapper do
  cookbook 'w_mysql', path: './'
end
