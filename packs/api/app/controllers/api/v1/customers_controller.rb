module Api
  module V1
    class CustomersController < BaseController
      def index
        scope = Customer.order(:id)
        if params[:q].present?
          needle = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].downcase)}%"
          scope = scope.where("LOWER(name) LIKE :q OR LOWER(service_address) LIKE :q", q: needle)
        end
        render_page scope, item: Wire.method(:customer)
      end

      def show
        render json: Wire.customer(Customer.find(params[:id]))
      end

      def create
        customer = Customer.create!(customer_attributes)
        render json: Wire.customer(customer), status: :created
      end

      def update
        customer = Customer.find(params[:id])
        customer.update!(customer_attributes)
        render json: Wire.customer(customer)
      end

      def destroy
        Customer.find(params[:id]).destroy!
        head :no_content
      end

      private

      def customer_attributes
        body_attributes(:name, :contact_email, :phone, :service_address, :notes)
      end
    end
  end
end
