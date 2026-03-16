class Job < ApplicationRecord
  belongs_to :customer
  has_many :appointments, dependent: :destroy
  has_many :job_parts, dependent: :destroy
  has_one :invoice_record, dependent: :destroy

  enum :priority, %w[low normal urgent].index_by(&:itself), default: "normal", validate: true
  enum :status, Dispatch::StatusMachine::STATUSES.index_by(&:itself), default: "requested", validate: true

  scope :open_for_work, -> { where(status: Dispatch::StatusMachine::OPEN_FOR_SCHEDULING) }

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

  # The only path to `invoiced`: prices the job, writes the record and moves
  # the status, all in one transaction.
  def invoice!
    transaction do
      priced = Dispatch::Invoicing.draft(
        status: status,
        priority: priority,
        labor: appointments.includes(:technician).map { |appointment|
          Dispatch::Pricing::LaborItem.new(
            appointment_id: appointment.id,
            technician_name: appointment.technician.name,
            hourly_cost_cents: appointment.technician.hourly_cost_cents,
            starts_at: appointment.scheduled_start,
            ends_at: appointment.scheduled_end
          )
        },
        parts: job_parts.includes(:part).map { |job_part|
          Dispatch::Pricing::PartItem.new(
            job_part_id: job_part.id,
            sku: job_part.part.sku,
            name: job_part.part.name,
            quantity: job_part.quantity,
            unit_price_cents: job_part.unit_price_cents
          )
        },
        already_invoiced: InvoiceRecord.exists?(job_id: id)
      )

      record = create_invoice_record!(
        labor_cents: priced.labor_cents,
        parts_cents: priced.parts_cents,
        total_cents: priced.total_cents
      )
      priced.line_items.each_with_index do |line, index|
        record.line_items.create!(
          position: index + 1,
          kind: line.kind,
          description: line.description,
          quantity: line.quantity,
          unit_cents: line.unit_cents,
          amount_cents: line.amount_cents,
          weekend: line.weekend
        )
      end
      update!(status: "invoiced")
      record
    end
  end
end
