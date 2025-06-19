class Explore::DevlogsController < ApplicationController
  def index
    devlogs = Devlog.includes(:project, :user, file_attachment: :blob)
                    .where(projects: { is_deleted: false })
                    .order(created_at: :desc)
    @pagy, @devlogs = pagy(devlogs, items: 10)
  end
end
