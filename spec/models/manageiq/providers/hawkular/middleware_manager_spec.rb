describe ManageIQ::Providers::Hawkular::MiddlewareManager do
  let(:ems) { FactoryGirl.build(:ems_hawkular) }

  it ".ems_type" do
    expect(described_class.ems_type).to eq('hawkular')
  end

  it ".description" do
    expect(described_class.description).to eq('Hawkular')
  end

  describe "miq_id_prefix" do
    let(:random_id) { SecureRandom.hex(10) }
    let!(:my_region) do
      MiqRegion.my_region || FactoryGirl.create(:miq_region, :region => MiqRegion.my_region_number)
    end
    let(:random_region) do
      region = Random.rand(1..99) while !region || region == my_region.region
      MiqRegion.find_by(:region => region) || FactoryGirl.create(:miq_region, :region => region)
    end

    it "must return non-empty string" do
      rval = subject.miq_id_prefix
      expect(rval.to_s.strip).not_to be_empty
    end

    it "must prefix the provided string/identifier" do
      rval = subject.miq_id_prefix(random_id)

      expect(rval).to end_with(random_id)
      expect(rval).not_to eq(random_id)
    end

    it "must generate different prefixes for different providers" do
      ems_a = FactoryGirl.create(:ems_hawkular)
      ems_b = FactoryGirl.create(:ems_hawkular)

      expect(ems_a.miq_id_prefix).not_to eq(ems_b.miq_id_prefix)
    end

    it "must generate different prefixes for same provider on different MiQ region" do
      ems_a = FactoryGirl.create(:ems_hawkular)
      ems_b = ems_a.dup
      ems_b.id = described_class.id_in_region(ems_a.id % described_class::DEFAULT_RAILS_SEQUENCE_FACTOR, random_region.region)

      expect(ems_a.miq_id_prefix).not_to eq(ems_b.miq_id_prefix)
    end

    it "validate_authentication_status" do
      expect(ems.validate_authentication_status).to eq(:available => true, :message => nil)
    end

    it "verify_ssl_mode" do
      expect(described_class.verify_ssl_mode("ssl-without-validation")).to eq(OpenSSL::SSL::VERIFY_NONE)
      expect(described_class.verify_ssl_mode("other")).to eq(OpenSSL::SSL::VERIFY_PEER)
    end

    it "entrypoint" do
      expect(described_class.entrypoint("0.0.0.0", "9000", "non-ssl")).to eq(
        URI::HTTP.build(:host => "0.0.0.0", :port => "9000".to_i).to_s
      )
      expect(described_class.entrypoint("0.0.0.0", "9000", "")).to eq(
        URI::HTTP.build(:host => "0.0.0.0", :port => "9000".to_i).to_s
      )
      expect(described_class.entrypoint("0.0.0.0", "9000", nil)).to eq(
        URI::HTTP.build(:host => "0.0.0.0", :port => "9000".to_i).to_s
      )
      expect(described_class.entrypoint("0.0.0.0", "9000", "other")).to eq(
        URI::HTTPS.build(:host => "0.0.0.0", :port => "9000".to_i).to_s
      )
    end

    it "create_jdr_report" do
      expect(ems).to receive(:run_generic_operation).with(:JDR, "ref")
      ems.create_jdr_report("ref")
    end

    it "resume_middleware_server_group" do
      expect(ems).to receive(:run_generic_operation).with('Resume Servers', "ref")
      ems.resume_middleware_server_group("ref")
    end

    it "suspend_middleware_server_group" do
      expect(ems).to receive(:run_generic_operation).with('Suspend Servers', "ref", :timeout => 0)
      ems.suspend_middleware_server_group("ref", {})
      expect(ems).to receive(:run_generic_operation).with('Suspend Servers', "ref", :timeout => 10)
      ems.suspend_middleware_server_group("ref", :timeout => 10)
    end

    it "reload_middleware_server_group" do
      expect(ems).to receive(:run_generic_operation).with('Reload Servers', "ref")
      ems.reload_middleware_server_group("ref")
    end

    it "restart_middleware_server_group" do
      expect(ems).to receive(:run_generic_operation).with('Restart Servers', "ref")
      ems.restart_middleware_server_group("ref")
    end

    it "stop_middleware_server_group" do
      expect(ems).to receive(:run_generic_operation).with('Stop Servers', "ref", :timeout => 0)
      ems.stop_middleware_server_group("ref", {})
      expect(ems).to receive(:run_generic_operation).with('Stop Servers', "ref", :timeout => 10)
      ems.stop_middleware_server_group("ref", :timeout => 10)
    end

    it "start_middleware_server_group" do
      expect(ems).to receive(:run_generic_operation).with('Start Servers', "ref")
      ems.start_middleware_server_group("ref")
    end

    it "kill_middleware_domain_server" do
      expect(ems).to receive(:run_generic_operation).with(:Kill, "ref")
      ems.kill_middleware_domain_server("ref")
    end

    it "restart_middleware_domain_server" do
      expect(ems).to receive(:run_generic_operation).with(:Restart, "ref")
      ems.restart_middleware_domain_server("ref")
    end

    it "restart_middleware_server" do
      expect(ems).to receive(:run_generic_operation).with(:Shutdown, "ref", :restart => true)
      ems.restart_middleware_server("ref")
    end

    it "stop_middleware_domain_server" do
      expect(ems).to receive(:run_generic_operation).with(:Stop, "ref")
      ems.stop_middleware_domain_server("ref")
    end

    it "start_middleware_domain_server" do
      expect(ems).to receive(:run_generic_operation).with(:Start, "ref")
      ems.start_middleware_domain_server("ref")
    end

    it "stop_middleware_server" do
      expect(ems).to receive(:run_generic_operation).with(:Shutdown, "ref")
      ems.stop_middleware_server("ref")
    end

    it "reload_middleware_server" do
      expect(ems).to receive(:run_generic_operation).with(:Reload, "ref")
      ems.reload_middleware_server("ref")
    end

    it "resume_middleware_server" do
      expect(ems).to receive(:run_generic_operation).with(:Resume, "ref")
      ems.resume_middleware_server("ref")
    end

    it "suspend_middleware_server" do
      expect(ems).to receive(:run_generic_operation).with(:Suspend, "ref", :timeout => 0)
      ems.suspend_middleware_server("ref", {})
      expect(ems).to receive(:run_generic_operation).with(:Suspend, "ref", :timeout => 10)
      ems.suspend_middleware_server("ref", :timeout => 10)
    end

    it "shutdown_middleware_server" do
      expect(ems).to receive(:run_generic_operation).with(:Shutdown, "ref", :restart => false, :timeout => 0)
      ems.shutdown_middleware_server("ref", {})
      expect(ems).to receive(:run_generic_operation).with(:Shutdown, "ref", :restart => false, :timeout => 10)
      ems.shutdown_middleware_server("ref", :timeout => 10)
    end

    it "run_generic_operation" do
      data_operation = {
        :operationName => :JDR,
        :resourcePath  => "ref",
        :parameters    => {}
      }
      expect(ems).to receive(:run_operation).with(data_operation)
      ems.send(:run_generic_operation, :JDR, "ref", {})
    end

    it "run_specific_operation" do
      expect(ems).to receive(:run_operation).with({:resourcePath => "ref"}, :JDR)
      ems.send(:run_specific_operation, :JDR, "ref", {})
    end

    it "supports_port?" do
      expect(ems.send(:supports_port?)).to be_truthy
    end

    it "event_monitor_class" do
      expect(described_class.event_monitor_class).to eq(ManageIQ::Providers::Hawkular::MiddlewareManager::EventCatcher)
    end

    context "#validation" do
      it "handles unknown error" do
        allow(ManageIQ::Providers::Hawkular::MiddlewareManager).to receive(:raw_connect).and_raise(StandardError)
        expect { ems.verify_credentials }.to raise_error(MiqException::Error, /Unable to verify credentials/)
      end

      it "handles invalid host" do
        allow(ManageIQ::Providers::Hawkular::MiddlewareManager).to receive(:raw_connect).and_raise(URI::InvalidComponentError)
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqHostError, /Host */)
      end

      it "handles connection error" do
        allow(ManageIQ::Providers::Hawkular::MiddlewareManager).to receive(:raw_connect).and_raise(
          ::Hawkular::ConnectionException.new(nil, nil)
        )
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqUnreachableError, /Unable to connect to*/)
      end

      it "handles invalid credentials" do
        allow(ManageIQ::Providers::Hawkular::MiddlewareManager).to receive(:raw_connect).and_raise(
          ::Hawkular::Exception.new("", 401)
        )
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError, /Invalid credentials/)
      end
    end
  end

  describe 'middleware operations:' do
    subject(:ems) { FactoryGirl.create(:ems_hawkular) }
    let(:mw_server) do
      FactoryGirl.create(
        :hawkular_middleware_server,
        :ext_management_system => ems,
        :ems_ref               => '/f;f1/r;server'
      )
    end
    let(:mw_domain_server) do
      FactoryGirl.create(
        :hawkular_middleware_server,
        :ext_management_system => ems,
        :ems_ref               => '/t;hawkular/f;master.Unnamed%20Domain/r;Local~~/r;Local~%2Fhost%3Dmaster/r;Local~%2Fhost%3Dmaster%2Fserver%3Dserver-one'
      )
    end
    let(:mw_domain) do
      FactoryGirl.create(
        :hawkular_middleware_domain,
        :ext_management_system => ems,
        :ems_ref               => '/t;hawkular/f;master.Unnamed%20Domain/r;Local~~/r;Local~%2Fhost%3Dmaster'
      )
    end
    let(:mw_datasource) do
      FactoryGirl.create(
        :hawkular_middleware_datasource,
        :ext_management_system => ems,
        :server_id             => mw_server.id,
        :ems_ref               => '/t;hawkular/f;master.Unnamed%20Domain/r;Local~~/r;Local~%2fsubsystem%3ddatasources%2fdata-source%3dExampleDS'
      )
    end

    before(:all) do
      MiqServer.seed
      NotificationType.seed
    end

    def notification_expectations(mw_server, op_name, type_name)
      notification = Notification.last
      expect(notification.notification_type.name).to eq(type_name)
      expect(notification.options[:op_name]).to eq(op_name)
      expect(notification.options[:mw_server]).to eq("#{mw_server.name} (#{mw_server.feed})")
    end

    def timeline_server_expectations(mw_item, op_name, status)
      event = EmsEvent.last
      expect(event.ems_id).to eq(ems.id)
      expect(event.event_type).to eq("MwServer.#{op_name}.#{status}")
      expect(event.middleware_server_id).to eq(mw_item.id)
      expect(event.middleware_server_name).to eq(mw_item.name)
    end

    def timeline_domain_expectations(status)
      event = EmsEvent.last
      expect(event.ems_id).to eq(ems.id)
      expect(event.event_type).to eq("MwDomain.Stop.#{status}")
      expect(event.middleware_domain_id).to eq(mw_domain.id)
      expect(event.middleware_domain_name).to eq(mw_domain.name)
    end

    %w(shutdown suspend resume reload restart stop).each do |operation|
      describe operation do
        it "should create a user notification and timeline event on success" do
          allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_generic_operation) do |_, &callback|
            callback.perform(:success, nil)
          end

          ems.public_send("#{operation}_middleware_server", mw_server.ems_ref)
          queue = MiqQueue.last
          expect(queue).not_to be_nil
          queue.deliver

          op_name = operation.capitalize
          notification_expectations(mw_server, op_name.to_sym, 'mw_op_success')
          timeline_server_expectations(mw_server, op_name, "Success")
        end

        it "should create a user notification and timeline event on failure" do
          allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_generic_operation) do |_, &callback|
            callback.perform(:failure, 'Error')
          end

          ems.public_send("#{operation}_middleware_server", mw_server.ems_ref)
          queue = MiqQueue.last
          expect(queue).not_to be_nil
          queue.deliver

          op_name = operation.capitalize
          notification_expectations(mw_server, op_name.to_sym, 'mw_op_failure')
          timeline_server_expectations(mw_server, op_name, "Failed")
        end
      end
    end

    %w(start restart stop kill).each do |operation|
      describe "domain server specific '#{operation}' operation:" do
        it "should create a user notification and timeline event on success" do
          allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_generic_operation) do |_, &callback|
            callback.perform(:success, nil)
          end

          ems.public_send("#{operation}_middleware_domain_server",
                          mw_domain_server.ems_ref.sub(/%2Fserver%3D/, '%2Fserver-config%3D'),
                          {},
                          :original_resource_path => mw_domain_server.ems_ref)
          queue = MiqQueue.last
          expect(queue).not_to be_nil
          queue.deliver

          op_name = operation.capitalize
          notification_expectations(mw_domain_server, op_name.to_sym, 'mw_op_success')
          timeline_server_expectations(mw_domain_server, op_name, "Success")
        end

        it "should create a user notification and timeline event on failure" do
          allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_generic_operation) do |_, &callback|
            callback.perform(:failure, 'Error')
          end

          ems.public_send("#{operation}_middleware_domain_server",
                          mw_domain_server.ems_ref.sub(/%2Fserver%3D/, '%2Fserver-config%3D'),
                          {},
                          :original_resource_path => mw_domain_server.ems_ref)

          queue = MiqQueue.last
          expect(queue).not_to be_nil
          queue.deliver

          op_name = operation.capitalize
          notification_expectations(mw_domain_server, op_name.to_sym, 'mw_op_failure')
          timeline_server_expectations(mw_domain_server, op_name, "Failed")
        end
      end
    end

    describe 'domain stop operation' do
      it 'should create a user notification and timeline event on success' do
        allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_generic_operation) do |_, &callback|
          callback.perform(:success, nil)
        end

        ems.stop_middleware_server(mw_domain.ems_ref)
        MiqQueue.last.deliver

        notification_expectations(mw_domain, :Stop, 'mw_op_success')
        timeline_domain_expectations('Success')
      end

      it 'should create a user notification and timeline event on failure' do
        allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_generic_operation) do |_, &callback|
          callback.perform(:failure, nil)
        end

        ems.stop_middleware_server(mw_domain.ems_ref)
        MiqQueue.last.deliver

        notification_expectations(mw_domain, :Stop, 'mw_op_failure')
        timeline_domain_expectations('Failed')
      end
    end

    describe 'remove datasource operation' do
      it "should create a user notification and timeline event on success" do
        allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_specific_operation) do |_, &callback|
          callback.perform(:success, nil)
        end
        ems.public_send("remove_middleware_datasource", mw_datasource.ems_ref)

        notification_expectations(mw_server, "Remove Datasource", 'mw_op_success')
      end

      it "should create a user notification and timeline event on failure" do
        allow_any_instance_of(::Hawkular::Operations::Client).to receive(:invoke_specific_operation) do |_, &callback|
          callback.perform(:failure, 'Error')
        end

        ems.public_send("remove_middleware_datasource", mw_datasource.ems_ref)

        notification_expectations(mw_server, "Remove Datasource", 'mw_op_failure')
      end
    end
  end
end
