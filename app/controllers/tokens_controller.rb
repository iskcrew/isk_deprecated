# frozen_string_literal: true

# Controller for access tokens, only creation and deletion are currently handled here
class TokensController < ApplicationController
  # ACLs, we require global admin priviledges for all user token operations
  before_action :require_global_admin

  def create
    user = User.find(params[:user_id])
    loop do
      t = SecureRandom.urlsafe_base64
      next unless AuthToken.where(token: t).count.zero?
      # Got unique token
      token = user.auth_tokens.new(token: t)
      token.save!
      redirect_to users_path && return
    end
  end

  def destroy
    User.find(params[:user_id]).auth_tokens.find(params[:id]).destroy
    redirect_to users_path
  end
end
