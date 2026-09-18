# OWASP Top 10 in Rails

Detailed patterns for preventing the most common web application vulnerabilities in Rails.

## 1. SQL Injection Prevention

Rails ActiveRecord prevents SQL injection by default, but raw SQL is dangerous:

```ruby
# SAFE: Parameterized queries
User.where(email: params[:email])
User.where('email = ?', params[:email])
User.where('email = :email', email: params[:email])

# DANGEROUS: String interpolation
User.where("email = '#{params[:email]}'")  # SQL injection!
User.where("email = " + params[:email])     # SQL injection!
```

Additional safe patterns for complex queries:

```ruby
# SAFE: Arel for complex conditions
users = User.arel_table
User.where(users[:email].matches("%#{User.sanitize_sql_like(params[:q])}%"))

# SAFE: find_by with hash conditions
User.find_by(email: params[:email])

# DANGEROUS: Raw SQL without sanitization
User.find_by_sql("SELECT * FROM users WHERE email = '#{params[:email]}'")

# SAFE: Raw SQL with binds
User.find_by_sql(['SELECT * FROM users WHERE email = ?', params[:email]])
```

## 2. Cross-Site Scripting (XSS) Prevention

Rails escapes output by default in ERB:

```erb
<%# SAFE: Auto-escaped %>
<%= @user.name %>
<%= @user.bio %>

<%# DANGEROUS: Bypasses escaping %>
<%= raw @user.bio %>
<%= @user.bio.html_safe %>
<%== @user.bio %>
```

When raw HTML is necessary, sanitize it:

```ruby
<%= sanitize @user.bio, tags: %w[p br strong em], attributes: %w[class] %>
```

Content Security Policy as defense-in-depth:

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.img_src     :self, :data
    policy.font_src    :self
    policy.connect_src :self
    policy.frame_ancestors :none
  end

  config.content_security_policy_nonce_generator = ->(request) {
    request.session.id.to_s
  }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

## 3. Cross-Site Request Forgery (CSRF)

CSRF protection is enabled by default:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# In forms (automatic with form_with)
<%= form_with model: @user do |f| %>
  <%# CSRF token automatically included %>
<% end %>
```

For API controllers, disable CSRF but use token authentication:

```ruby
class Api::BaseController < ActionController::API
  # No CSRF for API, but authenticate with tokens
  before_action :authenticate_api_token!
end
```

## 4. Broken Authentication

Use Devise with secure defaults:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.stretches = Rails.env.test? ? 1 : 12
  config.pepper = Rails.application.credentials.devise_pepper
  config.password_length = 12..128
  config.timeout_in = 30.minutes
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 5
  config.unlock_strategy = :time
  config.unlock_in = 1.hour
end
```

## 5. Broken Access Control (Authorization)

Implement proper authorization with Pundit:

```ruby
class ArticlePolicy < ApplicationPolicy
  def update?
    record.user == user || user.admin?
  end

  def destroy?
    record.user == user || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end

# In controller
class ArticlesController < ApplicationController
  def update
    @article = Article.find(params[:id])
    authorize @article

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit
    end
  end
end
```

Ensure every controller action is authorized — add a Pundit after-action check:

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
end
```
