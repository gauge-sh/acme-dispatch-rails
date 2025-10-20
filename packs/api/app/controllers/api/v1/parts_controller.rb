module Api
  module V1
    class PartsController < BaseController
      before_action :require_admin!, only: :destroy

      def index
        scope = Part.order(:id)
        if params[:q].present?
          needle = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].downcase)}%"
          scope = scope.where("LOWER(sku) LIKE :q OR LOWER(name) LIKE :q", q: needle)
        end
        render_page scope, item: Wire.method(:part)
      end

      def show
        render json: Wire.part(Part.find(params[:id]))
      end

      def create
        part = Part.create!(part_attributes)
        render json: Wire.part(part), status: :created
      end

      def update
        part = Part.find(params[:id])
        part.update!(part_attributes)
        render json: Wire.part(part)
      end

      def destroy
        Part.find(params[:id]).destroy!
        head :no_content
      end

      private

      def part_attributes
        body_attributes(:sku, :name, :unit_cost_cents, :unit_price_cents)
      end
    end
  end
end
