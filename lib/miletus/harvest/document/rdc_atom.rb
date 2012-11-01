module Miletus::Harvest::Document

  class RDCAtom < Base

    validates_attachment_content_type :document,
      :content_type => %w[application/atom+xml application/xml text/xml]

    # Produces RIF-CS document from RDC Atom feed
    #
    # Not particularly efficient, as everything is put in memory.
    def to_rif
      File.open(document.path) do |f|
        feed = Atom::Feed.load_feed(f)
        Miletus::Harvest::RDCAtom::Feed.new(feed).to_rif
      end
    end

  end

end
