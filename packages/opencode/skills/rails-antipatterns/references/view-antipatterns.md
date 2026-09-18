# View & Hotwire Anti-Patterns

## Logic-Heavy Views

Conditional logic and data manipulation in templates obscures intent and resists testing.

**Bad:**

```erb
<% if @user.subscription && @user.subscription.active? && @user.subscription.plan == 'premium' %>
  <div class="premium-badge">
    <%= @user.subscription.plan.titleize %> Member since
    <%= @user.subscription.created_at.strftime('%B %Y') %>
  </div>
<% elsif @user.subscription && @user.subscription.trial? %>
  <div class="trial-badge">
    Trial ends in <%= ((@user.subscription.trial_end - Time.current) / 1.day).ceil %> days
  </div>
<% end %>
```

**Good** — move logic to helpers, presenters, or model methods:

```ruby
# app/helpers/subscriptions_helper.rb
module SubscriptionsHelper
  def subscription_badge(user)
    return unless user.subscription

    if user.subscription.premium?
      render 'subscriptions/premium_badge', subscription: user.subscription
    elsif user.subscription.trial?
      render 'subscriptions/trial_badge', subscription: user.subscription
    end
  end
end
```

```erb
<%= subscription_badge(@user) %>
```

## Instance Variables in Partials

Partials that rely on instance variables create hidden dependencies and make them fragile to reuse.

**Bad:**

```erb
<%# app/views/posts/_post.html.erb %>
<div class="post">
  <h2><%= @post.title %></h2>
  <p>By <%= @current_user.name %></p>
</div>
```

**Good** — use strict locals (Rails 7.1+):

```erb
<%# app/views/posts/_post.html.erb %>
<%# locals: (post:, author_name:) %>
<div class="post">
  <h2><%= post.title %></h2>
  <p>By <%= author_name %></p>
</div>
```

```erb
<%= render 'posts/post', post: @post, author_name: @post.author.name %>
```

## Nil Gymnastics in Views

Sprinkling `&.` and `try` throughout views to guard against nil.

**Bad:**

```erb
<%= @user&.profile&.bio || 'No bio' %>
<%= @order&.customer&.name || 'Unknown' %>
<%= @post.comments&.last&.author&.name || 'Anonymous' %>
```

**Good** — use the Null Object pattern or handle at the data layer:

```ruby
class User < ApplicationRecord
  has_one :profile

  def bio
    profile&.bio || 'No bio provided'
  end
end

class NullCustomer
  def name = 'Unknown'
end

class Order < ApplicationRecord
  def display_customer
    customer || NullCustomer.new
  end
end
```

```erb
<%= @user.bio %>
<%= @order.display_customer.name %>
```

## Turbo Streams When Frames Suffice

Using Turbo Streams for simple in-place updates that a Turbo Frame handles automatically. See `hotwire-patterns` skill for correct patterns.

**Bad:**

```ruby
# Controller responds with a stream to replace a single element
def edit
  @post = Post.find(params[:id])
  respond_to do |format|
    format.turbo_stream {
      render turbo_stream: turbo_stream.replace(
        dom_id(@post), partial: 'posts/form', locals: { post: @post }
      )
    }
  end
end
```

**Good** — wrap the content in a Turbo Frame and let it work automatically:

```erb
<%# show.html.erb %>
<%= turbo_frame_tag dom_id(@post) do %>
  <h2><%= @post.title %></h2>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>

<%# edit.html.erb %>
<%= turbo_frame_tag dom_id(@post) do %>
  <%= form_with model: @post do |form| %>
    <%= form.text_field :title %>
    <%= form.submit %>
  <% end %>
<% end %>
```

## Stimulus for Everything

Using Stimulus controllers to replicate behaviors that Turbo already provides, or building complex client-side state that belongs on the server.

**Bad** — fetching JSON and rendering HTML client-side:

```javascript
// Defeats the purpose of Hotwire (HTML over the wire)
export default class extends Controller {
  async load() {
    const response = await fetch(this.urlValue);
    const data = await response.json();
    this.resultsTarget.textContent = JSON.stringify(data);
  }
}
```

**Good** — let the server render HTML and use Turbo to deliver it:

```erb
<%= turbo_frame_tag "items", src: items_path, loading: :lazy do %>
  <p>Loading...</p>
<% end %>
```

## Ignoring Turbo Drive Compatibility

Adding JavaScript that breaks when Turbo Drive navigates (event listeners on `DOMContentLoaded` that don't re-fire).

**Bad:**

```javascript
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.dropdown').forEach(el => {
    el.addEventListener('click', toggleDropdown);
  });
});
```

**Good** — use a Stimulus controller, which connects/disconnects automatically:

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle() {
    this.element.classList.toggle("open");
  }
}
```
