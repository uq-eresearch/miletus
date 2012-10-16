ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Statistics" do
          div do
            stats = {
              'OAI-PMH input records' => \
                Miletus::Harvest::OAIPMH::RIFCS::Record.all.count,
              'OAI-PMH endpoints' => \
                Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.all.count,
              'SRU interfaces' => Miletus::Harvest::SRU::Interface.all.count,
              'concepts' => Miletus::Merge::Concept.all.count,
              'facets' => Miletus::Merge::Facet.all.count,
              'OAI-PMH output records' =>
                Miletus::Output::OAIPMH::Record.all.count,
            }
            render('/admin/stats', :stats => stats)
          end
        end
      end
    end # columns
  end # content
end
