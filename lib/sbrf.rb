require "sbrf/version"
require 'rest-client'

module Sbrf
  attr_accessor :return_url, :fail_url

  class SbrfResponse
    attr_accessor :error_code, :error_message
    def initialize(attributes={})
      @error_code = attributes['errorCode'].to_i
      @error_message = attributes['errorMessage']
    end

    def success?
      @error_code == 0
    end
  end

  class VerifyEnrollmentResponse < SbrfResponse
    def initialize(attributes={})
      @enrolled = attributes['enrolled']
      super(attributes)
    end

    def enrolled?
      @enrolled == 'Y'
    end
  end

  class RegisterDoResponse < SbrfResponse
    attr_accessor :order_id, :form_url
    def initialize(attributes={})
      @order_id = attributes['orderId']
      @form_url = attributes['formUrl']
      super(attributes)
    end
  end

  class ReverseDoResponse < SbrfResponse; end
  class RefundDoResponse < SbrfResponse; end

  class OrderStatusDoResponse < SbrfResponse
    attr_accessor :order_status, :order_number, :pan, :expiration,
      :cardholder_name, :amount, :currency, :approval_code, :ip
      # TODO: add other fields

    def initialize(attributes={})
      @order_status = (attributes['OrderStatus'] || attributes['orderStatus']).to_i
      @order_number = attributes['OrderNumber'] || attributes['orderNumber']
      @pan = attributes['Pan']
      @expiration = attributes['expiration']
      @cardholder_name = attributes['cardholderName']
      @amount = (attributes['Amount'] || attributes['amount']).to_i
      @currency = attributes['currency']
      @approval_code = attributes['approvalCode']
      @ip = attributes['ip']
      super(attributes)
    end
  end

  class << self
    def base_url
      if test_mode
        'https://3dsec.sberbank.ru/payment/rest/'
      else
        'https://securepayments.sberbank.ru/payment/rest/'
      end
    end

    def password=(password)
      @password = password
    end

    def user_name=(user_name)
      @user_name = user_name
    end

    def test_mode
      @test_mode
    end

    def test_mode=(test_mode)
      @test_mode = test_mode
    end

    def register_do(params)
      raise ArgumentError,
        "#register_do got unexpected object type: #{params.class.name}" unless params.is_a? Hash
      check_accounts_data
      params[:returnUrl] = return_url if return_url && !params.include?(:returnUrl)
      params[:failUrl] = fail_url if fail_url && !params.include?(:failUrl)
      required_params = [:orderNumber, :amount, :returnUrl]
      missing_params = required_params.inject([]) do |ans, key|
        ans << key unless params.keys.include?(key)
        ans
      end
      raise ArgumentError, "#register_do did not get next params: #{missing_params.join(',')}" if missing_params.any?
      res = RestClient.post base_url + 'register.do', form_params(params)
      RegisterDoResponse.new(JSON.parse(res.body))
    end

    def reverse_do(params)
      raise ArgumentError,
        "#reverse_do got unexpected object type: #{params.class.name}" unless params.is_a? Hash
      check_accounts_data
      raise ArgumentError, "#reverse_do did not get next params: orderId" unless params.keys.include?(:orderId)
      res = RestClient.post base_url + 'reverse.do', form_params(params)
      ReverseDoResponse.new(JSON.parse(res.body))
    end

    def refund_do(params)
      raise ArgumentError,
        "#refund_do got unexpected object type: #{params.class.name}" unless params.is_a? Hash
      check_accounts_data
      required_params = [:orderId, :amount]
      missing_params = required_params.inject([]) do |ans, key|
        ans << key unless params.keys.include?(key)
        ans
      end
      raise ArgumentError, "#refund_do did not get next params: #{missing_params.join(',')}" if missing_params.any?
      res = RestClient.post base_url + 'refund.do', form_params(params)
      RefundDoResponse.new(JSON.parse(res.body))
    end

    def getOrderStatus_do(params)
      raise ArgumentError,
        "#getOrderStatus_do got unexpected object type: #{params.class.name}" unless params.is_a? Hash
      check_accounts_data
      raise ArgumentError, "#getOrderStatus_do did not get next params: orderId" unless params.keys.include?(:orderId)
      res = RestClient.post base_url + 'getOrderStatus.do', form_params(params)
      OrderStatusDoResponse.new(JSON.parse(res.body))
    end

    def getOrderStatusExtended_do(params)
      raise ArgumentError,
        "#getOrderStatusExtended_do got unexpected object type: #{params.class.name}" unless params.is_a? Hash
      check_accounts_data
      raise ArgumentError, "#getOrderStatusExtended_do did not get next params:
        orderId or orderNumber" unless (params.keys.include?(:orderId) || params.keys.include?(:orderNumber))
      res = RestClient.post base_url + 'getOrderStatusExtended.do', form_params(params)
      OrderStatusDoResponse.new(JSON.parse(res.body))
    end

    def verifyEnrollment_do(params)
      raise ArgumentError,
        "#verifyEnrollment_do got unexpected object type: #{params.class.name}" unless params.is_a? Hash
      check_accounts_data
      raise ArgumentError, "#verifyEnrollment_do did not get next params: pan" unless params.keys.include?(:pan)
      res = RestClient.post base_url + 'verifyEnrollment.do', form_params(params)
      VerifyEnrollmentResponse.new(JSON.parse(res.body))
    end

    private

    def check_accounts_data
      raise 'Error: password cannot be empty' if @password.nil?
      raise 'Error: user name cannot be empty' if @user_name.nil?
    end

    def form_params(params)
      params.merge('userName' => @user_name, 'password' => @password)
    end
  end
end
