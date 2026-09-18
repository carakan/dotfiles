# Routing Patterns

Comprehensive routing patterns for Rails 7+ applications.

## Basic Resources

Define RESTful routes with `resources`. Limit exposed actions with `only` or `except` to keep the route table lean.

```ruby
Rails.application.routes.draw do
  resources :articles
  resources :users, only: [:index, :show]
  resources :sessions, only: [:new, :create, :destroy]
end
```

## Nested Resources

Nest resources to express parent-child relationships. Use `shallow: true` to avoid deeply nested URLs for actions that don't need the parent context.

```ruby
resources :articles do
  resources :comments, only: [:create, :destroy]
  resources :likes, only: [:create, :destroy], shallow: true
end
```

## Member and Collection Routes

Add custom actions beyond standard CRUD. Use `member` for actions on a single record (requires `:id`) and `collection` for actions on the set.

```ruby
resources :articles do
  member do
    post :publish
    post :unpublish
    get :preview
  end
  collection do
    get :search
    get :drafts
  end
end
```

## Namespaced Routes

Group routes under a module namespace for admin panels or API versioning. Controllers live in matching subdirectories (e.g., `app/controllers/admin/users_controller.rb`).

```ruby
namespace :admin do
  resources :users
  resources :articles
end

namespace :api do
  namespace :v1 do
    resources :users, only: [:index, :show]
  end
end
```

## Constraints

Restrict routes based on request properties like subdomain, format, or custom logic.

```ruby
# Subdomain constraint
constraints subdomain: 'api' do
  resources :users
end

# Format constraint
resources :articles, constraints: { format: 'json' }

# Custom constraint
constraints ->(req) { req.env['HTTP_USER_AGENT'] =~ /iPhone/ } do
  resources :mobile_pages
end
```

## Route Concerns

Extract reusable route patterns with `concern` to DRY up route definitions shared across multiple resources.

```ruby
concern :commentable do
  resources :comments, only: [:create, :destroy]
end

concern :likeable do
  resources :likes, only: [:create, :destroy]
end

resources :articles, concerns: [:commentable, :likeable]
resources :photos, concerns: [:commentable, :likeable]
```
