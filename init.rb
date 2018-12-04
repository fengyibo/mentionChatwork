require 'redmine'

Rails.configuration.to_prepare do
    require_dependency 'mentionChatwork/listener'
    require_dependency 'mentionChatwork/hooks'
    require_dependency 'mentionChatwork/journal_patch'
    require_dependency 'journal'
    Journal.send(:include, RedmineMentions::JournalPatch)
end

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
      'post_wiki_updates' => '1',
      'trigger' => '@',
  }, :partial => 'settings/chatwork_settings'
end
