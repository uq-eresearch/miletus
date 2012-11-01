require 'open-uri'
require 'uri'

module Miletus::Harvest::Document

  class Base < ActiveRecord::Base

    self.table_name = 'harvest_documents'

    attr_accessible :url

    has_attached_file :document
    has_many :facet_links, :as => :harvest_record,
      :class_name => 'Miletus::Harvest::FacetLink'

    validates :url, :presence => true
    validates_format_of :url, :with => URI::regexp(%w(http https file))
    validates_uniqueness_of :url

    def deleted?
      not document.present?
    end

    def fetch
      begin
        open(remote_file_location, fetch_options) do |f|
          tempfile = Tempfile.new('fetched-document-')
          begin
            IO.copy_stream(f, tempfile)
            tempfile.close
            tempfile.open
            self.document = tempfile
          ensure
            tempfile.unlink
          end
          # Record headers for conditional request next time
          if f.respond_to?(:meta)
            self.etag = f.meta['etag']
            self.last_modified = f.meta['last-modified']
          end
        end
        document.flush_writes
        save!
      rescue OpenURI::HTTPError => e
        if e.message =~ /^4/ # 4xx code
          document.clear
        end
        # Ignore 3xx and 5xx codes
      end
    end

    def url=(url)
      self[:url] = url
      # As the URL has changed, clear any existing document
      document.clear
    end

    private

    def fetch_options
      opts = {}
      opts[:read_timeout] = 600 # Handle very large documents
      opts['If-None-Match'] = self.etag if self.etag
      opts['If-Modified-Since'] = self.last_modified if self.last_modified
      opts
    end

    def remote_file_location
      self.url.gsub(%r{^file://},'')
    end

  end

end
