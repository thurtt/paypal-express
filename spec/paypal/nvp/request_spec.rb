require 'spec_helper.rb'

describe Paypal::NVP::Request do
  let :attributes do
    {
      :username => 'nov',
      :password => 'password',
      :signature => 'sig'
    }
  end

  let :instance do
    Paypal::NVP::Request.new attributes
  end

  describe '.new' do
    context 'when any required parameters are missing' do
      it 'should raise AttrRequired::AttrMissing' do
        attributes.keys.each do |missing_key|
          insufficient_attributes = attributes.reject do |key, value|
            key == missing_key
          end
          expect do
            Paypal::NVP::Request.new insufficient_attributes
          end.should raise_error AttrRequired::AttrMissing
        end
      end
    end

    context 'when all required parameters are given' do
      it 'should succeed' do
        expect do
          Paypal::NVP::Request.new attributes
        end.should_not raise_error AttrRequired::AttrMissing
      end

      it 'should setup endpoint and version' do
        client = Paypal::NVP::Request.new attributes
        client.version.should == Paypal::API_VERSION
        client.class.endpoint.should == Paypal::NVP::Request::ENDPOINT[:production]
      end

      it 'should support sandbox mode' do
        sandbox_mode do
          client = Paypal::NVP::Request.new attributes
          client.class.endpoint.should == Paypal::NVP::Request::ENDPOINT[:sandbox]
        end
      end
    end
  end

  describe '#request' do
    it 'should POST to NPV endpoint' do
      expect do
        instance.request :RPCMethod
      end.should request_to Paypal::NVP::Request::ENDPOINT[:production], :post
    end

    context 'when got API error response' do
      before do
        fake_response 'SetExpressCheckout/failure'
      end

      it 'should raise Paypal::Exception::APIError' do
        expect do
          instance.request :SetExpressCheckout
        end.should raise_error(Paypal::Exception::APIError)
      end
    end

    context 'when got HTTP error response' do
      before do
        FakeWeb.register_uri(
          :post,
          Paypal::NVP::Request::ENDPOINT[:production],
          :body => "Invalid Request",
          :status => ["400", "Bad Request"]
        )
      end

      it 'should raise Paypal::Exception::APIError' do
        expect do
          instance.request :SetExpressCheckout
        end.should raise_error(Paypal::Exception::HttpError)
      end
    end
  end
end