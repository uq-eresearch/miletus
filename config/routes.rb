Miletus::Application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  root :to => 'page#view', :name => 'index'

  post '/recheck-sru-records' => 'record#recheck_sru'

  get '/atom' => 'record#atom', :as => :current_atom
  get '/atom/:date' => 'record#atom', :as => :atom

  match '/records.atom' => redirect('/atom')
  get '/records.gexf' => 'record#gexf'
  get '/records.sitemap' => 'record#sitemap'

  get '/graph' => 'record#graph', :as => :concept_graph

  get '/records/:id.gexf' => 'record#gexf',
    :constraints => {:id => /\d+/}, :as => :concept_gexf

  get '/records/:uuid.:format' => 'record#view_format',
    :constraints => {
      :uuid => /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/,
      :format => /[a-z0-9\.]+/
    }, :as => :concept_format
  get '/records/:uuid' => 'record#view',
    :constraints => {
      :uuid => /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
    }, :as => :concept
  get '/records/:id' => 'record#view',
    :constraints => {:id => /\d+/}, :as => :concept_id

  post '/records/:id/recheck-sru' => 'record#recheck_sru',
    :constraints => {:id => /\d+/}


  match '/oai' => 'oai#index'

  match '/browse' => 'record#index'

  match '/about' => 'page#view', :name => 'about'
  match '/contact' => 'page#view', :name => 'contact'

  match '/robots.txt' => 'seo#robots'
  match '/siteindex.xml' => 'seo#siteindex', :as => :siteindex
  match '/main.sitemap' => 'seo#sitemap'
  match '/pages.sitemap' => 'page#sitemap'
  match '/credits' => 'page#credits'
end
