module PagyHelper
  include Pagy::Frontend

  def pagy_nav_custom(pagy)
    previous_link = if pagy.prev
                      link_to('Previous', pagy_url_for(pagy, pagy.prev),
                              class: 'relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-offset-0')
                    else
                      content_tag(:span, 'Previous',
                                  class: 'relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-400 ring-1 ring-inset ring-gray-300 cursor-not-allowed')
                    end

    next_link = if pagy.next
                  link_to('Next', pagy_url_for(pagy, pagy.next),
                          class: 'relative ml-3 inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-offset-0')
                else
                  content_tag(:span, 'Next',
                              class: 'relative ml-3 inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-400 ring-1 ring-inset ring-gray-300 cursor-not-allowed')
                end

    content_tag(:nav, class: 'flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6', aria: { label: 'Pagination' }) do
      concat(content_tag(:div, class: 'hidden sm:block') do
        content_tag(:p, class: 'text-sm text-gray-700') do
          "Showing ".html_safe +
          content_tag(:span, pagy.from, class: 'font-medium') +
          " to ".html_safe +
          content_tag(:span, pagy.to, class: 'font-medium') +
          " of ".html_safe +
          content_tag(:span, pagy.count, class: 'font-medium') +
          " results".html_safe
        end
      end)
      concat(content_tag(:div, class: 'flex flex-1 justify-between sm:justify-end') do
        previous_link + next_link
      end)
    end
  end
end
