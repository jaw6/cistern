require 'spec_helper'

class WaitForModel < Sample::Model
  identity :id

  attribute :name
end

class WaitForModels < Sample::Collection
  model WaitForModel

  def get(_identity)
    self
  end
end

describe 'Cistern#wait_for' do
  it 'should return false if timeout exceeded' do
    expect(Cistern.wait_for(0, 0) { false }).to be_falsey
  end
end

describe 'Cistern#wait_for!' do
  it 'should raise if timeout exceeded' do
    expect { Cistern.wait_for!(0, 0) { false } }.to raise_exception(Cistern::Timeout)
  end
end

describe 'Cistern::Model#wait_for!' do
  let(:service) { Sample.new }
  let(:model)   { service.wait_for_models.new(identity: 1) }

  it 'should raise if timeout exceeded' do
    expect { model.wait_for!(0, 0) { false } }.to raise_exception(Sample::Timeout)
  end
end

describe 'WaitForModel#timeout' do
  let(:service) { Sample.new }
  let(:model)   { service.wait_for_models.new(identity: 1) }

  it 'should use service-specific timeout in #wait_for' do
    service.class.timeout = 0.1
    service.class.poll_interval = 0

    elapsed = 0

    Timeout.timeout(2) do
      expect do
        model.wait_for! { sleep(0.2); elapsed += 0.2; elapsed > 0.2 }
      end.to raise_exception(Sample::Timeout)
    end
  end

  it 'should favor explicit timeout' do
    service.class.timeout = 1
    service.class.poll_interval = 0

    elapsed = 0

    Timeout.timeout(2) do
      expect do
        model.wait_for!(0.1) { sleep(0.2); elapsed += 0.2; elapsed > 0.2 }
      end.to raise_exception(Sample::Timeout)
    end
  end
end
