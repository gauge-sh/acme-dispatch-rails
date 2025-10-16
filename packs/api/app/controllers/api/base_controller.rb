module Api
  class BaseController < ActionController::API
    DOMAIN_ERROR_STATUS = {
      "validation_failed" => :bad_request,
      "invalid_transition" => :conflict,
      "schedule_conflict" => :conflict,
      "insufficient_stock" => :conflict
    }.freeze

    before_action :authenticate!

    rescue_from Dispatch::Error, with: :domain_error
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    rescue_from ActionDispatch::Http::Parameters::ParseError do
      render_error "validation_failed", "request body is not valid json", :bad_request
    end

    private

    attr_reader :current_token

    def current_user = current_token.user

    def authenticate!
      @current_token = ApiToken.authenticate(bearer_token)
      return render_error("unauthorized", "invalid or missing token", :unauthorized) unless @current_token

      @current_token.touch_last_used
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end

    def require_admin!
      render_error "forbidden", "admin role required", :forbidden unless current_user.admin?
    end

    def render_error(code, message, status, fields: nil)
      error = { code: code, message: message }
      error[:fields] = fields if fields.present?
      render json: { error: error }, status: status
    end

    def domain_error(exception)
      render_error exception.code, exception.message, DOMAIN_ERROR_STATUS.fetch(exception.code),
        fields: exception.fields
    end

    def not_found(exception)
      resource = exception.model ? exception.model.underscore.humanize.downcase : "record"
      render_error "not_found", "#{resource} not found", :not_found
    end

    def record_invalid(exception)
      errors = exception.record.errors
      fields = errors.attribute_names.without(:base).index_with { |name| errors[name].first }
      render_error "validation_failed", first_error_message(errors), :bad_request,
        fields: fields.presence
    end

    # Base errors carry contract wording verbatim; attribute errors read as
    # "name can't be blank".
    def first_error_message(errors)
      base = errors[:base].first
      return base if base

      message = errors.full_messages.first.to_s
      message[0].downcase + message[1..]
    end

    # The shared list envelope. Key order is part of the wire contract.
    def render_page(scope, item:)
      page, per_page = pagination_params
      render json: {
        items: scope.offset((page - 1) * per_page).limit(per_page).map { |record| item.call(record) },
        page: page,
        per_page: per_page,
        total: scope.count
      }
    end

    def pagination_params
      page = positive_int(params[:page], default: 1)
      per_page = positive_int(params[:per_page], default: 20)
      unless page && per_page
        raise Dispatch::ValidationFailed, "page and per_page must be positive integers"
      end

      [ page, [ per_page, 100 ].min ]
    end

    def positive_int(raw, default:)
      return default if raw.nil?
      return nil unless raw.to_s.match?(/\A[1-9]\d*\z/)

      raw.to_i
    end

    # PATCH semantics: absent keys stay untouched, explicit nulls clear.
    # Slicing by presence in the raw body keeps that distinction.
    def body_attributes(*keys)
      params.slice(*keys).permit!.to_h
    end

    def boolean_param(key)
      case params[key]
      when "true" then true
      when "false" then false
      else raise Dispatch::ValidationFailed, "#{key} must be true or false"
      end
    end

    def parse_time!(raw, field)
      Time.iso8601(raw)
    rescue ArgumentError, TypeError
      raise Dispatch::ValidationFailed, "#{field} must be an iso-8601 timestamp"
    end
  end
end
