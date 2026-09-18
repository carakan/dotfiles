# Profiling Tools

## rack-mini-profiler

Add a timing badge to every page showing SQL queries, rendering time, and memory usage:

```ruby
# Gemfile
gem 'rack-mini-profiler'

# Optional: flamegraph support
gem 'stackprof'
gem 'flamegraph'
```

### Usage

- Timing badge appears on every page in development
- Press **Alt+P** to show/hide the badge
- Click the badge to see detailed breakdown

### Query Parameters

Append these to any URL for detailed profiling:

```
?pp=help                # Show all profiling options
?pp=env                 # Show environment info
?pp=profile-gc          # Profile garbage collection
?pp=profile-memory      # Profile memory allocations
?pp=flamegraph          # Generate flamegraph (requires stackprof)
?pp=flamegraph&flamegraph_sample_rate=1  # Higher resolution
?pp=analyze-memory      # Analyze memory with MemoryProfiler
```

### Configuration

```ruby
# config/initializers/mini_profiler.rb
if defined?(Rack::MiniProfiler)
  # Store results in Redis for multi-process servers
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
  Rack::MiniProfiler.config.storage_options = { url: ENV['REDIS_URL'] }

  # Enable in production for admin users
  Rack::MiniProfiler.config.authorization_mode = :allow_authorized
end

# In ApplicationController, authorize specific users
class ApplicationController < ActionController::Base
  before_action :check_mini_profiler

  private

  def check_mini_profiler
    Rack::MiniProfiler.authorize_request if current_user&.admin?
  end
end
```

## Benchmark

Measure execution time of code blocks:

```ruby
require 'benchmark'

# Single measurement
result = Benchmark.measure { User.all.to_a }
puts result
# => 0.010000   0.000000   0.010000 (  0.012345)
#    user        system     total      real

# Compare alternatives
Benchmark.bm(15) do |x|
  x.report('includes:')  { User.includes(:posts).to_a }
  x.report('preload:')   { User.preload(:posts).to_a }
  x.report('eager_load:') { User.eager_load(:posts).to_a }
end
```

### benchmark-ips (Recommended for Comparisons)

Measure iterations per second for more statistically meaningful comparisons:

```ruby
# Gemfile
gem 'benchmark-ips', group: :development

require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('find_each') { User.find_each { |u| u.name } }
  x.report('each')      { User.all.each { |u| u.name } }
  x.compare!
end
# Output shows iterations/second and relative speed
```

## MemoryProfiler

Identify memory-heavy operations and object allocations:

```ruby
# Gemfile
gem 'memory_profiler', group: :development

require 'memory_profiler'

report = MemoryProfiler.report do
  User.all.to_a
end

report.pretty_print
# Shows: total allocated, total retained, by gem, by file, by location
```

### Targeted Memory Analysis

```ruby
# Profile a specific request in a controller
report = MemoryProfiler.report do
  get '/users'
end

# Focus on allocations from your app code only
report = MemoryProfiler.report(allow_files: 'app/') do
  process_users
end
```

## derailed_benchmarks

Profile memory and boot time of the entire Rails application:

```ruby
# Gemfile
gem 'derailed_benchmarks', group: :development

# Profile boot memory by gem
bundle exec derailed bundle:mem

# Profile request memory
bundle exec derailed exec perf:mem_over_time

# Profile request speed
bundle exec derailed exec perf:ips
```

Useful for identifying gems that consume excessive memory at boot.

## ActiveSupport::Notifications

Subscribe to Rails instrumentation events for custom profiling:

```ruby
# Log slow queries (> 100ms)
ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  if duration > 100
    Rails.logger.warn("SLOW QUERY (#{duration.round(1)}ms): #{payload[:sql]}")
  end
end

# Log slow controller actions
ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if event.duration > 500
    Rails.logger.warn("SLOW ACTION (#{event.duration.round(1)}ms): #{event.payload[:controller]}##{event.payload[:action]}")
  end
end
```

## Rails Built-In Profiling

### Query Logging

```ruby
# Enable verbose query logs (shows caller location)
# config/environments/development.rb
config.active_record.verbose_query_logs = true
# Output: User Load (0.5ms) SELECT ... ← app/controllers/users_controller.rb:12

# Log query count per request (custom middleware)
class QueryCounter
  def initialize(app)
    @app = app
  end

  def call(env)
    count = 0
    counter = ->(*, **) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      status, headers, body = @app.call(env)
      Rails.logger.info("Queries: #{count} for #{env['PATH_INFO']}")
      [status, headers, body]
    end
  end
end
```

### Server Timing Headers

Expose server-side timing data to browser DevTools:

```ruby
# config/environments/development.rb
config.server_timing = true
# Shows in browser DevTools Network tab → Timing
```

## Production Monitoring

### Scout APM / New Relic / Datadog

For production profiling, use an APM service that provides:
- Transaction traces with SQL breakdown
- N+1 query detection
- Memory usage over time
- Background job performance
- Error tracking with performance context

### Custom Metrics with StatsD

```ruby
# Track specific operation timing
StatsD.measure('order.process') do
  process_order(@order)
end

# Count events
StatsD.increment('order.created')

# Gauge current values
StatsD.gauge('queue.size', Sidekiq::Queue.new.size)
```
