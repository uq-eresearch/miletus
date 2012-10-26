module Miletus::Harvest::Document

  class RIFCS < Base

    validates_attachment_content_type :document,
      :content_type => %w[application/xml text/xml]

    def to_rif_file(&block)
      document.file? ? File.open(document.path, &block) : nil
    end

    def to_rif
      to_rif_file do |f|
        f.read
      end
    end

  end

end
