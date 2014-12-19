# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md



Isk::Application.routes.draw do
	# The priority is based upon order of creation:
	# first created -> highest priority.

	# Sample resource route (maps HTTP verbs to controller actions automatically):
	#		resources :products

	# Sample resource route with options:
	#		resources :products do
	#			member do
	#				get 'short'
	#				post 'toggle'
	#			end
	#
	#			collection do
	#				get 'sold'
	#			end
	#		end

	# Sample resource route with sub-resources:
	#		resources :products do
	#			resources :comments, :sales
	#			resource :seller
	#		end

	# Sample resource route with more complex sub-resources
	#		resources :products do
	#			resources :comments
	#			resources :sales do
	#				get 'recent', :on => :collection
	#			end
	#		end

	# Sample resource route within a namespace:
	#		namespace :admin do
	#			# Directs /admin/products/* to Admin::ProductsController
	#			# (app/controllers/admin/products_controller.rb)
	#			resources :products
	#		end

	# You can have the root of your site routed with "root"
	# just remember to delete public/index.html.
	# root :to => 'welcome#index'

	# See how all your routes lay out with "rake routes"

	# This is a legacy wild controller route that's not recommended for RESTful applications.
	# Note: This route will make all actions in every controller accessible via GET requests.
	# match ':controller(/:action(/:id))(.:format)'

	root :to => 'slides#index'

	get 'monitor', to: 'monitor#index'

	resources :displays do
		resources :history, only: [:index, :show] do
			collection do
				post 'clear'
			end
		end
		
		member do
			get 'presentation'
			get 'slide_queue'
			get 'slide_stats'
			post 'sort_queue'
			post 'remove_override'
			put 'update_override'
			post 'grant'
			post 'deny'
			get 'dpy_control'
		end

		collection do
			post 'hello'
		end
	end

	resources :events do
		member do
			post 'generate_images'
		end

		collection do

		end
	end

	resources :groups do
		member do
			post 'sort', :as => 'sort'
			get 'add_slides'
			post 'adopt_slides'
			post 'hide_all'
			post 'publish_all'
			post 'grant'
			post 'deny'
			post 'add_to_override'
			get 'download_slides'
		end
	end

	resource :login do
	end

	resources :presentations do
		member do
			post 'sort', :as => 'sort'
			post 'add_group'
			post 'remove_group'
			get 'preview'
			post 'grant'
			post 'deny'
			post 'add_to_override'
		end

		collection do
		end
	end

	resources :schedules do
		member do
		end

		collection do

		end
	end

	resources :slides do
		resources :history, only: [:index, :show] do
			collection do
				post 'clear'
			end
		end
		
		
		member do
			get 'preview'
			get 'full'
			get 'svg_data'
			post "svg_data" => :svg_save, :as => 'svg_save'
			post 'ungroup'
			post 'undelete'
			post 'hide'
			post 'deny'
			post 'grant'
			post 'to_inkscape'
			post 'to_simple'
			post 'add_to_group'
			post 'add_to_override'
			post 'clone'
			get 'thumb'
		end

		collection do
		end
	end

	resources :templates do
		member do
			post :sort
		end

		collection do
		end
	end

	resources :tickets do
		member do
		end

		collection do
		end
	end

	resources :users do
		member do
			get 'roles'
			post 'grant'
		end

		collection do

		end
	end

end
