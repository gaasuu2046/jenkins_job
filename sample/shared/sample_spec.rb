describe port(22) do
  	it { should be_listening }
end

describe service('ntpd') do
	it { should be_enabled }
	it { should be_running }
end
