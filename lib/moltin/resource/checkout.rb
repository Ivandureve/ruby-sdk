require 'moltin/api/crud_resource'
require 'moltin/api/request'
require 'moltin/resource/cart'
require 'moltin/resource/gateway'

module Moltin
  module Resource
    class Checkout < Moltin::Api::CrudResource

      attributes :id,
        :billing_address,
        :cart,
        :gateway,
        :shipping,
        :shipping_address

      attr_reader :gateways
      attr_reader :shipping_methods

      def retrieve
        @response = Moltin::Api::Request.get("carts/#{cart.identifier}/checkout")
        @gateways = Moltin::ResourceCollection.new 'Moltin::Resource::Gateway', @response.result['gateways'].map { |k, v| v }
        # raise @response.result['shipping']['methods'].to_yaml
        @shipping_methods = Moltin::ResourceCollection.new 'Moltin::Resource::ShippingMethod', @response.result['shipping']['methods']
        self
      end

      def requires_shipping?
        @response.result['shipping']['required']
      end

      def save
        data = {
          gateway: @data[:gateway],
          shipping: @data[:shipping],
          bill_to: (@data[:billing_address].data.compact if @data[:billing_address]),
          ship_to: (@data[:shipping_address].data.compact if @data[:shipping_address]) || "bill_to",
        }
        response = Moltin::Api::Request.post("carts/#{cart.identifier}/checkout", data)
        @order_id = response.result['id'] if response.success?
        response
      end

      def authorize!
        raise "Requires order to be placed" unless @order_id.present?
        data = {
          ip: '127.0.0.1',
          data: {
            number: '',
            expiry_month: '',
            expiry_year: '',
            start_year: '',
            cvv: '',
            issue_number: '',
            type: '',
          }
        }
        Moltin::Api::Request.post("checkout/payment/authorize/#{@order_id}", data)
      end

    end
  end
end
