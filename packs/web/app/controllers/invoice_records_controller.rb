class InvoiceRecordsController < ApplicationController
  include Paged

  def index
    @records, @pager = paginate(InvoiceRecord.includes(job: :customer).order(id: :desc))
  end

  def show
    @record = InvoiceRecord.includes(:line_items, job: :customer).find(params[:id])
  end
end
