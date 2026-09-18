---
name: action-controller-patterns
description: Use when building or refactoring Rails controllers — structuring actions, defining routes, whitelisting parameters, or responding in multiple formats. Also applies when sharing logic across controllers with concerns, handling errors consistently, or adding Turbo Stream responses alongside HTML. Covers Rails 7+ patterns including params.expect.
---

# Action Controller Patterns

Guidance for implementing Rails controllers, routing, request handling, and response patterns for Rails 7+.

## Quick Reference

| Need                    | Solution                                   |
| ----------------------- | ------------------------------------------ |
| Load resource           | `before_action :set_resource`              |
| Require login           | `before_action :authenticate_user!`        |
| Whitelist params        | `params.require(:model).permit(...)`       |
| Params (7.2+)           | `params.expect(model: [...])`              |
| Multiple formats        | `respond_to` block                         |
| Handle 404              | `rescue_from ActiveRecord::RecordNotFound` |
| Custom route action     | `member` or `collection` route             |
| Shared controller logic | Controller concern                         |

## Controller Structure

A well-structured controller follows RESTful conventions with callbacks for shared setup, authorization checks, and a private method for strong parameters. Keep actions focused on the request/response cycle.

```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :authorize_article, only: [:edit, :update, :destroy]

  # GET /articles
  def index
    @articles = Article.published.recent.page(params[:page])
  end

  # GET /articles/:id
  def show; end

  # GET /articles/new
  def new
    @article = current_user.articles.build
  end

  # POST /articles
  def create
    @article = current_user.articles.build(article_params)

    if @article.save
      redirect_to @article, notice: 'Article created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /articles/:id/edit
  def edit; end

  # PATCH/PUT /articles/:id
  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /articles/:id
  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article deleted.'
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def authorize_article
    redirect_to articles_url, alert: 'Not authorized.' unless @article.user == current_user
  end

  def article_params
    params.require(:article).permit(:title, :body, :published)
  end
end
```

## Strong Parameters

Strong parameters prevent mass-assignment vulnerabilities by whitelisting permitted attributes. Always define a private `*_params` method rather than permitting inline.

### Basic Usage

```ruby
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
```

### Nested Attributes

Permit nested attributes for `accepts_nested_attributes_for` associations. Include `:id` and `:_destroy` to support editing and removing nested records.

```ruby
def order_params
  params.require(:order).permit(
    :customer_name,
    :shipping_address,
    line_items_attributes: [:id, :product_id, :quantity, :_destroy]
  )
end
```

### Rails 7.2+ expect Syntax

The `params.expect` method provides stricter parameter filtering that raises on unexpected structures, preventing parameter injection attacks.

```ruby
def user_params
  params.expect(user: [:name, :email, :password])
end

def order_params
  params.expect(order: [:customer_name, line_items: [[:product_id, :quantity]]])
end
```

### Dynamic Permit

Conditionally expand permitted attributes based on user roles or context.

```ruby
def article_params
  permitted = [:title, :body]
  permitted << :featured if current_user.admin?
  params.require(:article).permit(permitted)
end
```

## Before Actions (Filters)

Filters run code before, after, or around controller actions. Use `before_action` for authentication, resource loading, and authorization. Scope filters with `only`, `except`, or `if`/`unless` to keep them targeted.

### Common Patterns

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_time_zone

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_time_zone
    Time.zone = current_user&.time_zone || 'UTC'
  end
end
```

### Conditional Filters

Restrict filters to specific actions or conditions to avoid unnecessary processing.

```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :require_admin, if: :admin_action?

  private

  def admin_action?
    action_name.in?(%w[feature unfeature])
  end
end
```

### Skip Filters

Override inherited filters in subclasses. Use sparingly — skipping authentication or CSRF protection requires careful consideration. See the `rails-security` skill for security implications.

```ruby
class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token  # For API controllers
end

class PublicPagesController < ApplicationController
  skip_before_action :authenticate_user!
end
```

## Response Handling

### Respond To (Multiple Formats)

Use `respond_to` to serve different formats from a single action. Rails selects the block matching the request's `Accept` header or URL format extension.

```ruby
def show
  @article = Article.find(params[:id])

  respond_to do |format|
    format.html
    format.json { render json: @article }
    format.xml { render xml: @article }
    format.pdf { send_article_pdf(@article) }
  end
