module Api
  module V1
    class UsersController < BaseController
      before_action :require_admin!

      def index
        scope = User.order(:id)
        scope = scope.where(role: params[:role]) if params[:role].present?
        scope = scope.where(is_active: boolean_param(:is_active)) unless params[:is_active].nil?
        render_page scope, item: Wire.method(:user)
      end

      def show
        render json: Wire.user(User.find(params[:id]))
      end

      def create
        user = User.create!(user_attributes)
        render json: Wire.user(user), status: :created
      end

      def update
        user = User.find(params[:id])
        attributes = user_attributes
        guard_self_edit(user, attributes)
        user.update!(attributes)
        render json: Wire.user(user)
      end

      def destroy
        User.find(params[:id]).destroy!
        head :no_content
      end

      private

      def user_attributes
        attributes = body_attributes(:email, :name, :role, :is_active, :password)
        # A null password is meaningless rather than a clearing: drop it.
        attributes.delete("password") if attributes["password"].nil?
        attributes
      end

      def guard_self_edit(user, attributes)
        return unless user == current_user

        if attributes.key?("role") && attributes["role"] != user.role
          raise Dispatch::ValidationFailed, "you cannot change your own role"
        end
        if attributes.key?("is_active") && attributes["is_active"] != true
          raise Dispatch::ValidationFailed, "you cannot deactivate yourself"
        end
      end
    end
  end
end
