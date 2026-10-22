# frozen_string_literal: true

RSpec.describe TopicQuery do
  fab!(:user)
  fab!(:admin)
  fab!(:category)
  fab!(:suppressed_tag, :tag)
  fab!(:normal_tag, :tag)
  fab!(:untagged_topic) { Fabricate(:topic, category: category) }
  fab!(:normal_topic) { Fabricate(:topic, category: category, tags: [normal_tag]) }
  fab!(:suppressed_topic) { Fabricate(:topic, category: category, tags: [suppressed_tag]) }
  fab!(:mixed_topic) { Fabricate(:topic, category: category, tags: [suppressed_tag, normal_tag]) }

  before do
    enable_current_plugin
    SiteSetting.tagging_enabled = true
    SiteSetting.tags_suppressed_from_latest = suppressed_tag.name
  end

  it "hides tagged topics from latest for guests and users" do
    expect(TopicQuery.new.list_latest.topics).to contain_exactly(untagged_topic, normal_topic)
    expect(TopicQuery.new(user).list_latest.topics).to contain_exactly(untagged_topic, normal_topic)
    expect(TopicQuery.new(admin).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
    )
  end

  it "hides topics matching any configured tag" do
    SiteSetting.tags_suppressed_from_latest = "#{suppressed_tag.name}|#{normal_tag.name}"

    expect(TopicQuery.new.list_latest.topics).to contain_exactly(untagged_topic)
  end

  it "keeps tracked and watched topics in latest and unseen" do
    user.update!(first_seen_at: 1.day.ago)
    TopicUser.change(
      user.id,
      suppressed_topic.id,
      notification_level: TopicUser.notification_levels[:tracking],
    )
    TopicUser.change(
      user.id,
      mixed_topic.id,
      notification_level: TopicUser.notification_levels[:watching],
    )

    expect(TopicQuery.new(user).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
      suppressed_topic,
      mixed_topic,
    )
    expect(TopicQuery.new(user).list_unseen.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
      suppressed_topic,
      mixed_topic,
    )
    expect(TopicQuery.new(admin).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
    )
    expect(TopicQuery.new.list_latest.topics).to contain_exactly(untagged_topic, normal_topic)
  end

  it "suppresses a topic again after returning to regular" do
    TopicUser.change(
      user.id,
      suppressed_topic.id,
      notification_level: TopicUser.notification_levels[:watching],
    )
    expect(TopicQuery.new(user).list_latest.topics).to include(suppressed_topic)

    TopicUser.change(
      user.id,
      suppressed_topic.id,
      notification_level: TopicUser.notification_levels[:regular],
    )

    expect(TopicQuery.new(user).list_latest.topics).to contain_exactly(untagged_topic, normal_topic)
  end

  it "keeps read tracked topics out of unseen" do
    user.update!(first_seen_at: 1.day.ago)
    TopicUser.change(
      user.id,
      suppressed_topic.id,
      notification_level: TopicUser.notification_levels[:tracking],
      last_read_post_number: suppressed_topic.highest_post_number,
    )

    expect(TopicQuery.new(user).list_latest.topics).to include(suppressed_topic)
    expect(TopicQuery.new(user).list_unseen.topics).to contain_exactly(untagged_topic, normal_topic)
  end

  it "keeps personal tag mutes for watched topics" do
    SiteSetting.remove_muted_tags_from_latest = "always"
    user.user_option.update!(watched_precedence_over_muted: false)
    TopicUser.change(
      user.id,
      suppressed_topic.id,
      notification_level: TopicUser.notification_levels[:watching],
    )
    TagUser.change(user.id, suppressed_tag.id, TagUser.notification_levels[:muted])

    expect(TopicQuery.new(user).list_latest.topics).to contain_exactly(untagged_topic, normal_topic)
  end

  it "lets a user show suppressed topics on their timeline" do
    user.custom_fields["show_suppressed_tag_topics"] = true
    user.save_custom_fields

    expect(TopicQuery.new(user.reload).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
      suppressed_topic,
      mixed_topic,
    )
    expect(TopicQuery.new.list_latest.topics).to contain_exactly(untagged_topic, normal_topic)
    expect(TopicQuery.new(admin).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
    )
  end

  it "restores filtering when the preference is unchecked" do
    user.custom_fields["show_suppressed_tag_topics"] = true
    user.save_custom_fields
    user.custom_fields["show_suppressed_tag_topics"] = false
    user.save_custom_fields

    expect(TopicQuery.new(user.reload).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
    )
  end

  it "keeps the user's own tag mutes when opting out" do
    SiteSetting.remove_muted_tags_from_latest = "always"
    user.custom_fields["show_suppressed_tag_topics"] = true
    user.save_custom_fields
    TagUser.change(user.id, suppressed_tag.id, TagUser.notification_levels[:muted])

    expect(TopicQuery.new(user.reload).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
    )
  end

  it "shows all topics when the setting is empty" do
    SiteSetting.tags_suppressed_from_latest = ""

    expect(TopicQuery.new.list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
      suppressed_topic,
      mixed_topic,
    )
  end

  it "keeps suppressed topics on their category page" do
    expect(TopicQuery.new(nil, category: category.id).list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
      suppressed_topic,
      mixed_topic,
    )
  end

  it "keeps suppressed topics on tag pages" do
    expect(TopicQuery.new(nil, tags: [suppressed_tag.name]).list_latest.topics).to contain_exactly(
      suppressed_topic,
      mixed_topic,
    )
    expect(TopicQuery.new(nil, tags: [normal_tag.name]).list_latest.topics).to contain_exactly(
      normal_topic,
      mixed_topic,
    )
  end

  it "shows a topic again after its suppressed tag is removed" do
    mixed_topic.tags.delete(suppressed_tag)

    expect(TopicQuery.new.list_latest.topics).to contain_exactly(
      untagged_topic,
      normal_topic,
      mixed_topic,
    )
  end
end
