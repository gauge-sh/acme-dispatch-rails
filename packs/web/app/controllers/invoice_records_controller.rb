class InvoiceRecordsController < ApplicationController
  include Paged

  def index
    scope = InvoiceRecord.includes(job: :customer).order(id: :desc)
    if params[:customer_id].present?
      scope = scope.joins(:job).where(jobs: { customer_id: params[:customer_id] })
    end
    @records, @pager = paginate(scope)
    @customers = Customer.order(:name)
  end

  def show
    @record = InvoiceRecord.includes(:line_items, job: :customer).find(params[:id])
  end
end
