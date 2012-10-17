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

  def sitemap
    extend Miletus::NamespaceHelper
    if Page.count > 0
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.urlset(:xmlns => ns_by_prefix('sitemap').uri) {
          Page.all.each do |page|
            begin
              url = url_for(
                :controller => 'page',
                :action => 'view',
                :name => page.name)
              xml.url {
                xml.loc url
                xml.lastmod page.updated_at.iso8601
              }
            rescue ActionController::RoutingError
              # Skip this one
            end
          end
        }
      end
      render :content_type => 'text/xml', :text => builder.to_xml
    else
      render :status => 404, :text => ''
    end
  end

end
