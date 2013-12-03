Archives::Application.routes.draw do
    
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
    
  # *** Note from Trevor: Avoiding use of 'match' because it will be depricated in Rails 4
  # *** Defining 'get' and 'post' for most routes to support passing URL params later


  #access terms 
  get 'terms' => 'terms#index'
  get 'terms/request_terms' => 'terms#request_terms'
  get 'terms/request_entity' => 'terms#request_entity'
  


  # THESE ARE TEMPORARY - NEED TO ADD MORE ROBUST ALIASING FOR COLLECTIONS
  get "tilden" => 'collections#show', :defaults => { :id => 2 }
  get "emmet" => 'collections#show', :defaults => { :id => 1 }
  
  get "org_units/index"

  get "contacts/index"

  get "general/home"

  get "collections/index"

  get "collections/view"

  get "collections/container_list"

  get "searches/index"
  get "searches/results"
  post "searches/results"
  
  get "searches/controlaccess"
  
  get "contacts/compose", :as => :contact
  post "contacts/deliver"
  
  # search
  get 'search' => 'searches#index'
  get 'search/results' => 'searches#results', :as => :search_results
  post 'search/results' => 'searches#results', :as => :search_results
  
    
  get ':org_unit_code' => 'searches#results', :defaults => { :prefilter => 'org_unit_code' },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }, :as => :org_unit_results
  post ':org_unit_code' => 'searches#results', :defaults => { :prefilter => 'org_unit_code' },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }, :as => :org_unit_results
  get ':org_unit_code/request_access' => 'contacts#compose', :defaults => { :layout => true, :mode => 'request' }
  
  
  get 'controlaccess/:access_term_id' =>'searches#results', :defaults => { :prefilter => 'access_term_id' }, :as => :controlaccess_results
  post 'controlaccess/:access_term_id' =>'searches#results', :defaults => { :prefilter => 'access_term_id' }, :as => :controlaccess_results
  
  get 'search/collection/:collection_id' => 'searches#collection', :as => :collection_results
  post 'search/collection/:collection_id' =>'searches#collection', :as => :collection_results
  
  # collections browse
  get 'collections' => 'collections#index'
  post 'collections' => 'collections#index'
  
  # individual collections
  get 'collection/:id(.:format)' => 'collections#show'
  post 'collection/:id(.:format)' => 'collections#show'

  get 'collection/:id/raw' => 'collections#show', :defaults => { :format => 'json' }
  get 'collection/:id/ead' => 'collections#show', :defaults => { :format => 'xml' }
  get 'collection/:id/pdf' => 'collections#show', :defaults => { :format => 'pdf' }
  get 'collection/:id/newpdf' => 'collections#show', :defaults => { :format => 'newpdf' }
  
  # preferred routes using MSS IDs - org_unit_code is not significant
  get ':org_unit_code/:identifier_value(.:format)' => 'collections#show', :defaults => { :find_by_identifier => true },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }

  post ':org_unit_code/:identifier_value(.:format)' => 'collections#show', :defaults => { :find_by_identifier => true },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }
  
  
  # preferred route + PDF 
  get ':org_unit_code/:identifier_value/pdf' => 'collections#show', :defaults => { :find_by_identifier => true, :format => 'pdf' },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }
  get ':org_unit_code/:identifier_value/newpdf' => 'collections#show', :defaults => { :find_by_identifier => true, :format => 'newpdf' },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }  
  # preferred route + EAD
  get ':org_unit_code/:identifier_value/ead' => 'collections#show', :defaults => { :find_by_identifier => true, :format => 'xml' },
    :constraints => { :org_unit_code => /[A-Za-z]{2,5}/ }
    
      
  get 'collection/:id/container_list' => 'collections#container_list'
  post 'collection/:id/container_list' => 'collections#container_list'
  get 'collection/:id/container_list/:page' => 'collections#container_list_page'  
  get 'repositories' => 'org_units#index'

   
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'general#home'
  get '*path' => 'general#redirect'
  post '*path' => 'general#redirect'





  
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



  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
