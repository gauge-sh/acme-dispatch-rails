class CustomersController < ApplicationController
  include Paged

  def index
    @q = params[:q].to_s.strip
    scope = Customer.order(:name)
    if @q.present?
      needle = "%#{Customer.sanitize_sql_like(@q.downcase)}%"
      scope = scope.where("LOWER(name) LIKE :q OR LOWER(service_address) LIKE :q", q: needle)
    end
    @customers, @pager = paginate(scope)
  end

  def show
    @customer = Customer.find(params[:id])
    @jobs = @customer.jobs.order(created_at: :desc)
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to @customer, notice: "Customer added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @customer = Customer.find(params[:id])
  end

  def update
    @customer = Customer.find(params[:id])
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    customer = Customer.find(params[:id])
    customer.destroy!
    redirect_to customers_path, notice: "Customer removed."
  rescue Dispatch::ValidationFailed => error
    redirect_to customer, alert: error.message.upcase_first
  end

  private

  def customer_params
    params.expect(customer: [ :name, :contact_email, :phone, :service_address, :notes ])
  end
end
