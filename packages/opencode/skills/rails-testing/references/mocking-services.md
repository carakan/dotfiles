# Mocking External Services

Patterns for stubbing and recording HTTP interactions in Rails tests.

## WebMock

### Setup

```ruby
# spec/spec_helper.rb or test/test_helper.rb
require 'webmock/rspec'   # for RSpec
require 'webmock/minitest' # for Minitest

# Block all external requests (allow localhost for system tests)
WebMock.disable_net_connect!(allow_localhost: true)
```

### Stubbing Requests

```ruby
# Stub a specific GET request
stub_request(:get, 'https://api.example.com/users')
  .to_return(
    status: 200,
    body: '{"users": []}',
    headers: { 'Content-Type' => 'application/json' }
  )

# Stub with pattern matching
stub_request(:post, /api\.stripe\.com/)
  .to_return(status: 200, body: fixture('stripe_charge.json'))

# Stub with request body matching
stub_request(:post, 'https://api.example.com/webhooks')
  .with(body: hash_including(event: 'payment.success'))
  .to_return(status: 200)

# Stub with headers
stub_request(:get, 'https://api.example.com/protected')
  .with(headers: { 'Authorization' => 'Bearer token123' })
  .to_return(status: 200, body: '{"data": "secret"}')
```

### Asserting Requests Were Made

```ruby
# Assert a request was made
expect(WebMock).to have_requested(:get, 'https://api.example.com/users')

# Assert with specific body
expect(WebMock).to have_requested(:post, 'https://api.example.com/users')
  .with(body: { name: 'John' }.to_json)

# Assert request count
expect(WebMock).to have_requested(:get, 'https://api.example.com/users').times(2)
```

### Simulating Failures

```ruby
# Timeout
stub_request(:get, 'https://api.example.com/slow')
  .to_timeout

# Network error
stub_request(:get, 'https://api.example.com/down')
  .to_raise(SocketError)

# Specific HTTP error
stub_request(:get, 'https://api.example.com/not-found')
  .to_return(status: 404, body: '{"error": "not found"}')
```

## VCR

### Setup

```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
  config.filter_sensitive_data('<AUTH_TOKEN>') { ENV['AUTH_TOKEN'] }

  # Allow localhost for system tests
  config.ignore_localhost = true
end
```

### Recording Cassettes

```ruby
# Explicit cassette usage
VCR.use_cassette('github_user') do
  response = GithubClient.get_user('octocat')
  expect(response['login']).to eq('octocat')
end

# RSpec metadata (auto-names cassette from test description)
it 'fetches user from GitHub', :vcr do
  response = GithubClient.get_user('octocat')
  expect(response['login']).to eq('octocat')
end
```

### Recording Modes

```ruby
# Record once, replay forever (default)
VCR.use_cassette('api_call', record: :once) { ... }

# Re-record when cassette is older than 7 days
VCR.use_cassette('api_call', re_record_interval: 7.days) { ... }

# Always record new episodes, replay existing
VCR.use_cassette('api_call', record: :new_episodes) { ... }

# Never record, only replay (CI-safe)
VCR.use_cassette('api_call', record: :none) { ... }
```

## Choosing Between WebMock and VCR

| Scenario | Recommended |
|---|---|
| Simple, predictable API responses | WebMock |
| Complex API interactions with many endpoints | VCR |
| Testing error handling and edge cases | WebMock |
| Recording real API behavior for regression | VCR |
| CI environments with no external access | Either (both replay) |
