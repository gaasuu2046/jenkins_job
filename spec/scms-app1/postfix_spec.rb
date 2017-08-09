require 'spec_helper'

exists = {
			'myhostname' => 'www.scms.mlit.go.jp',
			'myorigin' => '$mydomain',
			'inet_interfaces' => 'all',
}
commentout = {
			'inet_interfaces' => 'localhost',
}

describe package('postfix') do
  it { should be_installed }
end

describe service('postfix') do
  it { should be_running }
  it { should be_enabled }
end

describe file('/etc/postfix/main.cf') do
  exists.each do |key, value| 
    it { should contain "#{key} = #{value}"}
  end
  commentout.each do |k, v| 
    its(:content) { should_not match /^(\s*[^#]*\s*)#{k} = #{v}/ }
  end
end

describe port(25) do
  it { should be_listening }
end
