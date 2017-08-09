require 'spec_helper'

describe 'scms-app2' do
  property[:roles].each do |role|
    include_examples "#{role}_spec"
  end
end
