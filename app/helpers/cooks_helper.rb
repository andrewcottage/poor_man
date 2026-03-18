module CooksHelper
  def contributor_badge(user)
    content_tag(
      :span,
      user.contributor_badge,
      class: "inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-200"
    )
  end

  def community_activity_summary(activity)
    case activity.type
    when :recipe
      "#{activity.user.username} published #{activity.recipe.title}"
    when :review
      "#{activity.user.username} reviewed #{activity.recipe.title}"
    end
  end
end
