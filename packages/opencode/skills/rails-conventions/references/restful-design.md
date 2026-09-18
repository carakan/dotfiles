# RESTful Design in Rails

## Standard Actions

| Action  | HTTP Verb | Path            | Purpose         |
| ------- | --------- | --------------- | --------------- |
| index   | GET       | /users          | List all        |
| show    | GET       | /users/:id      | Show one        |
| new     | GET       | /users/new      | Form for new    |
| create  | POST      | /users          | Create new      |
| edit    | GET       | /users/:id/edit | Form for edit   |
| update  | PATCH/PUT | /users/:id      | Update existing |
| destroy | DELETE    | /users/:id      | Delete          |

## Custom Actions

Add custom actions sparingly using member or collection routes:

```ruby
resources :users do
  member do
    post :activate     # POST /users/:id/activate
    post :deactivate   # POST /users/:id/deactivate
  end
  collection do
    get :search        # GET /users/search
  end
end
```

Prefer creating a new resource over adding custom actions. For example, instead of `POST /users/:id/activate`, consider a `UserActivationsController` with a `create` action.

## Nested Resources

Limit nesting to one level:

```ruby
# Good: One level deep
resources :posts do
  resources :comments, only: [:index, :create]
end

# Avoid: Too deep
resources :users do
  resources :posts do
    resources :comments  # Don't do this
  end
end
```

For deeper relationships, use shallow nesting:

```ruby
resources :posts do
  resources :comments, shallow: true
end
# Produces:
#   POST   /posts/:post_id/comments     (create)
#   GET    /comments/:id                (show)
#   PATCH  /comments/:id                (update)
#   DELETE /comments/:id                (destroy)
```

## Namespace and Scope Patterns

```ruby
# Namespace: adds module, path prefix, and URL helpers
namespace :admin do
  resources :users  # Admin::UsersController, /admin/users
end

# Scope: path prefix only, no module
scope '/api/v1' do
  resources :users  # UsersController, /api/v1/users
end

# Module: controller module only, no path prefix
scope module: :api do
  resources :users  # Api::UsersController, /users
end
```

## Controller Structure

Follow this standard structure for RESTful controllers:

```ruby
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.all
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: 'User created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: 'User deleted.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```
