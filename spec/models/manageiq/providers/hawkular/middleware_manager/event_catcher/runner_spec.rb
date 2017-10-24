describe ManageIQ::Providers::Hawkular::MiddlewareManager::EventCatcher::Runner do
  subject do
    _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
    auth                 = AuthToken.new(:name     => "jdoe",
                                         :auth_key => "password",
                                         :userid   => "jdoe",
                                         :password => "password")
    ems                  = FactoryGirl.create(:ems_hawkular,
                                              :hostname        => 'localhost',
                                              :port            => 8080,
                                              :authentications => [auth],
                                              :zone            => zone)
    described_class.new(:ems_id => ems.id)
  end

  before do
    allow_any_instance_of(ManageIQ::Providers::Hawkular::MiddlewareManager)
      .to receive_messages(:authentication_check => [true, ""])
    allow_any_instance_of(MiqWorker::Runner).to receive(:worker_initialization)
  end

  context "#whitelist" do
    require 'hawkular/hawkular_client'

    it "accepts event tagged with known event_type" do
      event      = ::Hawkular::Alerts::Event.new({})
      event.tags = {'miq.event_type' => 'hawkular_event.critical'}
      expect(subject.send(:whitelist?, event)).to be true
    end

    it "rejects event tagged with unknown event_type" do
      event      = ::Hawkular::Alerts::Event.new({})
      event.tags = {'miq.event_type' => 'hawkular_event.unknown'}
      expect(subject.send(:whitelist?, event)).to be false
    end

    it "rejects event without event_type tag" do
      event = ::Hawkular::Alerts::Event.new({})
      expect(subject.send(:whitelist?, event)).to be false
    end
  end

  context "#event_hash" do
    require 'hawkular/hawkular_client'

    it "properly converts event supplying only required fields" do
      event = ::Hawkular::Alerts::Event.new({})
      event.ctime = Time.now.to_i
      event.text = 'text message'
      event.tags = {'miq.event_type' => 'hawkular_event.critical'}

      hash = subject.send(:event_to_hash, event, 1)
      expect(hash).to be_an Hash
      expect(hash[:ems_id]).to eq 1
      expect(hash[:source]).to eq 'HAWKULAR'
      expect(hash[:timestamp]).to be_an Time
      expect(hash[:event_type]).to eq 'hawkular_event.critical'
      expect(hash[:message]).to eq 'text message'
      expect(hash[:middleware_ref]).to be_nil
      expect(hash[:middleware_type]).to be_nil
      expect(hash[:full_data]).to be_an String
    end

    it "properly converts event supplying optional fields" do
      event = ::Hawkular::Alerts::Event.new({})
      event.ctime = Time.now.to_i
      event.text    = 'text message'
      event.context = {'resource_path' => 'canonical_path', 'message' => 'context message'}
      event.tags    = {'miq.event_type' => 'hawkular_event.critical', 'miq.resource_type' => 'MiddlewareServer'}

      hash = subject.send(:event_to_hash, event, 1)
      expect(hash).to be_an Hash
      expect(hash[:ems_id]).to eq 1
      expect(hash[:source]).to eq 'HAWKULAR'
      expect(hash[:timestamp]).to be_an Time
      expect(hash[:event_type]).to eq 'hawkular_event.critical'
      expect(hash[:message]).to eq 'context message'
      expect(hash[:middleware_ref]).to eq 'canonical_path'
      expect(hash[:middleware_type]).to eq 'MiddlewareServer'
      expect(hash[:full_data]).to be_an String
    end
  end

  context "event_monitor" do
    it "reset_event_monitor_handle" do
      expect(subject.instance_variable_get('@event_monitor_handle')).to be_nil
      subject.send(:reset_event_monitor_handle)
    end

    it "stop_event_monitor" do
      expect(subject).to receive(:reset_event_monitor_handle)
      expect(subject.instance_variable_get('@event_monitor_handle')).to be_nil
      subject.send(:stop_event_monitor)
    end

    context "event_monitor_handle" do
      it "event_monitor_handle not defined" do
        VCR.use_cassette(described_class.name.underscore.to_s,
                         :decode_compressed_response => true) do # , :record => :new_episodes) do
          subject.instance_variable_set('@event_monitor_handle', nil)
          subject.send(:event_monitor_handle)
          expect(subject.instance_variable_get('@event_monitor_handle')).to be_an ManageIQ::Providers::Hawkular::MiddlewareManager::EventCatcher::Stream
        end
      end
    end
  end

  it 'process_event' do
    subject.instance_variable_set('@filtered_events', ['hawkular_event.critical', 'hawkular_datasource.ok'])
    expect(subject.send(:blacklist?, "")).to be_falsey
    expect(subject.send(:blacklist?, "hawkular_event.critical")).to be_truthy
  end

  it 'process_event' do
    event = ::Hawkular::Alerts::Event.new({})
    event.ctime = Time.now.to_i
    event.text    = 'text message'
    event.context = {'resource_path' => 'canonical_path', 'message' => 'context message'}
    event.tags    = {'miq.event_type' => 'hawkular_event.critical', 'miq.resource_type' => 'MiddlewareServer'}
    event_hash = subject.send(:event_to_hash, event, 1)
    subject.instance_variable_set('@cfg', :ems_id => 1)
    subject.instance_variable_set('@filtered_events', ['hawkular_datasource.ok'])
    expect(EmsEvent).to receive(:add_queue).with('add', 1, event_hash)
    subject.send(:process_event, event)
  end

  it 'monitor_events' do
    VCR.use_cassette(described_class.name.underscore.to_s,
                     :decode_compressed_response => true) do # , :record => :new_episodes) do
      subject.send(:event_monitor_handle)
      monitor_handle = subject.instance_variable_get('@event_monitor_handle')
      expect(monitor_handle).to receive(:start)
      expect(subject).to receive(:reset_event_monitor_handle)
      subject.send(:monitor_events)
    end
  end
end
