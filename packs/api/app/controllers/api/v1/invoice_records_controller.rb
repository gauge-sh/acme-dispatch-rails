module Api
  module V1
    class InvoiceRecordsController < BaseController
      def index
        scope = InvoiceRecord.includes(:line_items).order(:id)
        scope = scope.where(job_id: params[:job_id]) if params[:job_id].present?
        if params[:customer_id].present?
          scope = scope.joins(:job).where(jobs: { customer_id: params[:customer_id] })
        end
        render_page scope, item: Wire.method(:invoice_record)
      end

      def show
        render json: Wire.invoice_record(InvoiceRecord.find(params[:id]))
      end

      def create
        record = Job.find(params[:id]).invoice!
        render json: Wire.invoice_record(record), status: :created
      end
    end
  end
end
