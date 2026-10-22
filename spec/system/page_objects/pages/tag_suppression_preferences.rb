# frozen_string_literal: true

module PageObjects
  module Pages
    class TagSuppressionPreferences < UserPreferencesInterface
      CHECKBOX = ".pref-show-suppressed-tag-topics input[type='checkbox']"

      def set_show_suppressed_topics(value)
        find(CHECKBOX).set(value)
        self
      end

      def has_show_suppressed_topics_enabled?
        has_css?("#{CHECKBOX}:checked")
      end

      def has_show_suppressed_topics_disabled?
        has_css?("#{CHECKBOX}:not(:checked)")
      end
    end
  end
end
