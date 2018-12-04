require 'httpclient'

module RedmineMentions
  module JournalPatch
    def self.included(base)
      base.class_eval do
        after_create :send_chatwork

        def send_chatwork
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
                # メール送信機能は無効
                # MentionMailer.notify_mentioning(issue, self, user).deliver

                cf = UserCustomField.find_by_name("UserChatWorkRoom")
                val = user.custom_value_for(cf).value rescue nil

                if val != nil
                  rid = val.match(/#!rid\d+/)
                  room = rid[0][5..val.length]
                  header = {
                    :project => escape(issue.project),
                    :title => escape(issue),
                    :url => object_url(issue),
                    :author => escape(issue.author),
                    :assigned_to => escape(issue.assigned_to.to_s),
                    :status => escape(issue.status.to_s),
                    :by => escape(username.to_s)
                  }
                  body = escape issue.notes if issue.notes
                  speak room, header, body
                  end
              end
            end
          end
        end
      end
    end

    def speak(room, header, body=nil, footer=nil)
      url = 'https://api.chatwork.com/v2/rooms/'
      token = Setting.plugin_mentionChatwork["token"]
      content = create_body body, header, footer
      reqHeader = {'X-ChatWorkToken' => token}
      endpoint = "#{url}#{room}/messages"

      begin
        client = HTTPClient.new
        client.ssl_config.cert_store.set_default_paths
        client.ssl_config.ssl_version = :auto
        client.post_async(endpoint, "body=#{content}", reqHeader)

      rescue Exception => e
        Rails.logger.info("cannot connect to #{endpoint}")
        Rails.logger.info(e)
      end
    end

    def create_body(body=nil, header=nil, footer=nil)
      result = '[info]'

      if header
        result +=
            "[title]#{'['+header[:status]+']' if header[:status]} #{header[:title] if header[:title]} / #{header[:project] if header[:project]}\n
            #{header[:url] if header[:url]}\n
            #{'送信者: '+header[:by] if header[:by]}#{', 担当者: '+header[:assigned_to] if header[:assigned_to]}#{', 責任者: '+header[:author] if header[:author]}[/title]"
      end

      if body
        result += body
      end

      if footer
        result += "\n" + footer
      end

      result += '[/info]'

      CGI.escape result
    end

    private
    def escape(msg)
      msg.to_s
    end

    def object_url(obj)
      if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
        host, port, prefix = $2, $4, $5
        Rails.application.routes.url_for(obj.event_url({
             :host => host,
             :protocol => Setting.protocol,
             :port => port,
             :script_name => prefix
         }))
      else
        Rails.application.routes.url_for(obj.event_url({
             :host => Setting.host_name,
             :protocol => Setting.protocol
         }))
      end
    end
  end
end
