module Api
  # Builds the exact JSON shapes in docs/domain.md. Hash insertion order is
  # the wire order, so keys here are laid out deliberately.
  module Wire
    module_function

    def customer(customer)
      {
        id: customer.id,
        name: customer.name,
        contact_email: customer.contact_email,
        phone: customer.phone,
        service_address: customer.service_address,
        notes: customer.notes,
        **timestamps(customer)
      }
    end

    def technician(technician)
      {
        id: technician.id,
        name: technician.name,
        phone: technician.phone,
        skill_tags: technician.skill_tags,
        hourly_cost_cents: technician.hourly_cost_cents,
        is_active: technician.is_active,
        **timestamps(technician)
      }
    end

    def user(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        is_active: user.is_active,
        **timestamps(user)
      }
    end

    def part(part)
      {
        id: part.id,
        sku: part.sku,
        name: part.name,
        unit_cost_cents: part.unit_cost_cents,
        unit_price_cents: part.unit_price_cents,
        **timestamps(part)
      }
    end

    def job(job)
      {
        id: job.id,
        customer_id: job.customer_id,
        title: job.title,
        description: job.description,
        priority: job.priority,
        status: job.status,
        **timestamps(job)
      }
    end

    # The detail shape nests; the list shape above stays flat.
    def job_detail(job)
      {
        id: job.id,
        customer_id: job.customer_id,
        title: job.title,
        description: job.description,
        priority: job.priority,
        status: job.status,
        appointments: job.appointments.order(:scheduled_start, :id).map { |a| appointment(a) },
        job_parts: job.job_parts.order(:id).map { |jp| job_part(jp) },
        invoice_record_id: job.invoice_record&.id,
        **timestamps(job)
      }
    end

    def appointment(appointment)
      {
        id: appointment.id,
        job_id: appointment.job_id,
        technician_id: appointment.technician_id,
        scheduled_start: time(appointment.scheduled_start),
        scheduled_end: time(appointment.scheduled_end),
        completion_notes: appointment.completion_notes,
        **timestamps(appointment)
      }
    end

    def job_part(job_part)
      {
        id: job_part.id,
        job_id: job_part.job_id,
        part_id: job_part.part_id,
        quantity: job_part.quantity,
        unit_price_cents: job_part.unit_price_cents,
        **timestamps(job_part)
      }
    end

    def stock_level(stock_level)
      {
        id: stock_level.id,
        part_id: stock_level.part_id,
        quantity_on_hand: stock_level.quantity_on_hand,
        part: part(stock_level.part),
        **timestamps(stock_level)
      }
    end

    def invoice_record(record)
      {
        id: record.id,
        job_id: record.job_id,
        labor_cents: record.labor_cents,
        parts_cents: record.parts_cents,
        total_cents: record.total_cents,
        line_items: record.line_items.map { |line| line_item(line) },
        **timestamps(record)
      }
    end

    def line_item(line)
      {
        kind: line.kind,
        description: line.description,
        quantity: quantity(line.quantity),
        unit_cents: line.unit_cents,
        amount_cents: line.amount_cents,
        weekend: line.weekend
      }
    end

    # A bare number: 2, not 2.0; 1.5 for fractional hours.
    def quantity(value)
      value == value.to_i ? value.to_i : value.to_f
    end

    def time(value)
      value.utc.iso8601
    end

    def timestamps(record)
      { created_at: time(record.created_at), updated_at: time(record.updated_at) }
    end
  end
end
