namespace :uuid_keys do
  desc "Dump key => uuid JSON map"
  task :dump => :environment do |t|
    require 'miletus'
    h = Miletus::Merge::Concept.all.each_with_object({}) do |concept, memo|
      concept.facets.pluck(:key).each do |key|
        memo[key] = concept.uuid
      end
    end
    puts JSON.pretty_generate(h)
  end

  desc "Load key => uuid JSON map to create placeholder facets"
  task :load => :environment do |t|
    require 'miletus'
    h = JSON.parse($stdin.read)
    h.each do |facet_key, uuid|
      # Concept & facet creation should be atomic
      Miletus::Merge::Concept.transaction do
        # Create concept with UUID
        concept = Miletus::Merge::Concept.find_or_create_by_uuid(uuid)
        # Create empty placeholder facet for this concept
        unless Miletus::Merge::Facet.find_by_key(facet_key)
          facet = concept.facets.new
          facet.key = facet_key
          facet.save!
          $stderr.puts "Creating facet #{facet_key} for concept #{uuid}"
        end
      end
    end
  end

end