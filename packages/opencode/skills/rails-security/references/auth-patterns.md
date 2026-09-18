# Authentication & Secrets Patterns

Detailed patterns for authentication, session management, and secrets handling in Rails.

## Password Security

```ruby
class User < ApplicationRecord
  has_secure_password

  validates :password, length: { minimum: 12 },
                       format: {
                         with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
                         message: 'must include uppercase, lowercase, and number'
                       },
                       if: :password_required?

  private

  def password_required?
    new_record? || password.present?
  end
end
```

## Session Security

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_myapp_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 24.hours
```

Key session hardening steps:

- Set `secure: true` in production to prevent transmission over HTTP
- Set `httponly: true` to prevent JavaScript access to the session cookie
- Set `same_site: :lax` (or `:strict`) to mitigate CSRF
- Rotate the session on login to prevent session fixation:

```ruby
class SessionsController < ApplicationController
  def create
    user = User.authenticate(params[:email], params[:password])
    if user
      reset_session  # Prevent session fixation
      session[:user_id] = user.id
      redirect_to root_path
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end
end
```

## Password Reset

```ruby
class PasswordResetsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    # Always show same response to prevent email enumeration
    if user
      user.send_reset_password_instructions
    end
    redirect_to login_path, notice: 'If email exists, reset instructions sent.'
  end
end
```

Key considerations:

- Use time-limited, single-use tokens
- Invalidate token after use or expiration
- Return the same response regardless of whether the email exists
- Send reset link over HTTPS only

## Secrets Management

### Rails Credentials (Rails 5.2+)

```bash
# Edit credentials
EDITOR="code --wait" rails credentials:edit

# Access in code
Rails.application.credentials.secret_api_key
Rails.application.credentials.dig(:aws, :access_key_id)
```

Environment-specific credentials:

```bash
rails credentials:edit --environment production
```

### Environment Variables

```ruby
# config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>

# In code — fail fast if missing
api_key = ENV.fetch('API_KEY') { raise 'API_KEY required' }
```

Never commit secrets:

```gitignore
# .gitignore
.env
.env.local
config/master.key
config/credentials/*.key
```

### Credential Access Patterns

```ruby
# Structured credentials
Rails.application.credentials.dig(:stripe, :secret_key)
Rails.application.credentials.dig(:aws, :access_key_id)

# With fallback for development
stripe_key = Rails.application.credentials.dig(:stripe, :secret_key) ||
             ENV['STRIPE_SECRET_KEY']
```
