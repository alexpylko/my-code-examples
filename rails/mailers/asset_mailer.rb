class AssetMailer < ActionMailer::Base
  include Resque::Mailer
  helper :application

  def comment_posted(comment_id)
    @comment = Customer::Comment.find(comment_id)
    @asset = @comment.commentable
    @user = @comment.owner
    subject = if @comment.documents.present?
      "#{@user.full_name} added attachment to #{@asset.name}"
      else
      "#{@user.full_name} added comment to #{@asset.name}"
    end

    mail(to: @asset.notification_email_list, subject: subject)
  end

  def admin_contact_changed asset_id, current_user_id
  	@asset = ::Customer::Asset.find(asset_id)
    @current_user = User.find(current_user_id)
    @user = @asset.asset_owner
    subject = "#{@asset.name} is now assigned to #{@user.name}"

    mail(to: @asset.notification_email_list, subject: subject)
  end

  def asset_removed asset_id, id
    @asset = ::Customer::Asset.deleted.find(asset_id)
    @user = User.where(id: id).first || @asset.asset_owner
    subject = "#{@user.full_name} deleted #{@asset.name}"

    mail(to: @asset.notification_email_list, subject: subject)
  end
end