module ChatHelper
  def render_markdown(text)
    return "" if text.blank?

    html = ERB::Util.html_escape(text)

    # Images ![alt](url)
    html = html.gsub(/!\[([^\]]*)\]\(([^)]+)\)/, '<img src="\2" alt="\1" loading="lazy" class="chat-preview-image" />')

    # Bold
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')

    # Italic
    html = html.gsub(/\*(.+?)\*/, '<em>\1</em>')

    # Links [text](url)
    html = html.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')

    html = wrap_markdown_lists(html)

    # Paragraphs from double newlines
    html = html.split(/\n{2,}/).map { |para|
      para = para.strip
      next if para.blank?
      if para.start_with?("<ul>") || para.start_with?("<ol>")
        para
      else
        "<p>#{para}</p>"
      end
    }.compact.join("\n")

    # Single newlines to <br>
    html = html.gsub(/(?<!\n)\n(?!\n)/, "<br>")

    html.html_safe
  end

  def conversation_timestamp_label(conversation)
    date = conversation.updated_at.in_time_zone.to_date

    if date == Time.zone.today
      "Today"
    elsif date == Time.zone.yesterday
      "Yesterday"
    else
      I18n.l(date, format: :short)
    end
  end

  private

  def wrap_markdown_lists(html)
    output = []
    list_items = []
    list_type = nil

    html.each_line(chomp: true) do |line|
      stripped = line.strip

      unordered_match = stripped.match(/\A-\s+(.+)\z/)
      ordered_match = stripped.match(/\A\d+\.\s+(.+)\z/)

      current_type = if unordered_match
        :ul
      elsif ordered_match
        :ol
      end

      if current_type
        if list_type.present? && list_type != current_type
          output << "<#{list_type}>#{list_items.join}</#{list_type}>"
          list_items = []
        end

        list_type = current_type
        list_items << "<li>#{(unordered_match || ordered_match)[1]}</li>"
      else
        if list_type.present?
          output << "<#{list_type}>#{list_items.join}</#{list_type}>"
          list_items = []
          list_type = nil
        end

        output << line
      end
    end

    output << "<#{list_type}>#{list_items.join}</#{list_type}>" if list_type.present?
    output.join("\n")
  end
end
