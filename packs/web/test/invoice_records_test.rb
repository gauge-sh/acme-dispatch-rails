require_relative "web_case"

class InvoiceRecordsTest < WebCase
  setup { sign_in_dispatcher }

  def invoice_furnace
    job = jobs(:furnace)
    Appointment.create!(
      job: job, technician: technicians(:reyes),
      scheduled_start: Time.utc(2025, 3, 12, 13), scheduled_end: Time.utc(2025, 3, 12, 14, 30)
    )
    JobPart.create!(job: job, part: parts(:igniter), quantity: 3)
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")
    job.invoice!
  end

  test "empty state points at the job flow" do
    get invoice_records_path
    assert_select ".empty", text: /Complete a job/
  end

  test "lists records with totals" do
    record = invoice_furnace
    get invoice_records_path
    assert_select "td a", text: record.id.to_s
    assert_select "td.amount strong", text: "$254.07"
  end

  test "filters by customer" do
    record = invoice_furnace
    get invoice_records_path(customer_id: customers(:meridian).id)
    assert_select "td a", text: record.id.to_s

    get invoice_records_path(customer_id: customers(:quinn).id)
    assert_select ".empty", text: "Nothing billed for this customer."
  end

  test "exports a csv of what to bill" do
    record = invoice_furnace
    get invoice_records_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type

    rows = CSV.parse(response.body, headers: true)
    assert_equal 1, rows.size
    assert_equal record.id.to_s, rows.first["id"]
    assert_equal "25407", rows.first["total_cents"]
    assert_equal "Meridian Property Group", rows.first["customer"]
  end

  test "shows the line items with surcharge badges" do
    record = invoice_furnace
    get invoice_record_path(record)
    assert_response :success
    assert_select "td", text: /Dana Reyes — 1\.5h on 2025-03-12/
    assert_select "td", text: /IGN-4420 — Hot surface igniter/
    assert_select ".badge.priority-urgent", text: "urgent +10%"
    assert_select "tfoot td.amount strong", text: "$254.07"
  end
end
