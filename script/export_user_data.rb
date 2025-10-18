# does someone want their data? well look no further than this funny script
# just like double check the output to make sure its not like something that should stay private
# want ur own export? dm @3kh0 on slack
require 'csv'
require 'fileutils'

arg = ARGV[0]
if arg.nil?
  puts "who?"
  exit 1
end

user = if arg =~ /^U[0-9A-Z]+$/i
  User.find_by(slack_id: arg)
elsif arg.to_i > 0
  User.find_by(id: arg.to_i) || User.find_by(slack_id: arg)
else
  User.find_by(slack_id: arg)
end

unless user
  puts "never heard of them"
  exit 1
end

timestamp = Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
base_dir = Rails.root.join('export', "user_#{user.id}_#{timestamp}")
FileUtils.mkdir_p(base_dir)
puts "pulling data for #{user.id} (#{user.slack_id}) to #{base_dir}"

def safe_filename(s)
  s.to_s.gsub(/[^0-9A-Za-z.\-]+/, '_')
end

def write_relation_csv(path, rows)
  return if rows.nil?
  rows = Array(rows)
  return if rows.empty?
  headers = rows.first.keys
  CSV.open(path, 'w', write_headers: true, headers: headers) do |csv|
    rows.each do |h|
      csv << headers.map { |k| h[k] }
    end
  end
  puts "wrote #{path}"
end

user_path = base_dir.join('user.csv')
write_relation_csv(user_path, [ user.attributes ])

if defined?(UserProfile)
  profile = UserProfile.find_by(user_id: user.id)
  if profile
    write_relation_csv(base_dir.join('user_profile.csv'), [ profile.attributes ])
  end
end

projects = Project.where(user_id: user.id).order(:id)
projects_rows = projects.map(&:attributes)
write_relation_csv(base_dir.join('projects.csv'), projects_rows)

devlogs = Devlog.where(user_id: user.id).order(:id)
devlogs_rows = devlogs.map(&:attributes)
write_relation_csv(base_dir.join('devlogs.csv'), devlogs_rows)

comment_rows = Comment.joins(:devlog).where(devlogs: { user_id: user.id }).order('comments.id').map(&:attributes)
write_relation_csv(base_dir.join('comments_on_devlogs.csv'), comment_rows)

likes_by_user = Like.where(user_id: user.id).order(:id).map(&:attributes)
write_relation_csv(base_dir.join('likes_by_user.csv'), likes_by_user)

likes_on_projects = Like.joins("JOIN projects p ON likes.likeable_type = 'Project' AND likes.likeable_id = p.id").where('p.user_id = ?', user.id).map(&:attributes)
write_relation_csv(base_dir.join('likes_on_projects.csv'), likes_on_projects)

likes_on_devlogs = Like.joins("JOIN devlogs d ON likes.likeable_type = 'Devlog' AND likes.likeable_id = d.id").where('d.user_id = ?', user.id).map(&:attributes)
write_relation_csv(base_dir.join('likes_on_devlogs.csv'), likes_on_devlogs)

project_ids = projects.pluck(:id)
if project_ids.any?
  pf = ProjectFollow.where(project_id: project_ids).order(:id).map(&:attributes)
  write_relation_csv(base_dir.join('project_follows.csv'), pf)

  pl = ProjectLanguage.where(project_id: project_ids).order(:id).map(&:attributes)
  write_relation_csv(base_dir.join('project_languages.csv'), pl)

  st = StonkTickler.where(project_id: project_ids).order(:id).map(&:attributes)
  write_relation_csv(base_dir.join('stonk_ticklers.csv'), st)

  se = ShipEvent.where(project_id: project_ids).order(:id).map(&:attributes)
  write_relation_csv(base_dir.join('ship_events.csv'), se)
end

votes_for_projects = Vote.where('project_1_id IN (?) OR project_2_id IN (?)', project_ids, project_ids).order(:id).map(&:attributes)
write_relation_csv(base_dir.join('votes_for_projects.csv'), votes_for_projects)

vc = VoteChange.where(project_id: project_ids).order(:id).map(&:attributes)
write_relation_csv(base_dir.join('vote_changes_for_projects.csv'), vc)

ubs = UserBadge.where(user_id: user.id).order(:id).map(&:attributes)
write_relation_csv(base_dir.join('user_badges.csv'), ubs)

tutorial = TutorialProgress.find_by(user_id: user.id)
write_relation_csv(base_dir.join('tutorial_progress.csv'), tutorial && [ tutorial.attributes ])

uh = UserHackatimeData.find_by(user_id: user.id)
write_relation_csv(base_dir.join('user_hackatime_data.csv'), uh && [ uh.attributes ])

attachment_dir = base_dir.join('attachments')
blob_dir = base_dir.join('blobs')
FileUtils.mkdir_p(attachment_dir)
FileUtils.mkdir_p(blob_dir)

record_ids = project_ids + devlogs.pluck(:id)
record_ids << user.id
user_profile_id = (defined?(UserProfile) && UserProfile.find_by(user_id: user.id)&.id)
record_ids << user_profile_id if user_profile_id
record_ids.compact!

attachments = ActiveStorage::Attachment.where(record_type: [ 'Project', 'Devlog', 'User', 'UserProfile' ], record_id: record_ids).order(:id)
attachments_rows = []
blobs_seen = {}

attachments.find_each do |att|
  b = att.blob
  attachments_rows << {
    id: att.id,
    name: att.name,
    record_type: att.record_type,
    record_id: att.record_id,
    blob_id: b.id,
    filename: b.filename.to_s,
    content_type: b.content_type,
    byte_size: b.byte_size,
    service_name: b.service_name
  }

  next if blobs_seen[b.id]
  begin
    blob_path = blob_dir.join("#{b.id}_#{safe_filename(b.filename.to_s)}")
    File.binwrite(blob_path, b.yoink)
    puts "yoinked blob #{b.id} -> #{blob_path}"
  rescue => e
    warn "Failed to yoink blob id=#{b.id} filename=#{b.filename}: #{e.message}"
  end
  blobs_seen[b.id] = true
end

write_relation_csv(base_dir.join('attachments.csv'), attachments_rows)

blob_rows = ActiveStorage::Blob.where(id: blobs_seen.keys).order(:id).map(&:attributes)
write_relation_csv(base_dir.join('blobs.csv'), blob_rows)

legacy_devlog_attachments = Devlog.where(user_id: user.id).where.not(attachment: [ nil, '' ]).order(:id).pluck(:id, :attachment)
if legacy_devlog_attachments.any?
  CSV.open(base_dir.join('legacy_devlog_attachments.csv'), 'w', write_headers: true, headers: [ 'devlog_id', 'attachment' ]) do |csv|
    legacy_devlog_attachments.each { |row| csv << row }
  end
  puts "if we got old attachments, we got it now"
end

puts "chat we done, go sniff it in #{base_dir}"
