module ApplicationHelper

  def absolute_link(path="")
    request.protocol + request.host_with_port + path
  end

  def body_class(controller, action)
    return "signup" if ["sessions", "registrations"].include? controller
    return "home" if ["home#index"].include?("#{controller}##{action}")
  end

  def nav_class(controller, action)
    ["home#about"].include?("#{controller}##{action}") ? "hero" : "normal"
  end


end
