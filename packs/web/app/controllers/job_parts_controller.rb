class JobPartsController < ApplicationController
  def create
    job = Job.find(params[:job_id])
    part = Part.find(params[:part_id])
    JobPart.create!(job: job, part: part, quantity: params[:quantity].to_i)
    redirect_to job, notice: "Recorded #{params[:quantity]} × #{part.name}."
  rescue Dispatch::Error => error
    redirect_to job, alert: error.message.upcase_first
  end

  def destroy
    job_part = JobPart.find(params[:id])
    job_part.destroy!
    redirect_to job_part.job, notice: "Part returned to stock."
  rescue Dispatch::Error => error
    redirect_to job_part.job, alert: error.message.upcase_first
  end
end
