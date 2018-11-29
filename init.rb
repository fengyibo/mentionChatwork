require 'redmine'

require_dependency 'mentionChatwork/listener'

Redmine::Plugin.register :mentionChatwork do
  name 'Mention Chatwork'
  author 'Switch'
  url 'https://github.com/munyu720/mentionChatwork'
  author_url 'https://github.com/munyu720'
  description 'A Redmine plugin.'
  version '0.1.0'

  requires_redmine :version_or_higher => '3.2.0'

  settings :default => {
      'room' => nil,
      'token' => nil,
      'post_updates' => '1',
      'post_wiki_updates' => '1'
  },
           :partial => 'settings/chatwork_settings'
end
