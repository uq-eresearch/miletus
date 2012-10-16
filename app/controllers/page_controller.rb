class PageController < ApplicationController

  def view
    page = Page.find_by_name(params[:name])
    if page.nil?
      @page_name = params[:name]
      render :status => 404, :layout => true, :template => 'page/not_found'
    else
      render :status => 200, :layout => true, :text => page.to_html
    end
  end

end
