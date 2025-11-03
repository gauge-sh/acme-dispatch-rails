class DashboardController < ApplicationController
  def show
    @counts_by_status = Job.group(:status).count
    @open_jobs = Job.where(status: %w[requested scheduled in_progress])
      .includes(:customer).order(updated_at: :desc).limit(10)
    @today = Appointment.includes(:technician, job: :customer)
      .where(scheduled_start: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)
      .order(:scheduled_start)
    @low_stock = StockLevel.includes(:part).where(quantity_on_hand: ..2).order(:quantity_on_hand).limit(8)
  end
end
