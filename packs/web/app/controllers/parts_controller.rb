class PartsController < ApplicationController
  include Paged

  def index
    scope = Part.includes(:stock_level).order(:name)
    if params[:q].present?
      needle = "%#{Part.sanitize_sql_like(params[:q].downcase)}%"
      scope = scope.where("LOWER(sku) LIKE :q OR LOWER(name) LIKE :q", q: needle)
    end
    @parts, @pager = paginate(scope)
  end

  def show
    @part = Part.find(params[:id])
    @recent_usage = @part.job_parts.includes(job: :customer).order(created_at: :desc).limit(10)
    @history = @part.stock_adjustments.includes(:user).order(id: :desc).limit(15)
  end

  def new
    @part = Part.new
  end

  def create
    @part = Part.new(part_params)
    if @part.save
      redirect_to @part, notice: "Part added to the catalog."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @part = Part.find(params[:id])
  end

  def update
    @part = Part.find(params[:id])
    if @part.update(part_params)
      redirect_to @part, notice: "Part updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    require_admin!
    return if performed?

    part = Part.find(params[:id])
    part.destroy!
    redirect_to parts_path, notice: "Part removed."
  rescue Dispatch::ValidationFailed => error
    redirect_to part, alert: error.message.upcase_first
  end

  def adjust_stock
    part = Part.find(params[:id])
    part.stock_level.adjust!(params[:delta].to_i, by: current_user, note: "manual adjustment")
    redirect_to part, notice: "Stock is now #{part.stock_level.reload.quantity_on_hand}."
  rescue Dispatch::Error => error
    redirect_to part, alert: error.message.upcase_first
  end

  private

  def part_params
    params.expect(part: [ :sku, :name, :unit_cost_cents, :unit_price_cents ])
  end
end
