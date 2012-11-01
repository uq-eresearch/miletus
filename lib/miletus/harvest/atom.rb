module Miletus::Harvest::Atom

  class FeedUpdateJob < Struct.new(:feed)
    def perform
      feed.mirror
    end

    def to_s
      feed.url
    end
  end

  def jobs
    Feed.all.map { |feed| FeedUpdateJob.new(feed) }
  end

  module_function :jobs

  require File.join(File.dirname(__FILE__),'atom','document_link')
  require File.join(File.dirname(__FILE__),'atom','entry')
  require File.join(File.dirname(__FILE__),'atom','feed')
end