# Application Hardening

Detailed patterns for HTTP security headers, file upload validation, rate limiting, logging security, and deployment checklists.

## HTTP Security Headers

Using the `secure_headers` gem:

```ruby
# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.content_security_policy = {
    default_src: %w['self'],
    script_src: %w['self'],
    style_src: %w['self' 'unsafe-inline'],
    img_src: %w['self' data:],
    font_src: %w['self'],
    connect_src: %w['self'],
    frame_ancestors: %w['none']
  }
end
```

Manual header approach:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_security_headers

  private

  def set_security_headers
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Permissions-Policy'] = 'camera=(), microphone=(), geolocation=()'
  end
end
```

## File Upload Security

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    # Check file type
    unless file.content_type.in?(%w[application/pdf image/png image/jpeg])
      errors.add(:file, 'must be PDF, PNG, or JPEG')
    end

    # Check file size
    if file.byte_size > 10.megabytes
      errors.add(:file, 'must be less than 10MB')
    end
  end
end
```

Additional upload hardening:

- Store uploads outside the public directory (use Active Storage with cloud services)
- Scan uploads for malware in production (e.g., ClamAV)
- Generate random filenames to prevent path traversal
- Validate file content, not just extensions — use `marcel` or `file` command

## Rate Limiting

Using `Rack::Attack`:

```ruby
class Rack::Attack
  # Limit login attempts
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/login' && req.post?
  end

  # Limit API requests
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api')
  end

  # Block suspicious requests
  blocklist('block bad IPs') do |req|
    Blocklist.blocked?(req.ip)
  end
end
```

Additional rate limiting strategies:

```ruby
# Throttle by authenticated user (prevents abuse from a single account)
throttle('api/user', limit: 1000, period: 1.hour) do |req|
  req.env['warden']&.user&.id if req.path.start_with?('/api')
end

# Throttle password resets by email
throttle('password_resets/email', limit: 3, period: 1.hour) do |req|
  if req.path == '/password_resets' && req.post?
    req.params.dig('user', 'email')&.downcase&.strip
  end
end
```

## Logging Security

Never log sensitive data:

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :secret, :token, :api_key,
  :credit_card, :cvv, :ssn
]
```

## Security Scanning Tools

Integrate these tools into the development workflow:

| Tool | Purpose | Usage |
|------|---------|-------|
| `brakeman` | Static analysis for security vulnerabilities | `bundle exec brakeman` |
| `bundler-audit` | Check gems for known CVEs | `bundle exec bundler-audit check --update` |
| `ruby_audit` | Check Ruby version for CVEs | `bundle exec ruby-audit check` |

Add to CI pipeline:

```yaml
# .github/workflows/security.yml
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
    - run: bundle exec brakeman --no-pager
    - run: bundle exec bundler-audit check --update
```

## Deployment Security Checklist

### Before Deployment

- [ ] All secrets stored in credentials or environment variables
- [ ] `master.key` excluded from version control
- [ ] HTTPS enforced in production (`config.force_ssl = true`)
- [ ] Secure session configuration (httponly, secure, same_site)
- [ ] Strong parameters on all controller actions
- [ ] Authorization checks on all actions
- [ ] Rate limiting configured
- [ ] Security headers set
- [ ] File upload validation in place
- [ ] Dependency vulnerabilities checked (`bundle audit`)

### Ongoing Security Maintenance

- [ ] Regular dependency updates (`bundle update` + audit)
- [ ] Brakeman scans in CI pipeline
- [ ] Log review for suspicious activity
- [ ] Periodic penetration testing
- [ ] Monitor Ruby/Rails security advisories
