module Api
  module V1
    class StockLevelsController < BaseController
      def index
        scope = StockLevel.includes(:part).order(:part_id)
        scope = scope.where(part_id: params[:part_id]) if params[:part_id].present?
        render_page scope, item: Wire.method(:stock_level)
      end

      def adjust
        stock_level = StockLevel.find_by!(part_id: params[:part_id])
        unless params[:delta].is_a?(Integer)
          raise Dispatch::ValidationFailed, "delta must be an integer"
        end

        stock_level.adjust!(params[:delta])
        render json: Wire.stock_level(stock_level)
      end
    end
  end
end
