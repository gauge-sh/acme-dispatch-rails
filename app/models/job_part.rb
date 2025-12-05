# A part used on a job. Creating one takes the quantity out of stock in the
# same transaction; deleting one puts it back — unless the job has been
# invoiced, at which point the record is part of the bill and frozen.
class JobPart < ApplicationRecord
  belongs_to :job
  belongs_to :part

  validates :quantity, presence: true, numericality: { only_integer: true }

  before_create :capture_unit_price
  before_create :consume_stock
  before_destroy :release_stock

  private

  def capture_unit_price
    self.unit_price_cents ||= part.unit_price_cents
  end

  def consume_stock
    Dispatch::StatusMachine.check_accepts_parts!(job.status)
    part.stock_level.consume!(quantity, note: "used on job ##{job_id}")
  end

  def release_stock
    if job.invoiced?
      raise Dispatch::ValidationFailed, "an invoiced job cannot be changed"
    end

    part.stock_level.release!(quantity, note: "returned from job ##{job_id}")
  end
end
