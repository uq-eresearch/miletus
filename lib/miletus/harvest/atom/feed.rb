require 'atom'

module Miletus::Harvest::Atom

  module FeedMixin

    def complete?
      not self['http://purl.org/syndication/history/1.0', 'complete'].empty?
    end

    def continuing_url
      # Find previous archive link
      next_l = links.detect {|l| l.rel == 'prev-archive'}
      next_l.try(:href)
    end

  end

  class Feed < ActiveRecord::Base

    self.table_name = :harvest_atom_feeds

    attr_accessible :url

    has_many :entries,
      :class_name => 'Miletus::Harvest::Atom::Entry'

    def mirror
      re = remote_entries
      saved_entries = walk_and_mirror(re, re.complete?)
      if re.complete?
        (entries - saved_entries).each(&:destroy)
      end
    end

    def remote_entries
      RemoteEntries.new self.url
    end

    private

    def walk_and_mirror(re, read_to_end)
      stack = re.map do |entry|
        # Find existing entry
        e = entries.find_by_identifier(entry.id)
        if e.nil?
          # No matching entry, so create new
          e = entries.new()
        else
          unless read_to_end
            # Stop unless this entry was updated we don't reparse old entries
            break unless entry.updated.utc.iso8601 > e.updated.utc.iso8601
          end
        end
        # Update content
        e.xml = entry.to_xml
        # Put in queue to save (so we save in chronological order)
        e
      end
      # Reverse in place to get the effect of a stack
      stack.reverse!
      # Save entries in chronological order
      stack.map {|e| e.save!}
    end


    class RemoteEntries
      include Enumerable
      extend Forwardable

      def initialize(url)
        @feed = feed_from_url(url)
        @complete = @feed.complete?
      end

      def complete?
        @complete
      end

      def each
        until @feed.nil? do
          # Enumerate through remote entries
          @feed.entries.each {|e| yield e }
          # Find url to continue
          @feed = @feed.continuing_url.try {|url| feed_from_url(url) }
        end
      end

      private

      def feed_from_url(url)
        feed_uri = URI.parse(url)
        feed = case feed_uri.scheme
          when 'file'
            File.open(feed_uri.path) {|f| Atom::Feed.load_feed(f) }
          else
            Atom::Feed.load_feed(feed_uri)
          end
        # Mixin helper functions
        feed.extend(FeedMixin)
      end

    end

  end

end