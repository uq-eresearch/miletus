module Miletus::Harvest::Atom
  module RDC

    class FeedUpdateJob < Struct.new(:feed)
      def perform
        feed.mirror
      end
    end

    def jobs
      Feed.all.map { |feed| FeedUpdateJob.new(feed) }
    end

    module_function :jobs

    require File.join(File.dirname(__FILE__),'atom_rdc','atom_entry_patch')
    require File.join(File.dirname(__FILE__),'atom_rdc','feed')
    require File.join(File.dirname(__FILE__),'atom_rdc','entry')
  end
end