Miletus::Application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  post '/recheck-sru-records' => 'record#recheck_sru'

  get '/records/:id.gexf' => 'record#gexf',
    :constraints => {:id => /\d+/}, :as => :concept_gexf
  get '/records/:id' => 'record#view',
    :constraints => {:id => /\d+/}, :as => :concept

  post '/records/:id/recheck-sru' => 'record#recheck_sru',
    :constraints => {:id => /\d+/}

  get '/records.gexf' => 'record#gexf'
  get '/records.sitemap' => 'record#sitemap'
  get '/graph' => 'record#graph', :as => :concept_graph
  get '/stats' => 'record#stats'

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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'page#view', :name => 'index'

  # See how all your routes lay out with "rake routes"
end