end
```

### Turbo Stream Responses (Rails 7+)

Return Turbo Stream responses for in-place page updates without full reloads. Always provide an HTML fallback for non-Turbo requests. For comprehensive Turbo Stream patterns including broadcasts and frame targeting, see the `hotwire-patterns` skill.

```ruby
def create
  @comment = @article.comments.build(comment_params)

  respond_to do |format|
    if @comment.save
      format.turbo_stream
      format.html { redirect_to @article, notice: 'Comment added.' }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

### JSON Responses

For dedicated API endpoints, render JSON directly. For full API controller patterns including serialization, versioning, and authentication, see the `rails-api-pro` agent.

```ruby
def index
  @users = User.all
  render json: @users
end

def create
  @user = User.new(user_params)
  if @user.save
    render json: @user, status: :created, location: @user
  else
    render json: @user.errors, status: :unprocessable_entity
  end
end
```

### Streaming Responses

Stream large responses (CSV exports, reports) to avoid buffering the entire response in memory. Particularly useful for exports that iterate over large record sets.

```ruby
def export
  headers['Content-Type'] = 'text/csv'
  headers['Content-Disposition'] = 'attachment; filename="users.csv"'

  response.status = 200

  self.response_body = Enumerator.new do |yielder|
    yielder << "name,email\n"
    User.find_each do |user|
      yielder << "#{user.name},#{user.email}\n"
    end
  end
end
```

## Routing

Define RESTful routes with `resources` and scope them with namespaces, nesting, and constraints. For detailed routing patterns including nested resources, namespaces, constraints, and route concerns, see `references/routing-patterns.md`.

```ruby
Rails.application.routes.draw do
  resources :articles do
    resources :comments, only: [:create, :destroy]
    member do
      post :publish
    end
    collection do
      get :search
    end
  end

  namespace :admin do
    resources :users
  end
end
```

## Error Handling

Use `rescue_from` in `ApplicationController` to handle exceptions consistently across the application. Map exception classes to handler methods that render appropriate responses for both HTML and JSON formats. See the `rails-security` skill for authorization error handling patterns.

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def not_found
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def forbidden
    redirect_to root_path, alert: 'Access denied.'
  end
end
```

## Flash Messages

Flash messages persist across a single redirect. Use `flash.now` when rendering (not redirecting) to avoid the message leaking into the next request.

```ruby
def create
  @user = User.new(user_params)
  if @user.save
    redirect_to @user, notice: 'User created successfully.'
  else
    flash.now[:alert] = 'Please fix the errors below.'
    render :new, status: :unprocessable_entity
  end
end

# Types: :notice, :alert, or custom like :success, :error
redirect_to users_path, flash: { success: 'Welcome!' }
```

## Controller Concerns

Extract shared behavior into concerns when multiple controllers need the same functionality. Define a clear interface with abstract methods or configuration options.

```ruby
# app/controllers/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  def search
    @results = model_class.search(params[:q]).page(params[:page])
    render 'shared/search_results'
  end

  private

  def model_class
    raise NotImplementedError
  end
end

# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  include Searchable

  private

  def model_class
    Article
  end
end
```

## Keep Controllers Thin

Controllers should only handle the request/response cycle — parsing params, calling domain logic, and choosing a response. Move complex logic out of controllers into dedicated objects:

- **Service Objects** — Complex business operations spanning multiple models
- **Query Objects** — Complex database queries with reusable scopes
- **Form Objects** — Multi-model forms or forms with custom validation
- **Presenters/Decorators** — View-specific logic and formatting

For detailed patterns and implementation examples, see the `service-patterns` skill.

```ruby
# Delegate to a service object instead of inlining business logic
def create
  result = CreateOrderService.new(current_user, order_params).call

  if result.success?
    redirect_to result.order, notice: 'Order placed!'
  else
    @order = result.order
    flash.now[:alert] = result.error
    render :new, status: :unprocessable_entity
  end
end
```

## Related Skills

- **`service-patterns`** — Service objects, form objects, query objects, and interactors
- **`hotwire-patterns`** — Turbo Frames, Turbo Streams, and Stimulus controllers
- **`rails-security`** — Authentication, authorization, CSRF, and security best practices
- **`rails-testing`** — Controller and request spec patterns

## Additional Resources

### Reference Files

- **`references/routing-patterns.md`** — Detailed routing patterns including nested resources, namespaces, constraints, and route concerns
