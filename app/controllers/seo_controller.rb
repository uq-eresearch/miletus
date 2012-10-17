class SeoController < ApplicationController

  def robots
    @siteindex = url_for :controller => 'seo', :action => 'siteindex'
    render :content_type => 'text/plain', :formats => [:text]
  end

  def siteindex
    extend Miletus::NamespaceHelper
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.sitemapindex(:xmlns => ns_by_prefix('siteindex').uri) {
        xml.sitemap {
          xml.loc url_for(:controller => 'seo', :action => 'sitemap')
        }
        if Miletus::Merge::Concept.count > 0
          xml.sitemap {
            most_recent = Miletus::Merge::Concept.order('updated_at DESC').first
            xml.loc url_for(:controller => 'record', :action => 'sitemap')
            xml.lastmod most_recent.updated_at.iso8601
          }
        end
        if Page.count > 0
          xml.sitemap {
            most_recent = Page.order('updated_at DESC').first
            xml.loc url_for(:controller => 'page', :action => 'sitemap')
            xml.lastmod most_recent.updated_at.iso8601
          }
        end
      }
    end
    render :content_type => 'text/xml', :text => builder.to_xml
  end

  def sitemap
    extend Miletus::NamespaceHelper
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.urlset(:xmlns => ns_by_prefix('sitemap').uri) {
        xml.url {
          xml.loc url_for(:controller => 'record')
          xml.changefreq 'daily'
        }
      }
    end
    render :content_type => 'text/xml', :text => builder.to_xml
  end

end
