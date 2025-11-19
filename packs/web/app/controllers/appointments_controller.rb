class AppointmentsController < ApplicationController
  def new
    @job = Job.find(params[:job_id])
    @appointment = @job.appointments.build
    @technicians = Technician.active.order(:name)
  end

  def create
    @job = Job.find(params[:job_id])
    @appointment = @job.appointments.build(appointment_params)
    save_or_rerender(:new)
  end

  def edit
    @appointment = Appointment.find(params[:id])
    @job = @appointment.job
    @technicians = Technician.active.order(:name)
  end

  def update
    @appointment = Appointment.find(params[:id])
    @job = @appointment.job
    @appointment.assign_attributes(appointment_params)
    save_or_rerender(:edit)
  end

  def destroy
    appointment = Appointment.find(params[:id])
    appointment.destroy!
    redirect_to appointment.job, notice: "Appointment removed."
  end

  private

  # Conflicts and window errors come out of the domain as exceptions; they
  # belong on the form next to everything else.
  def save_or_rerender(failed_action)
    @appointment.save!
    redirect_to @job, notice: "Appointment saved."
  rescue Dispatch::Error => error
    @appointment.errors.add(:base, error.message)
    @technicians = Technician.active.order(:name)
    render failed_action, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid
    @technicians = Technician.active.order(:name)
    render failed_action, status: :unprocessable_entity
  end

  def appointment_params
    params.expect(appointment: [ :technician_id, :scheduled_start, :scheduled_end, :completion_notes ])
  end
end
