module Navigation
  
  def navigation(data)
    buffer = "<div class='navigation'>"
    if data.has_key?(:previous_link)
      buffer += "<div class='previous-link'><a href=#{data[:previous_link]}>← #{data[:previous_title]}</a></div>"
    end
    if data.has_key?(:next_link)
      buffer += "<div class='next-link'><a href=#{data[:next_link]}>#{data[:next_title]} →</a></div>"
    end
    buffer += "</div><div class='clear-float'></div>"
    buffer
  end

end