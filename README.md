# discourse-categories-suppressed

This local version suppresses topics by tag instead of category.

Configure `tags_suppressed_from_latest` in the admin site settings. Topics with **any** selected tag are excluded from the global `/latest` list by default, including for guests and staff. For logged-in users, topics whose current topic notification level is **tracking (2)** or **watching (3)** are exempt. Untagged topics and topics with only other tags remain visible. Leave the setting empty to disable filtering.

The exemption follows the stored topic level, including levels set automatically after reading or replying and levels inherited from category/tag preferences once core applies them to the topic. It does not exempt a whole category or tag just because that category or tag has a tracking preference. Regular topics and topics with no user-specific record remain suppressed. Returning a topic to regular restores suppression. Existing read-state, access, and mute filters still apply: an exempt topic that is fully read does not reappear in `/unseen` until it otherwise qualifies there.

Logged-in users can opt out under **Preferences → Interface → Latest topics** by enabling **Show topics with tags hidden by default** and saving. This account preference applies across devices and only bypasses this plugin's tag filter; the user's own mute settings and topic access permissions still apply. Unchecking it restores the default filtering. Guests always use the site default. The preference is editable by its owner and staff and is not exposed to other ordinary users.

Category and tag pages still show these topics, using the normal Discourse sorting. Topic access permissions, search, and the new, unread, and top lists are unchanged. Removing a suppressed tag makes a topic eligible for the global latest list again, provided it has no other suppressed tags.

The filter uses the same `:latest` query callback as the original plugin. Discourse also uses that callback for `/unseen` and the base query of `/filter`, so those views inherit the filtering with the same category and tag page exceptions. This plugin does not change which page is configured as the site's homepage.

The repository and plugin name remain `discourse-categories-suppressed`, but the old `categories_suppressed_from_latest` setting is replaced by `tags_suppressed_from_latest`.

The notification exemption reuses core's existing `topic_users AS tu` join. It adds a predicate to the same topic-list SQL query; it does not fetch each topic's level separately or maintain a per-user result cache. Query execution time still depends on the site's data and PostgreSQL execution plan.

## 中文说明

在管理后台搜索 `tags_suppressed_from_latest`，选择要从全站「最新」列表隐藏的标签。例如选择「灌水」后，带有该标签的话题不再出现在全站 `/latest` 中，但进入分类或标签页面仍能正常浏览。

多个标签按「命中任意一个就隐藏」处理，游客、普通用户和 staff 默认都使用此规则。清空设置即可关闭过滤。它不改变访问权限，也不修改站点首页设置。

对登录用户，话题当前通知等级为 `tracking`（2，跟踪）或 `watching`（3，关注）时自动豁免 suppress。手动设置、阅读或回复后自动进入这些等级，以及 core 已经落实到话题上的分类/标签继承等级都适用。只设置分类或标签的关注等级、尚未落实到具体话题时，不单独豁免整个分类或标签。恢复常规等级后重新隐藏。此豁免不绕过访问权限、个人静音或已读状态；已读话题不会因此重新出现在 `/unseen`。

登录用户可在「偏好设置 → 界面 → 最新话题」中勾选「显示带有默认隐藏标签的话题」并保存，仅为自己的账号关闭这层过滤，跨设备生效。用户自己设置的静音仍然有效。取消勾选恢复默认过滤，游客始终使用站点默认规则。

与原插件一样，复用 latest 查询的 `/unseen` 和 `/filter` 也会受到过滤；分类和标签页面不受影响。

豁免直接使用原列表查询已关联的 `topic_users` 通知等级，只增加 SQL 条件，不逐条查询话题，也不建立逐用户结果缓存。实际耗时仍需结合站点数据和 PostgreSQL 执行计划评估。
