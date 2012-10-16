class PageController < ApplicationController

  def view
    page = Page.find_by_name(params[:name])
    if page.nil?
      @name = params[:name]
      render :status => 404, :layout => true, :template => 'page/not_found'
    else
      @html = page.to_html.html_safe
      render :status => 200, :layout => true
    end
  end

end
