desc <<-END_DESC
END_DESC

namespace :redmine do
  task :send_status_mails => :environment do
    options = {}
    options[:panic_days] = ENV['panic_days'].to_i if ENV['panic_days']
    options[:stale_days] = ENV['stale_days'].to_i if ENV['stale_days']
    options[:login] = ENV['login'] if ENV['login']
    
    Mailer.status_mails(options)
  end
end