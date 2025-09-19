class Job < ApplicationRecord
  belongs_to :customer
  has_many :appointments, dependent: :destroy
  has_many :job_parts, dependent: :destroy

  enum :priority, %w[low normal urgent].index_by(&:itself), default: "normal", validate: true
  enum :status, Dispatch::StatusMachine::STATUSES.index_by(&:itself), default: "requested", validate: true

  normalizes :title, with: ->(value) { value.strip }
  normalizes :description, with: ->(value) { value.strip.presence }

  validates :title, presence: true, length: { maximum: 160 }
  validates :description, length: { maximum: 4000 }, allow_nil: true

  # Status only ever changes through here (or through invoicing); controllers
  # never write the column directly.
  def transition_to!(next_status)
    unless Dispatch::StatusMachine.status?(next_status)
      raise Dispatch::ValidationFailed, "unknown status"
    end

    Dispatch::StatusMachine.check_transition!(status, next_status, appointment_count: appointments.count)
    update!(status: next_status)
    self
  end
end
