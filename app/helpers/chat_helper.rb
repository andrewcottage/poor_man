module ChatHelper
  def render_markdown(text)
    return "" if text.blank?

    html = ERB::Util.html_escape(text)

    # Bold
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')

    # Italic
    html = html.gsub(/\*(.+?)\*/, '<em>\1</em>')

    # Links [text](url)
    html = html.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')

    # Unordered lists
    html = html.gsub(/^- (.+)$/) { "<li>#{$1}</li>" }
    html = html.gsub(%r{(<li>.*</li>\n?)+}) { |match| "<ul>#{match}</ul>" }

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
end
