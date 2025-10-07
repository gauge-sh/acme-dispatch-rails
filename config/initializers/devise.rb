Devise.setup do |config|
  require "devise/orm/active_record"

  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [ :http_auth ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
