class ApiTokensController < ApplicationController
  before_action :require_admin!

  def create
    user = User.find(params[:user_id])
    token = user.api_tokens.create(token_params)
    if token.persisted?
      # The plaintext lives in the flash for exactly one render.
      redirect_to user, notice: "Token issued. Copy it now — it will not be shown again: #{token.plaintext}"
    else
      redirect_to user, alert: token.errors.full_messages.first
    end
  end

  def destroy
    token = ApiToken.find(params[:id])
    token.destroy!
    redirect_to token.user, notice: "Token revoked."
  end

  private

  def token_params
    params.expect(api_token: [ :name ])
  end
end
