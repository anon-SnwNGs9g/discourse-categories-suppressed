# frozen_string_literal: true

RSpec.describe "Tag suppression preferences" do
  fab!(:user)
  fab!(:suppressed_tag, :tag)
  fab!(:suppressed_post) { Fabricate(:post) }
  fab!(:normal_post) { Fabricate(:post) }

  let(:preferences) { PageObjects::Pages::TagSuppressionPreferences.new }
  let(:topic_list) { PageObjects::Components::TopicList.new }

  before do
    enable_current_plugin
    SiteSetting.tagging_enabled = true
    SiteSetting.tags_suppressed_from_latest = suppressed_tag.name
    suppressed_post.topic.update!(tags: [suppressed_tag])
    sign_in(user)
  end

  it "lets a user choose whether to show suppressed topics" do
    visit("/latest")
    expect(topic_list).to have_topic(normal_post.topic)
    expect(topic_list).to have_no_topic(suppressed_post.topic)

    preferences.visit(user)
    expect(preferences).to have_show_suppressed_topics_disabled
    preferences.set_show_suppressed_topics(true)
    preferences.save_changes

    page.refresh
    expect(preferences).to have_show_suppressed_topics_enabled

    visit("/latest")
    expect(topic_list).to have_topic(suppressed_post.topic)

    preferences.visit(user)
    preferences.set_show_suppressed_topics(false)
    preferences.save_changes

    visit("/latest")
    expect(topic_list).to have_topic(normal_post.topic)
    expect(topic_list).to have_no_topic(suppressed_post.topic)
  end
end
