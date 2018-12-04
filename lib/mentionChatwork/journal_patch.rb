require 'httpclient'

module RedmineMentions
  module JournalPatch
    def self.included(base)
      base.class_eval do
        after_create :send_mail

        def send_mail
          if self.journalized.is_a?(Issue) && self.notes.present?
            issue = self.journalized
            project=self.journalized.project
            users=project.users.to_a.delete_if{|u| (u.type != 'User' || u.mail.empty?)}
            users_regex=users.collect{|u| "#{Setting.plugin_mentionChatwork['trigger']}#{u.login}"}.join('|')
            regex_for_email = '\B('+users_regex+')\b'
            regex = Regexp.new(regex_for_email)
            mentioned_users = self.notes.scan(regex)
            mentioned_users.each do |mentioned_user|
              username = mentioned_user.first[1..-1]
              if user = User.find_by_login(username)
                MentionMailer.notify_mentioning(issue, self, user).deliver

                header = {
                  :project => escape(issue.project),
                  :title => escape(issue),
                  :url => object_url(issue),
                  :author => escape(issue.author),
                  :assigned_to => escape(issue.assigned_to.to_s),
                  :status => escape(issue.status.to_s),
                  :by => escape(journal.user.to_s)
                }

                body = escape journal.notes if journal.notes
                ChatWorkListener.speak room, header, body
              end
            end
          end
        end
      end
    end

  end
end
