# Turbo Streams & Broadcasting Patterns

## Controller Response with Turbo Streams

```ruby
# app/controllers/comments_controller.rb
def create
  @comment = @post.comments.build(comment_params)

  respond_to do |format|
    if @comment.save
      format.turbo_stream
      format.html { redirect_to @post }
    else
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "new_comment",
          partial: "comments/form",
          locals: { comment: @comment }
        )
      }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

## Stream Template

```erb
<%# app/views/comments/create.turbo_stream.erb %>
<%= turbo_stream.append "comments" do %>
  <%= render @comment %>
<% end %>

<%= turbo_stream.update "comment_count", @post.comments.count %>

<%= turbo_stream.replace "new_comment" do %>
  <%= render "comments/form", comment: Comment.new %>
<% end %>
```

## Inline Streams (from controller)

Render multiple stream actions in a single response by passing an array.

```ruby
def destroy
  @comment.destroy

  respond_to do |format|
    format.turbo_stream {
      render turbo_stream: [
        turbo_stream.remove(@comment),
        turbo_stream.update("comment_count", @post.comments.count)
      ]
    }
    format.html { redirect_to @post }
  end
end
```

## ActionCable Broadcasting

For real-time updates pushed from the server without a request cycle.

### Model Broadcasting

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post

  after_create_commit -> {
    broadcast_append_to post,
      target: "comments",
      partial: "comments/comment"
  }

  after_update_commit -> {
    broadcast_replace_to post,
      partial: "comments/comment"
  }

  after_destroy_commit -> {
    broadcast_remove_to post
  }
end
```

### Subscribing in Views

```erb
<%# Subscribe to broadcasts %>
<%= turbo_stream_from @post %>

<div id="comments">
  <%= render @post.comments %>
</div>
```

### Custom Broadcasting

```ruby
# From anywhere in the application
Turbo::StreamsChannel.broadcast_append_to(
  "notifications_#{user.id}",
  target: "notifications",
  partial: "notifications/notification",
  locals: { notification: notification }
)
```

## Turbo Morphing (Rails 7.1+)

Page refreshes that preserve DOM state using morphing instead of replacement.

### Enable in Layout

```erb
<%# Enable page morphing in layout %>
<%= turbo_refreshes_morpho_with :morph %>
<%= turbo_refreshes_scroll_with :preserve %>
```

### Trigger a Morph Refresh

```ruby
respond_to do |format|
  format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
end
```
