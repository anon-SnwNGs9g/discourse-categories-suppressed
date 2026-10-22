# frozen_string_literal: true

# name: discourse-categories-suppressed
# about: Suppress topics with selected tags from the latest topics page.
# version: 0.4
# url: https://github.com/vinothkannans/discourse-categories-suppressed

after_initialize do
  preference_field = "show_suppressed_tag_topics"
  register_editable_user_custom_field preference_field
  register_user_custom_field_type(preference_field, :boolean)
  DiscoursePluginRegistry.serialized_current_user_fields << preference_field

  if TopicQuery.respond_to?(:results_filter_callbacks)
    remove_suppressed_tag_topics =
      Proc.new do |list_type, result, user, options|
        tag_names = SiteSetting.tags_suppressed_from_latest.split("|")

        if tag_names.blank? || list_type != :latest || options[:category] || options[:tags] ||
             (user && user.custom_fields[preference_field])
          result
        else
          tag_ids = Tag.where(name: tag_names).select(:id)
          suppressed_topic_ids = TopicTag.where(tag_id: tag_ids).select(:topic_id)
          filtered_result = result.where.not(id: suppressed_topic_ids)

          if user
            # Core already joins the current user's topic_users row as tu.
            filtered_result =
              filtered_result.or(
                result.where(
                  "tu.notification_level IN (?)",
                  [
                    TopicUser.notification_levels[:tracking],
                    TopicUser.notification_levels[:watching],
                  ],
                ),
              )
          end

          filtered_result
        end
      end

    TopicQuery.results_filter_callbacks << remove_suppressed_tag_topics
  end
end
