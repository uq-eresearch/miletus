module ApplicationHelper

  def site_name
    ENV["SITE_NAME"] || "Miletus"
  end

end