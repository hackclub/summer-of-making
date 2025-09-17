# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_devlog

  def create
    authorize Comment
    # Fix commenting by extracting rich content from content
    rich = params.dig(:comment, :rich_content)
    plain_text = extract_text_from_rich_content(rich)

    @comment = @devlog.comments.build(comment_params.merge(content: plain_text))
    @comment.user = current_user

    if @comment.save
      current_user.update(has_commented: true) unless current_user.has_commented
      if @devlog.project
        redirect_to @devlog.project, notice: "Comment was successfully created."
      else
        redirect_to campfire_path, notice: "Comment was successfully created."
      end
    else
      if @devlog.project
        redirect_to @devlog.project, alert: "Failed to add comment."
      else
        redirect_to campfire_path, alert: "Failed to add comment."
      end
    end
  end

  private

  def extract_text_from_rich_content(rich_content)
    json = JSON.parse(rich_content)["json"] rescue nil
    return "" unless json && json["content"]

    json["content"].flat_map do |node|
      node["content"]&.map { |inner| inner["text"] } || []
    end.join(" ").strip
  end


  def destroy
    @comment = @devlog.comments.find(params[:id])
    authorize @comment
    unless @comment.user == current_user || current_user.is_admin?
      if @devlog.project
        redirect_to @devlog.project, alert: "You can only delete your own comments."
      else
        redirect_to campfire_path, alert: "You can only delete your own comments."
      end
      return
    end

    if @comment.destroy
      if @devlog.project
        redirect_to @devlog.project, notice: "Comment deleted successfully!"
      else
        redirect_to campfire_path, notice: "Comment deleted successfully!"
      end
    else
      if @devlog.project
        redirect_to @devlog.project, alert: "Failed to delete comment."
      else
        redirect_to campfire_path, alert: "Failed to delete comment."
      end
    end
  end

  private

  def set_devlog
    @devlog = Devlog.find(params[:devlog_id])
  end

  def comment_params
    params.require(:comment).permit(:content, :rich_content)
  end
end
