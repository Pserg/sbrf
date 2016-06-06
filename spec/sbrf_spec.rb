require 'spec_helper'
require 'webmock/rspec'

describe Sbrf do
  before :each do
    Sbrf.user_name = 'sbrf_user_name'
    Sbrf.password = 'sbrf_password'
  end

  describe 'register_do' do
    describe 'do request' do
      let(:params){ {orderNumber: 1, amount: 100, returnUrl: 'localhost:3000/success'} }

      before :each do
        stub_request(:post, 'https://3dsec.sberbank.ru/payment/rest/register.do').
          to_return(status: 200, body: '{"orderId":"70906e55-7114-41d6-8332-4609dc6590f4",
          "formUrl":"https://server/application_context/merchants/test/payment_ru.html?mdOrder=70906e55-7114-41d6-8332-4609dc6590f4",
          "errorCode":"0","errorMessage":"Успешно"}')
      end

      it 'success' do
        res = Sbrf.register_do(params)
        expect(res.success?).to eq true
        expect(res.order_id).to eq "70906e55-7114-41d6-8332-4609dc6590f4"
        expect(res.form_url).to eq "https://server/application_context/merchants/test/payment_ru.html?mdOrder=70906e55-7114-41d6-8332-4609dc6590f4"
      end

      describe 'required params' do
        let(:params){ {orderNumber: 1, amount: 100, returnUrl: 'localhost:3000/success'} }

        it 'without argument raise an error' do
          expect{ Sbrf.register_do }.to raise_error(ArgumentError)
        end

        it 'received not hash raise an error' do
          expect{ Sbrf.register_do('arg') }.to raise_exception(ArgumentError)
        end

        it 'raise an error without order_number' do
          params.delete(:orderNumber)
          expect{ Sbrf.register_do(params)}.to raise_error(ArgumentError)
        end

        it 'raise an error without amount' do
          params.delete(:amount)
          expect{ Sbrf.register_do(params)}.to raise_error(ArgumentError)
        end

        it 'raise an error without return_url' do
          params.delete(:returnUrl)
          expect{ Sbrf.register_do(params)}.to raise_error(ArgumentError)
        end
      end
    end

  end

  describe 'do reverse' do
    let(:params){ { orderId: "70906e55-7114-41d6-8332-4609dc6590f4" } }

    before :each do
      stub_request(:post, 'https://3dsec.sberbank.ru/payment/rest/reverse.do').
        to_return(status: 200, body: '{"errorCode":"0","errorMessage":"Успешно"}')
    end

    it 'success' do
      res = Sbrf.reverse_do(params)
      expect(res.success?).to eq true
    end
  end

  describe 'do refund' do
    let(:params){ { orderId: "70906e55-7114-41d6-8332-4609dc6590f4", amount: 100 } }

    before :each do
      stub_request(:post, 'https://3dsec.sberbank.ru/payment/rest/refund.do').
        to_return(status: 200, body: '{"errorCode":"0","errorMessage":"Успешно"}')
    end

    it 'success' do
      res = Sbrf.refund_do(params)
      expect(res.success?).to eq true
    end
  end

  describe 'do getOrderStatus' do
    let(:params){ { orderId: "70906e55-7114-41d6-8332-4609dc6590f4" } }

    before :each do
      stub_request(:post, 'https://3dsec.sberbank.ru/payment/rest/getOrderStatus.do').
        to_return(status: 200, body: '{"expiration":"201512","cardholderName":"trtr",
          "depositAmount":789789,"currency":"810","approvalCode":"123456",
          "authCode":2,"clientId":"666","bindingId":"07a90a5d-cc60-4d1b-a9e6-ffd15974a74f",
          "ErrorCode":"0","ErrorMessage":"Успешно","OrderStatus":2,
          "OrderNumber":"23asdafaf","Pan":"411111**1111","Amount":789789}')
    end

    it 'success' do
      res = Sbrf.getOrderStatus_do(params)
      expect(res.success?).to eq true
      expect(res.order_status).to eq 2
      expect(res.amount).to eq 789789
    end
  end

  describe 'do getOrderStatusExtended' do
    let(:params){ { orderId: "70906e55-7114-41d6-8332-4609dc6590f4" } }

    before :each do
      stub_request(:post, 'https://3dsec.sberbank.ru/payment/rest/getOrderStatusExtended.do').
        to_return(status: 200, body: '{"errorCode":"0","errorMessage":"Успешно",
        "orderNumber":"0784sse49d0s134567890","orderStatus":6,"actionCode":-2007,
        "actionCodeDescription":"Время сессии истекло","amount":33000,
        "currency":"810","date":1383819429914,"orderDescription":"",
        "merchantOrderParams":[{"name":"email","value":"yap"}],
        "attributes":[{"name":"mdOrder","value":"b9054496-c65a-4975-9418-1051d101f1b9"}],
        "cardAuthInfo":{"expiration":"201912","cardholderName":"Ivan",
          "secureAuthInfo":{"eci":6,"threeDSInfo":{"xid":"MDAwMDAwMDEzODM4MTk0MzAzMjM="}},
          "pan":"411111**1111"},"terminalId":"333333"}')
    end

    it 'success' do
      res = Sbrf.getOrderStatusExtended_do(params)
      expect(res.success?).to eq true
      expect(res.order_status).to eq 6
      expect(res.amount).to eq 33000
    end
  end

  describe 'do verifyEnrollment' do
    let(:params){ { pan: 4111111111111111 } }

    before :each do
      stub_request(:post, 'https://3dsec.sberbank.ru/payment/rest/verifyEnrollment.do').
        to_return(status: 200, body: '{"errorCode":"0","errorMessage":"Успешно",
        "emitterName":"TEST CARD","emitterCountryCode":"RU","enrolled":"Y"}')
    end

    it 'success' do
      res = Sbrf.verifyEnrollment_do(params)
      expect(res.success?).to eq true
      expect(res.enrolled?).to eq true
    end
  end
end
