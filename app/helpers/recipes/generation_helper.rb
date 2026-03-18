module Recipes::GenerationHelper
  def generation_allowance_summary(user)
    if user.free?
      if user.can_generate_recipe?
        summary = "You still have your 1 free AI recipe generation trial."
      else
        summary = "Your 1 free AI recipe generation trial has been used."
      end
    else
      summary = "#{user.included_recipe_generations_remaining} of #{Billing::PlanCatalog::PRO_MONTHLY_GENERATION_LIMIT} #{Billing::PlanCatalog::PRO_DISPLAY_NAME} generations remaining, #{user.generation_window_label}."
    end

    return summary if user.remaining_generation_credits.zero?

    "#{summary} #{user.remaining_generation_credits} extra credit #{'generation'.pluralize(user.remaining_generation_credits)} available."
  end

  def generation_status_badge(generation)
    if generation.complete?
      content_tag(:span, "Complete", class: "inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800")
    elsif generation.data.present?
      content_tag(:span, "Recipe Generated", class: "inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800")
    else
      content_tag(:span, "Processing", class: "inline-flex items-center rounded-full bg-slate-200 px-2.5 py-0.5 text-xs font-medium text-slate-800")
    end
  end

  def generation_progress_bar(generation)
    progress = 0
    progress += 33 if generation.data.present?
    progress += 33 if generation.image.attached?
    progress += 34 if generation.images.attached?

    content_tag(:div, class: "h-2.5 w-full rounded-full bg-stone-200") do
      content_tag(:div, "", class: "h-2.5 rounded-full bg-emerald-500", style: "width: #{progress}%")
    end
  end

  def formatted_generation_data(generation)
    return "No data generated yet" unless generation.data.present?

    data = generation.data
    content_tag(:div, class: "space-y-4") do
      if data['title'].present?
        concat(content_tag(:h3, data['title'], class: "text-lg font-semibold"))
      end
      
      if data['blurb'].present?
        concat(content_tag(:p, data['blurb'], class: "text-gray-600"))
      end
      
      if data['category'].present?
        concat(content_tag(:p, "Category: #{data['category']}", class: "text-sm text-gray-500"))
      end
      
      if data['tags'].present? && data['tags'].is_a?(Array)
        concat(content_tag(:div, class: "flex flex-wrap gap-2") do
          data['tags'].map do |tag|
            content_tag(:span, tag, class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800")
          end.join.html_safe
        end)
      end
    end
  end
end 
