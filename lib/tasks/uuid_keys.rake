namespace :uuid_keys do
  desc "Dump key => uuid JSON map"
  task :dump => :environment do |t|
    require 'miletus'
    h = Miletus::Merge::Concept.all.each_with_object({}) do |concept, memo|
      concept.facets.pluck(:key).each do |key|
        memo[key] = concept.uuid
      end
    end
    puts JSON.dump(h)
  end
end