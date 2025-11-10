class TechniciansController < ApplicationController
  include Paged

  def index
    scope = Technician.order(:name)
    scope = scope.where(is_active: params[:show] != "inactive")
    if params[:skill].present?
      scope = scope.where(
        "EXISTS (SELECT 1 FROM json_each(technicians.skill_tags) WHERE json_each.value = ?)",
        params[:skill].downcase.strip
      )
    end
    @technicians, @pager = paginate(scope)
    @skills = Technician.pluck(:skill_tags).flatten.uniq.sort
  end

  def show
    @technician = Technician.find(params[:id])
    @upcoming = @technician.appointments.includes(job: :customer)
      .where(scheduled_start: Time.zone.now..).order(:scheduled_start).limit(10)
  end

  def schedule
    @technician = Technician.find(params[:id])
    @week_start = begin
      Date.iso8601(params[:week].to_s)
    rescue Date::Error
      Time.zone.today
    end.beginning_of_week
    week_range = @week_start.beginning_of_day..(@week_start + 6).end_of_day
    @by_day = @technician.appointments.includes(job: :customer)
      .where(scheduled_start: week_range)
      .order(:scheduled_start)
      .group_by { |appointment| appointment.scheduled_start.to_date }
  end

  def new
    @technician = Technician.new
  end

  def create
    @technician = Technician.new(technician_params)
    if @technician.save
      redirect_to @technician, notice: "Technician added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @technician = Technician.find(params[:id])
  end

  def update
    @technician = Technician.find(params[:id])
    if @technician.update(technician_params)
      redirect_to @technician, notice: "Technician updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    require_admin!
    return if performed?

    technician = Technician.find(params[:id])
    technician.destroy!
    redirect_to technicians_path, notice: "Technician removed."
  rescue Dispatch::ValidationFailed => error
    redirect_to technician, alert: error.message.upcase_first
  end

  private

  def technician_params
    attributes = params.expect(technician: [ :name, :phone, :hourly_cost_cents, :is_active, :skill_tags ])
    if attributes.key?(:skill_tags)
      attributes[:skill_tags] = attributes[:skill_tags].to_s.split(",")
    end
    attributes
  end
end
