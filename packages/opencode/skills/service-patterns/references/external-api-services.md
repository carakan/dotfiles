# External API Services

Wrap third-party API integrations in service objects to isolate networking concerns, handle errors consistently, and make the integration testable.

## Pattern

```ruby
# app/services/github/create_issue.rb
module GitHub
  class CreateIssue
    include Callable

    def initialize(repo:, title:, body:)
      @repo = repo
      @title = title
      @body = body
    end

    def call
      issue = client.create_issue(@repo, @title, @body)
      Result.success(issue: issue, url: issue.html_url)
    rescue Octokit::Error => e
      Result.failure(errors: ["GitHub API error: #{e.message}"])
    rescue Faraday::Error => e
      Result.failure(errors: ["Network error: #{e.message}"])
    end

    private

    def client
      @client ||= Octokit::Client.new(
        access_token: Rails.application.credentials.github_token
      )
    end
  end
end
```

## Key Principles

- **Isolate the client** — Build or inject the API client in a private method so tests can stub it.
- **Rescue specific errors** — Catch the library's error hierarchy (e.g., `Octokit::Error`) and network-level errors (e.g., `Faraday::Error`, `Net::OpenTimeout`) separately.
- **Namespace by provider** — Use a module per external service (`GitHub::`, `Stripe::`, `Twilio::`) to keep services organized.
- **Credential management** — Pull tokens from `Rails.application.credentials` or environment variables, never hardcode.

## Retry and Timeout Guidance

For production API integrations, consider:

```ruby
def client
  @client ||= Octokit::Client.new(
    access_token: Rails.application.credentials.github_token,
    connection_options: {
      request: { timeout: 10, open_timeout: 5 }
    }
  )
end
```

For retries, use a gem like `retriable` or implement a simple retry loop with exponential backoff rather than building retry logic into every service.
