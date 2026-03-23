require_relative "api_case"

class JobsApiTest < ApiCase
  test "the list shape is flat, the detail shape nests" do
    get_api "/jobs"
    job = body["items"].find { |j| j["id"] == jobs(:furnace).id }
    assert_equal %w[id customer_id title description priority status created_at updated_at], job.keys

    get_api "/jobs/#{jobs(:furnace).id}"
    assert_equal %w[id customer_id title description priority status appointments job_parts invoice_record_id created_at updated_at],
      body.keys
    assert_equal [], body["appointments"]
    assert_nil body["invoice_record_id"]
  end

  test "filters combine" do
    get_api "/jobs", status: "requested", priority: "urgent"
    assert_equal [ jobs(:furnace).id ], body["items"].map { |j| j["id"] }

    get_api "/jobs", customer_id: customers(:harbor).id
    assert_equal [ jobs(:oven).id ], body["items"].map { |j| j["id"] }

    get_api "/jobs", q: "oven"
    assert_equal [ jobs(:oven).id ], body["items"].map { |j| j["id"] }
  end

  test "status accepts a comma-separated list" do
    jobs(:oven).transition_to!("cancelled")
    get_api "/jobs", status: "requested,cancelled"
    ids = body["items"].map { |j| j["id"] }
    assert_includes ids, jobs(:furnace).id
    assert_includes ids, jobs(:oven).id
  end

  test "create starts at requested and ignores a status in the body" do
    post_api "/jobs", { customer_id: customers(:quinn).id, title: "Water heater pilot", status: "completed" }
    assert_response :created
    assert_equal "requested", body["status"]
    assert_equal "normal", body["priority"]
  end

  test "patch updates fields but never status" do
    patch_api "/jobs/#{jobs(:oven).id}", { title: "Deck oven runs 30F cold", status: "invoiced" }
    assert_response :success
    assert_equal "Deck oven runs 30F cold", body["title"]
    assert_equal "requested", body["status"]
  end

  test "transition walks the machine" do
    job = jobs(:furnace)
    schedule(job: job, technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])

    post_api "/jobs/#{job.id}/transition", { status: "scheduled" }
    assert_response :success
    assert_equal "scheduled", body["status"]

    post_api "/jobs/#{job.id}/transition", { status: "completed" }
    assert_response :conflict
    assert_api_error "invalid_transition", "cannot move a job from scheduled to completed"
  end

  test "transition refuses unknown statuses before consulting the machine" do
    post_api "/jobs/#{jobs(:furnace).id}/transition", { status: "done" }
    assert_response :bad_request
    assert_api_error "validation_failed", "unknown status"

    post_api "/jobs/#{jobs(:furnace).id}/transition", {}
    assert_response :bad_request
    assert_api_error "validation_failed", "unknown status"
  end

  test "transition can never reach invoiced" do
    job = complete(jobs(:furnace))
    post_api "/jobs/#{job.id}/transition", { status: "invoiced" }
    assert_response :conflict
    assert_api_error "invalid_transition", "cannot move a job from completed to invoiced"
  end

  test "scheduling requires an appointment" do
    post_api "/jobs/#{jobs(:oven).id}/transition", { status: "scheduled" }
    assert_response :bad_request
    assert_api_error "validation_failed", "a job needs an appointment before it can be scheduled"
  end

  test "deleting is refused once invoiced" do
    job = complete(jobs(:furnace))
    job.invoice!

    delete_api "/jobs/#{job.id}"
    assert_response :bad_request
    assert_api_error "validation_failed", "an invoiced job cannot be deleted"

    delete_api "/jobs/#{jobs(:oven).id}"
    assert_response :no_content
  end

  test "every status pair answers correctly over the wire" do
    legal = {
      "requested" => %w[scheduled cancelled],
      "scheduled" => %w[in_progress cancelled],
      "in_progress" => %w[completed cancelled],
      "completed" => [],
      "invoiced" => [],
      "cancelled" => []
    }
    schedule(job: jobs(:fence_light), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])

    legal.each do |from, allowed|
      Dispatch::StatusMachine::STATUSES.each do |to|
        jobs(:fence_light).update_column(:status, from)
        post_api "/jobs/#{jobs(:fence_light).id}/transition", { status: to }
        if allowed.include?(to)
          assert_response :success, "#{from} -> #{to}"
        else
          assert_response :conflict, "#{from} -> #{to}"
        end
      end
    end
  end

  test "the detail shape nests appointments and job parts" do
    job = jobs(:furnace)
    appointment = schedule(job: job, technician: technicians(:reyes), from: [ 13 ], to: [ 14, 30 ])
    job_part = JobPart.create!(job: job, part: parts(:igniter), quantity: 3)

    get_api "/jobs/#{job.id}"
    nested = body["appointments"].sole
    assert_equal appointment.id, nested["id"]
    assert_equal "2025-03-12T13:00:00Z", nested["scheduled_start"]
    assert_equal %w[id job_id technician_id scheduled_start scheduled_end completion_notes created_at updated_at],
      nested.keys

    part_row = body["job_parts"].sole
    assert_equal job_part.id, part_row["id"]
    assert_equal 1299, part_row["unit_price_cents"]
    assert_equal %w[id job_id part_id quantity unit_price_cents created_at updated_at], part_row.keys
  end
end
