require 'spec_helper'

describe 'liaavmdb001' do
  property[:roles].each do |role|
    include_examples "#{role}_spec"
  end
end