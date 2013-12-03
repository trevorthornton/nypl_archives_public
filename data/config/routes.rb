Archives::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  get 'users/:id/edit/' => 'users#edit'
  post 'users/:id/update' => 'users#update'
  put 'users/:id/update' => 'users#update'
  get 'users/new' => 'users#new'
  post 'users/create' => 'users#create'
  get 'users' => 'users#index'
  
  devise_for :users
  
  # Resource routes (maps HTTP verbs to controller actions automatically):
  resources :collections, :org_units, :components, :documents, :external_resources

  
  get 'collections/ingest/remove_tmp_ead' => 'collections#remove_tmp_ead'
  get 'collections/ingest/collection_exists' => 'collections#collection_exists'
  get 'collections/ingest/ingest_ead_from_interface' => 'collections#ingest_ead_from_interface'
  get 'collections/ingest/ingest_bnumber_from_interface' => 'collections#ingest_bnumber_from_interface'
  get 'collections/ingest/status' => 'collections#ingest_status'
  
 
  get 'collections/:id/components' => 'collections#components'
  get 'collections/:id/attach_file' => 'collections#attach_file'

  get 'collections/:id/:format' => 'collections#show'

  get 'components/:id/add_uuid' => 'components#add_uuid'
  
  get 'components/:id/:format' => 'components#show'
  
  
  get "access_terms/index"

  get "access_terms/show"

  get "authoritydata_searches/show"

  get "authoritydata_searches/results"

  get "collection_associations/create"

  get "collection_associations/delete"

  get "collection_associations/destroy"
  
  get ':org_unit_code/:identifier_value(/:format)' => 'collections#show', :defaults => { :find_by_identifier => true },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }
  get 'collection/:id(/:format)' => 'collections#show'
  
  get 'collection_associations/:describable_id/edit' => 'collection_associations#edit'
  get 'collection_associations/:describable_id/update' => 'collection_associations#update'
  get 'collection_associations/:describable_id/destroy' => 'collection_associations#destroy'
  


  get 'search_indices/update/:type' => 'search_indices#update'

  # search
  match 'search' => 'searches#index'
  match 'search/results' => 'searches#results'

  


  
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'collections#index'
  
  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  
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

  # See how all your routes lay out with "rake routes"

end
