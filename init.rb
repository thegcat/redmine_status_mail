require 'redmine'

Redmine::Plugin.register :redmine_status_mail do
  name 'Redmine Status Mail plugin'
  author 'Felix Schäfer'
  description 'Adds a rake task to send users a single status email per day. This email will include stale (so many days since the start_date or since the last update) and ending-soon (so many days until end_date) tickets.'
  version 'trunk'
end
