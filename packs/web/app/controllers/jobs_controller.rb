class JobsController < ApplicationController
  include Paged

  def index
    scope = Job.includes(:customer).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
    if params[:q].present?
      needle = "%#{Job.sanitize_sql_like(params[:q].downcase)}%"
      scope = scope.where("LOWER(title) LIKE ?", needle)
    end
    @jobs, @pager = paginate(scope)
    @customers = Customer.order(:name)
  end

  def show
    @job = Job.includes(appointments: :technician, job_parts: :part).find(params[:id])
    @appointments = @job.appointments.sort_by { |a| [ a.scheduled_start, a.id ] }
    @next_statuses = Dispatch::StatusMachine.allowed(@job.status) - [ "invoiced" ]
    @parts_in_stock = Part.joins(:stock_level).where(stock_levels: { quantity_on_hand: 1.. }).order(:name)
  end

  def new
    @job = Job.new(customer_id: params[:customer_id])
    @customers = Customer.order(:name)
  end

  def create
    @job = Job.new(job_params)
    if @job.save
      redirect_to @job, notice: "Job opened."
    else
      @customers = Customer.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @job = Job.find(params[:id])
    @customers = Customer.order(:name)
  end

  def update
    @job = Job.find(params[:id])
    if @job.update(job_params)
      redirect_to @job, notice: "Job updated."
    else
      @customers = Customer.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    job = Job.find(params[:id])
    if job.invoiced?
      return redirect_to job, alert: "An invoiced job cannot be deleted."
    end

    job.destroy!
    redirect_to jobs_path, notice: "Job deleted."
  end

  def transition
    job = Job.find(params[:id])
    job.transition_to!(params[:status].to_s)
    redirect_to job, notice: "Job is now #{job.status.humanize.downcase}."
  rescue Dispatch::Error => error
    redirect_to job, alert: error.message.upcase_first
  end

  def invoice
    job = Job.find(params[:id])
    record = job.invoice!
    redirect_to invoice_record_path(record), notice: "Invoice record created."
  rescue Dispatch::Error => error
    redirect_to job, alert: error.message.upcase_first
  end

  private

  def job_params
    params.expect(job: [ :customer_id, :title, :description, :priority ])
  end
end
