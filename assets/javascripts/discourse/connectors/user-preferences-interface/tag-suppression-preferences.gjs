import PreferenceCheckbox from "discourse/components/preference-checkbox";
import { i18n } from "discourse-i18n";

export default <template>
  <fieldset class="control-group pref-show-suppressed-tag-topics">
    <legend class="control-label">{{i18n
        "tag_suppression.preferences.title"
      }}</legend>
    <PreferenceCheckbox
      @labelKey="tag_suppression.preferences.show_topics"
      @checked={{@outletArgs.model.custom_fields.show_suppressed_tag_topics}}
      data-setting-name="show-suppressed-tag-topics"
    />
    <div class="instructions">{{i18n
        "tag_suppression.preferences.instructions"
      }}</div>
  </fieldset>
</template>
