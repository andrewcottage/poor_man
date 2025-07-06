module Recipes::GenerationHelper
  def generation_status_badge(generation)
    if generation.complete?
      content_tag(:span, "Complete", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800")
    elsif generation.data.present?
      content_tag(:span, "Recipe Generated", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800")
    else
      content_tag(:span, "Processing", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800")
    end
  end

  def generation_progress_bar(generation)
    progress = 0
    progress += 33 if generation.data.present?
    progress += 33 if generation.image.attached?
    progress += 34 if generation.images.attached?

    content_tag(:div, class: "w-full bg-gray-200 rounded-full h-2.5") do
      content_tag(:div, "", class: "bg-blue-600 h-2.5 rounded-full", style: "width: #{progress}%")
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