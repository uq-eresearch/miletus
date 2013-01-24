Miletus::Application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  post '/recheck-sru-records' => 'record#recheck_sru'

  get '/records.atom' => 'record#atom', :as => :atom_feed
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


  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  match '/oai' => 'oai#index'

  match '/browse' => 'record#index'

  match '/about' => 'page#view', :name => 'about'
  match '/contact' => 'page#view', :name => 'contact'

  match '/robots.txt' => 'seo#robots'
  match '/siteindex.xml' => 'seo#siteindex', :as => :siteindex
  match '/main.sitemap' => 'seo#sitemap'
  match '/pages.sitemap' => 'page#sitemap'
  match '/credits' => 'page#credits'

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'page#view', :name => 'index'

  # See how all your routes lay out with "rake routes"
end
