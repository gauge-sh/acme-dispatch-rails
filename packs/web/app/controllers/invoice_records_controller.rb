require "csv"

class InvoiceRecordsController < ApplicationController
  include Paged

  def index
    scope = InvoiceRecord.includes(job: :customer).order(id: :desc)
    if params[:customer_id].present?
      scope = scope.joins(:job).where(jobs: { customer_id: params[:customer_id] })
    end

    respond_to do |format|
      format.html do
        @records, @pager = paginate(scope)
        @customers = Customer.order(:name)
      end
      format.csv do
        send_data csv_for(scope), filename: "invoice-records.csv", type: "text/csv"
      end
    end
  end

  def show
    @record = InvoiceRecord.includes(:line_items, job: :customer).find(params[:id])
  end

  private

  def csv_for(records)
    CSV.generate do |csv|
      csv << %w[id job customer labor_cents parts_cents total_cents created_at]
      records.each do |record|
        csv << [
          record.id, record.job.title, record.job.customer.name,
          record.labor_cents, record.parts_cents, record.total_cents,
          record.created_at.utc.iso8601
        ]
      end
    end
  end
end
