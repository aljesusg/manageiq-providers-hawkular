describe ManageIQ::Providers::Hawkular::DatawarehouseManager::EventCatcher::Runner do
  let(:ems) { FactoryGirl.create(:ems_kubernetes, :hostname => 'hostname') }
  let(:subject) { described_class.new }
  context "#find_target" do
    require 'hawkular/hawkular_client'

    it "find a target container node" do
      target = FactoryGirl.create(:container_node, :id => 999, :name => 'the_target')
      tags = {
        'type'     => 'node',
        'nodename' => target.name
      }
      expect(described_class.find_target(tags)).to eq(target)
    end
  end

  it "event_monitor_class" do
    expect(described_class.event_monitor_class).to eq(ManageIQ::Providers::Hawkular::DatawarehouseManager::EventCatcher::Stream)
  end

  it "log_handle" do
    expect(described_class.log_handle).to eq($datawarehouse_log)
  end
end
