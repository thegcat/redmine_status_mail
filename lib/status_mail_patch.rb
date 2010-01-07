module Plugin
  module StatusMail
    module Mailer
      module ClassMethods
        def self.status_mails(options={})
          stale_days = options[:stale_days] || 7
          panic_days = options[:panic_days] || 7
          stale_date = stale_days.days.ago.to_date
          panic_date = panic_days.days.from_now.to_date

          # filter out tickets
          # only open tickets
          s = ARCondition.new Issue.open.proxy_options[:conditions]
          # only assigned tickets
          s << "#{Issue.table_name}.assigned_to_id IS NOT NULL"
          # only from active projects
          s << ["#{Project.table_name}.status = ?", Project::STATUS_ACTIVE]
          # only those that have already begun
          s << ["#{Issue.table_name}.start_date <= ?", Date.today]
          # TODO: Rescue from invalid or non-existent login
          s << ["#{Issue.table_name}.assigned_to_id = ?", User.find_by_login(options[:login]).id] if options[:login]

          stale_cond = ARCondition.new s.conditions
          panic_cond = s

          # tickets ending soon
          panic_cond << ["#{Issue.table_name}.due_date <= ?", panic_date]
          # tickets started at least stale_days ago and last updated at leaste stale_days ago
          stale_cond << ["#{Issue.table_name}.start_date <= ?", stale_date]
          stale_cond << ["#{Issue.table_name}.updated_on <= ?", stale_date]

          panic_issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
          :conditions => panic_cond.conditions,
          :order => "due_date ASC"
          ).group_by(&:assigned_to)
          stale_issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
          :conditions => stale_cond.conditions,
          :order => "due_date ASC"
          ).group_by(&:assigned_to)

          (panic_issues_by_assignee.keys | stale_issues_by_assignee.keys).each do |assignee|
            deliver_status_mail(assignee, panic_issues_by_assignee[assignee], panic_days, stale_issues_by_assignee[assignee], stale_days) unless assignee.nil?
          end                  
        end
      end

      module InstanceMethods
        def status_mails(user, panic_issues, panic_days, stale_issues, stale_days)
          set_language_if_valid user.language
          recipients user.mail
          s = case 
          when panic_issues.blank? then l(:mail_subject_status_mail_stale, stale_issues.size)
          when stale_issues.blank? then l(:mail_subject_status_mail_panic, panic_issues.size)
          else l(:mail_subject_status_mail_full, panic_issues.size, stale_issues.size)
          end
          subject s
          body :panic_issues => panic_issues, :panic_days => panic_days, :stale_issues => stale_issues, :stale_days => stale_days
          render_multipart('status_mail', body)
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end