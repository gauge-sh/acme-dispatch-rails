module Api
  module V1
    class JobsController < BaseController
      def index
        scope = Job.order(:id)
        if params[:status].present?
          scope = scope.where(status: params[:status].split(","))
        end
        scope = scope.where(priority: params[:priority]) if params[:priority].present?
        scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
        if params[:q].present?
          needle = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].downcase)}%"
          scope = scope.where("LOWER(title) LIKE ?", needle)
        end
        render_page scope, item: Wire.method(:job)
      end

      def show
        render json: Wire.job_detail(Job.find(params[:id]))
      end

      def create
        job = Job.create!(job_attributes)
        render json: Wire.job_detail(job), status: :created
      end

      def update
        job = Job.find(params[:id])
        job.update!(job_attributes)
        render json: Wire.job_detail(job)
      end

      def destroy
        job = Job.find(params[:id])
        if job.invoiced?
          raise Dispatch::ValidationFailed, "an invoiced job cannot be deleted"
        end

        job.destroy!
        head :no_content
      end

      def transition
        job = Job.find(params[:id])
        job.transition_to!(params[:status].is_a?(String) ? params[:status] : nil)
        render json: Wire.job_detail(job)
      end

      private

      # `status` is deliberately not on this list: create and update ignore
      # it rather than erroring.
      def job_attributes
        body_attributes(:customer_id, :title, :description, :priority)
      end
    end
  end
end
