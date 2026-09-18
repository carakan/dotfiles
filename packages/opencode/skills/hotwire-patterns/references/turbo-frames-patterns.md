# Turbo Frames Patterns

## Basic Frame

Wrap content in a `turbo_frame_tag` to make it independently updatable. Use `dom_id` for unique, meaningful frame IDs.

```erb
<%= turbo_frame_tag dom_id(@post) do %>
  <div class="post-card">
    <h2><%= @post.title %></h2>
    <%= link_to "Edit", edit_post_path(@post) %>
  </div>
<% end %>
```

## Lazy Loading

Load content asynchronously after the initial page render. Provide placeholder content inside the frame.

```erb
<%# Loads content asynchronously after page render %>
<%= turbo_frame_tag "comments",
    src: post_comments_path(@post),
    loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

## Breaking Out of Frames

Navigate outside the current frame scope using `data-turbo-frame="_top"`.

```erb
<%# Navigate outside the frame %>
<%= link_to "View Full Post", post_path(@post), data: { turbo_frame: "_top" } %>
```

## Inline Editing with Frames

Wrap both the show and edit views in the same frame tag. Clicking "Edit" loads the edit form inside the frame; submitting or cancelling returns to the show view.

```erb
<%# app/views/posts/edit.html.erb %>
<%= turbo_frame_tag dom_id(@post) do %>
  <%= form_with model: @post do |form| %>
    <%= form.text_field :title %>
    <%= form.submit "Save" %>
    <%= link_to "Cancel", post_path(@post) %>
  <% end %>
<% end %>
```

## Turbo Drive

Turbo Drive intercepts link clicks and form submissions, replacing the `<body>` without full page reloads. It is enabled by default.

### Opting Out

```erb
<%# Disable Turbo for a specific link %>
<%= link_to "External", "https://example.com", data: { turbo: false } %>

<%# Disable Turbo for a form %>
<%= form_with model: @user, data: { turbo: false } do |form| %>
  ...
<% end %>
```

### Progress Bar Customization

```css
/* Customize Turbo progress bar */
.turbo-progress-bar {
  height: 3px;
  background-color: #3b82f6;
}
```
