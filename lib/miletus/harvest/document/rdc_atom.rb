module Miletus::Harvest::Document

  class RDCAtom < Base

    validates_attachment_content_type :document,
      :content_type => %w[application/atom+xml application/xml text/xml]

    # Produces RIF-CS document from RDC Atom feed
    #
    # Not particularly efficient, as everything is put in memory.
    def to_rif
      return nil if document.path.nil?
      File.open(document.path) do |f|
        begin
          reader = Nokogiri::XML::Reader(f)
          reader.each do |node|
            case node.name
            when 'feed'
              feed = Atom::Feed.load_feed(node.outer_xml)
              return Miletus::Harvest::RDCAtom::Feed.new(feed).to_rif
            when 'entry'
              entry = Atom::Entry.new(XML::Reader.string(node.outer_xml))
              return Miletus::Harvest::RDCAtom::Entry.new(entry).to_rif(true)
            end
          end
        rescue RuntimeError
          nil # Parser probably failed for empty document
        end
      end
    end

  end

end
