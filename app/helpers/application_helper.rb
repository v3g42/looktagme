module ApplicationHelper

  def absolute_link(path="")
    request.protocol + request.host_with_port + path
  end


end
