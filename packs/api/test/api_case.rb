require "test_helper"

class ApiCase < ActionDispatch::IntegrationTest
  setup do
    @dispatcher_token = ApiToken.create!(user: users(:teddy), name: "suite").plaintext
    @admin_token = ApiToken.create!(user: users(:marisol), name: "suite-admin").plaintext
  end

  def get_api(path, token: @dispatcher_token, **query)
    get "/api/v1#{path}", params: query, headers: auth(token)
  end

  def post_api(path, body = {}, token: @dispatcher_token)
    post "/api/v1#{path}", params: body.to_json, headers: auth(token).merge(json)
  end

  def patch_api(path, body = {}, token: @dispatcher_token)
    patch "/api/v1#{path}", params: body.to_json, headers: auth(token).merge(json)
  end

  def delete_api(path, token: @dispatcher_token)
    delete "/api/v1#{path}", headers: auth(token)
  end

  def body
    JSON.parse(response.body)
  end

  def assert_api_error(code, message = nil)
    error = body.fetch("error")
    assert_equal code, error["code"]
    assert_equal message, error["message"] if message
  end

  def schedule(job:, technician:, from:, to:, day: [ 2025, 3, 12 ])
    Appointment.create!(
      job: job,
      technician: technician,
      scheduled_start: Time.utc(*day, *from),
      scheduled_end: Time.utc(*day, *to)
    )
  end

  def complete(job)
    schedule(job: job, technician: technicians(:okada), from: [ 9 ], to: [ 10 ]) if job.appointments.none?
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")
    job
  end

  private

  def auth(token)
    token ? { "Authorization" => "Bearer #{token}" } : {}
  end

  def json
    { "Content-Type" => "application/json" }
  end
end
