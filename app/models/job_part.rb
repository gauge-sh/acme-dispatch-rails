# A part used on a job. Creating one takes the quantity out of stock in the
# same transaction; deleting one puts it back — unless the job has been
# invoiced, at which point the record is part of the bill and frozen.
class JobPart < ApplicationRecord
  belongs_to :job
  belongs_to :part

  validates :quantity, presence: true, numericality: { only_integer: true }

  before_create :consume_stock
  before_destroy :release_stock

  private

  def consume_stock
    Dispatch::StatusMachine.check_accepts_parts!(job.status)
    part.stock_level.consume!(quantity)
  end

  def release_stock
    if job.invoiced?
      raise Dispatch::ValidationFailed, "an invoiced job cannot be changed"
    end

    part.stock_level.release!(quantity)
  end
end
