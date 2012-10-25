module Miletus::Harvest::Document

  class RIFCS < Base

    validates_attachment_content_type :document,
      :content_type => 'application/xml'

    def to_io(&block)
      document.file? ? File.open(document.path, &block) : nil
    end

    def to_rif
      to_io do |f|
        f.read
      end
    end

  end

end
