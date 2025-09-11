# tempchangelog.md

The following files have been modified with placeholder code for temporarily unlocked nav buttons:

- app/helpers/application_helper.rb - Modified `tab_unlocked?` method to temporarily unlock all tabs (explore, projects, vote, map)
- app/views/shared/_mobile_nav.html.erb - Added temporarily unlocked Map button to mobile navigation
- app/controllers/map_controller.rb - Commented out `check_identity_verification` before_action and method, added temporary bypass
- app/controllers/projects_controller.rb - Commented out `check_identity_verification` before_action and method, added temporary bypass
- app/controllers/votes_controller.rb - Commented out `check_identity_verification` before_action and method, added temporary bypass

All identity verification checks have been temporarily disabled to allow access to explore, projects, vote, and map pages without requiring identity verification.
