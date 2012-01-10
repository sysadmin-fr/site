module Navigation
  def start_navigation
    "<div class='navigation'>"
  end
  
  def stop_navigation
    "<div class='clear-float'></div></div>"
  end
  
  def previous_section(title, link)
    "<div class='previous-link'><a href=#{link}>← #{title}</a></div>"
  end

  def next_section(title, link)
    "<div class='next-link'><a href=#{link}>#{title} →</a></div>"
  end
end