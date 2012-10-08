require 'atom'

module Miletus::Harvest::Atom::RDC

  class Feed < ActiveRecord::Base

    self.table_name = :harvest_atom_rdc_feeds

    attr_accessible :url

    has_many :entries,
      :class_name => 'Miletus::Harvest::Atom::RDC::Entry'

    def mirror
      remote_entries.each do |entry|
        e = entries.find_by_atom_id(entry.id)
        e ||= entries.new()
        e.xml = entry.to_xml
        e.save!
      end
    end

    def remote_entries
      Enumerator.new do |y|
        feed_url = self.url
        loop do
          # Fetch feed
          feed_uri = URI.parse(feed_url)
          feed = case feed_uri.scheme
            when 'file'
              File.open(feed_uri.path) {|f| Atom::Feed.load_feed(f) }
            else
              Atom::Feed.load_feed(feed_uri)
            end
          # Enumerate through remote entries
          feed.entries.each {|e| y << e}
          # Find next link
          next_l = feed.links.detect {|l| %w[next next-archive].include?(l.rel)}
          raise StopIteration if next_l.nil?
          feed_url = next_l.href
        end
      end
    end

  end

end