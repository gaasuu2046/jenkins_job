# TO BE UPDATED
#
# 2015/12/01
require 'serverspec'
require 'net/ssh'
require 'yaml'

set :backend, :ssh

#if ENV['ASK_SUDO_PASSWORD']
#  begin
#    require 'highline/import'
#  rescue LoadError
#    fail "highline is not available. Try installing it."
#  end
#  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
#else
#  set :sudo_password, ENV['SUDO_PASSWORD']
#end

# 共有スクリプトをrequireする処理
base_spec_dir = Pathname.new(File.join(File.dirname(__FILE__)))
Dir[base_spec_dir.join('../shared/*.rb')].sort.each{ |f| require f }


host = ENV['TARGET_HOST']

properties = YAML.load_file('properties.yml')[host]
set_property properties

#unless ENV['TARGET_HOST']
	options = Net::SSH::Config.for(host)
#else
#	options = Net::SSH::Config.for(host, files=[ENV['SSH_CONFIG_FILE']])
#end

#options[:user] ||= Etc.getlogin

set :host,        options[:host_name] || host
#set :ssh_options, options
set :ssh_options, options

# Disable sudo
# set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C' 

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'
