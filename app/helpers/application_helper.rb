module ApplicationHelper

  def absolute_link(path="")
    request.protocol + request.host_with_port + path
  end

  def body_class(controller, action)
    "signup" if ["sessions", "registrations"].include? controller
  end

  def nav_class(controller, action)
    ["home#about"].include?("#{controller}##{action}") ? "hero" : "normal"
  end


end
