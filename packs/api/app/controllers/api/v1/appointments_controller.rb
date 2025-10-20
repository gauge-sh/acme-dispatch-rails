module Api
  module V1
    class AppointmentsController < BaseController
      def index
        scope = Appointment.order(:scheduled_start, :id)
        scope = scope.where(job_id: params[:job_id]) if params[:job_id].present?
        scope = scope.where(technician_id: params[:technician_id]) if params[:technician_id].present?
        if params[:from].present?
          scope = scope.where(scheduled_start: parse_time!(params[:from], "from")..)
        end
        if params[:to].present?
          scope = scope.where(scheduled_start: ..parse_time!(params[:to], "to"))
        end
        render_page scope, item: Wire.method(:appointment)
      end

      def show
        render json: Wire.appointment(Appointment.find(params[:id]))
      end

      def create
        appointment = Appointment.create!(appointment_attributes)
        render json: Wire.appointment(appointment), status: :created
      end

      def update
        appointment = Appointment.find(params[:id])
        appointment.update!(appointment_attributes)
        render json: Wire.appointment(appointment)
      end

      def destroy
        Appointment.find(params[:id]).destroy!
        head :no_content
      end

      private

      def appointment_attributes
        attributes = body_attributes(:job_id, :technician_id, :completion_notes)
        %w[scheduled_start scheduled_end].each do |field|
          next unless params.key?(field)

          attributes[field] = parse_time!(params[field], field)
        end
        attributes
      end
    end
  end
end
