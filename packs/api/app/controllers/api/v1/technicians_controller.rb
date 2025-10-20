module Api
  module V1
    class TechniciansController < BaseController
      before_action :require_admin!, only: :destroy

      def index
        scope = Technician.order(:id)
        scope = scope.where(is_active: boolean_param(:is_active)) unless params[:is_active].nil?
        if params[:skill].present?
          scope = scope.where(
            "EXISTS (SELECT 1 FROM json_each(technicians.skill_tags) WHERE json_each.value = ?)",
            params[:skill]
          )
        end
        render_page scope, item: Wire.method(:technician)
      end

      def show
        render json: Wire.technician(Technician.find(params[:id]))
      end

      def create
        technician = Technician.create!(technician_attributes)
        render json: Wire.technician(technician), status: :created
      end

      def update
        technician = Technician.find(params[:id])
        technician.update!(technician_attributes)
        render json: Wire.technician(technician)
      end

      def destroy
        Technician.find(params[:id]).destroy!
        head :no_content
      end

      private

      def technician_attributes
        attributes = body_attributes(:name, :phone, :hourly_cost_cents, :is_active)
        if params.key?(:skill_tags)
          attributes["skill_tags"] = params[:skill_tags].is_a?(Array) ? params[:skill_tags] : []
        end
        attributes
      end
    end
  end
end
