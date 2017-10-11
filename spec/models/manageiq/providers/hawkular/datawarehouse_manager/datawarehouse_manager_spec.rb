describe ManageIQ::Providers::Hawkular::DatawarehouseManager do
  context "#verify_ssl_mode" do
    let(:ems) { FactoryGirl.build(:ems_hawkular_datawarehouse) }

    it ".ems_type" do
      expect(described_class.ems_type).to eq("hawkular_datawarehouse")
    end

    it ".description" do
      expect(described_class.description).to eq("Hawkular Datawarehouse")
    end

    it ".event_monitor_class" do
      expect(described_class.event_monitor_class).to eq(ManageIQ::Providers::Hawkular::DatawarehouseManager::EventCatcher)
    end

    it "is secure by default when no security_protocol is sent" do
      endpoint = Endpoint.new(:security_protocol => nil)
      expect(ems.verify_ssl_mode(endpoint)).to eq(OpenSSL::SSL::VERIFY_PEER)
    end

    it "uses security_protocol when given" do
      # security_protocol should win over opposite verify_ssl
      endpoint = Endpoint.new(:security_protocol => 'ssl-with-validation',
                              :verify_ssl        => OpenSSL::SSL::VERIFY_NONE)
      expect(ems.verify_ssl_mode(endpoint)).to eq(OpenSSL::SSL::VERIFY_PEER)

      endpoint = Endpoint.new(:security_protocol => 'ssl-with-validation-custom-ca',
                              :verify_ssl        => OpenSSL::SSL::VERIFY_NONE)
      expect(ems.verify_ssl_mode(endpoint)).to eq(OpenSSL::SSL::VERIFY_PEER)

      endpoint = Endpoint.new(:security_protocol => 'ssl-without-validation',
                              :verify_ssl        => OpenSSL::SSL::VERIFY_PEER)
      expect(ems.verify_ssl_mode(endpoint)).to eq(OpenSSL::SSL::VERIFY_NONE)
    end

    it "validate_authentication_status" do
      expect(ems.validate_authentication_status).to eq(:available => true, :message => nil)
    end

    it "supports_port?" do
      expect(ems.supports_port?).to be_truthy
    end

    it "supported_auth_types" do
      expect(ems.supported_auth_types).to eq(%w(default auth_key))
    end

    it "required_credential_fields" do
      expect(ems.required_credential_fields("a_type")).to eq([:auth_key])
    end

    it "default_authentication_type" do
      expect(ems.default_authentication_type).to eq(:default)
    end

    it "supports_authentication?" do
      expect(ems.supports_authentication?("auth_key")).to be_truthy
      expect(ems.supports_authentication?("another_method")).to be_falsey
      expect(ems.supports_authentication?("default")).to be_truthy
    end

    context "#validation" do
      it "handles unknown error" do
        allow(ManageIQ::Providers::Hawkular::DatawarehouseManager).to receive(:raw_connect).and_raise(StandardError)
        expect { ems.verify_credentials }.to raise_error(MiqException::Error, /Unable to verify credentials/)
      end

      it "handles invalid host" do
        allow(ManageIQ::Providers::Hawkular::DatawarehouseManager).to receive(:raw_connect).and_raise(URI::InvalidComponentError)
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqHostError, /Host */)
      end

      it "handles connection error" do
        allow(ManageIQ::Providers::Hawkular::DatawarehouseManager).to receive(:raw_connect).and_raise(
          ::Hawkular::ConnectionException.new(nil, nil)
        )
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqUnreachableError, /Unable to connect to*/)
      end

      it "handles invalid credentials" do
        allow(ManageIQ::Providers::Hawkular::DatawarehouseManager).to receive(:raw_connect).and_raise(
          ::Hawkular::Exception.new("", 401)
        )
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError, /Invalid credentials/)
      end

      it "handles a host without hawkular" do
        allow(ManageIQ::Providers::Hawkular::DatawarehouseManager).to receive(:raw_connect).and_raise(
          ::Hawkular::Exception.new("", 404)
        )
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqHostError, /Hawkular not found on host/)
      end

      it "handles another hawkular exception" do
        allow(ManageIQ::Providers::Hawkular::DatawarehouseManager).to receive(:raw_connect).and_raise(
          ::Hawkular::Exception.new("Another code", 0)
        )
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqCommunicationsError, /Another code/)
      end
    end
  end
end
