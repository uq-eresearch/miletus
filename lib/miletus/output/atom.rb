module Miletus::Output::Atom

  def feed(date, url_options)
    DateFeed.new(date, url_options).as_feed
  end

  module_function(:feed)

  private

  class DateFeed
    extend Forwardable

    def_delegators :@url_helpers,
      :current_atom_url, :atom_url, :concept_id_url, :concept_format_url

    attr_reader :date

    def initialize(date, url_options)
      @date = date
      @url_options = url_options
      @url_helpers = Rails.application.routes.url_helpers
    end

    def as_feed
      make_feed do |feed|
        feed.id = current_atom_url(@url_options)
        # Create archive links
        d = next_archive_date and feed.links << Atom::Link.new({
          :rel => 'next-archive',
          :href => atom_url(d, @url_options)
        })
        d = previous_archive_date and feed.links << Atom::Link.new({
          :rel => 'prev-archive',
          :href => atom_url(d, @url_options)
        })
        # Add entries
        feed.entries = concept_entries
      end
    end

    private

    def present_date
      DateTime.now.utc.to_date
    end

    def last_updated
      Miletus::Merge::Concept.updated_at || DateTime.now
    end

    def concept_entries
      concepts = Miletus::Merge::Concept.updated_on(date).from_most_recent
      concepts.map do |concept|
        make_entry(concept) do |entry|
          if concept.uuid
            entry.links << Atom::Link.new({
              :rel => 'alternate',
              :type => 'application/rifcs+xml',
              :href => concept_format_url({
                :uuid => concept.uuid,
                :format => 'rifcs.xml'
              }.merge(@url_options))
            })
          end
        end
      end
    end

    def next_archive_date
      next_date = Miletus::Merge::Concept.updated_after(date)
        .from_most_recent
        .last
        .try(:updated_at).try(:to_date)
      next_date || (date < present_date ? present_date : nil)
    end

    def previous_archive_date
      Miletus::Merge::Concept.updated_before(date)
        .from_most_recent
        .first
        .try(:updated_at).try(:to_date)
    end

    def make_feed
      Atom::Feed.new do |feed|
        feed.updated = last_updated
        feed.title = 'Miletus Atom Feed'
        feed.generator = generator
        yield feed if block_given?
      end
    end

    def generator
      Atom::Generator.new(
        :name => 'Miletus',
        :uri => 'https://github.com/uq-eresearch/miletus')
    end

    def make_entry(concept)
      Atom::Entry.new do |entry|
        entry.id = concept_id_url(concept.id, @url_options)
        entry.updated = concept.updated_at
        entry.title = concept.title
        yield entry if block_given?
      end
    end

  end



end