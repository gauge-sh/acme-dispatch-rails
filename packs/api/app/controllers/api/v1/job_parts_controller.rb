module Api
  module V1
    class JobPartsController < BaseController
      def create
        job = Job.find(params[:id])
        part = Part.find(params[:part_id])
        unless params[:quantity].is_a?(Integer)
          raise Dispatch::ValidationFailed, "quantity must be an integer"
        end

        job_part = JobPart.create!(job: job, part: part, quantity: params[:quantity])
        render json: Wire.job_part(job_part), status: :created
      end

      def destroy
        JobPart.find(params[:id]).destroy!
        head :no_content
      end
    end
  end
end
