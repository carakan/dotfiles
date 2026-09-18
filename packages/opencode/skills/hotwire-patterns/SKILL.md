---
name: hotwire-patterns
description: Use when adding interactive UI to a Rails application without custom JavaScript — inline editing, live updates, real-time notifications, or partial page navigation. Also applies when choosing between Turbo Frames, Turbo Streams, and Stimulus, or reviewing Hotwire implementation for correctness.
---

# Hotwire Patterns for Rails

Hotwire (HTML Over The Wire) provides a modern approach to building interactive Rails applications with minimal JavaScript. It consists of Turbo (Drive, Frames, Streams) and Stimulus.

## Component Overview

| Component             | Purpose                               | When to Use                                       |
| --------------------- | ------------------------------------- | ------------------------------------------------- |
| Turbo Drive           | Full page navigation without reload   | Default — enabled automatically                   |
| Turbo Frames          | Independently updatable page sections | Inline editing, tabbed content, scoped navigation |
| Turbo Streams         | Targeted DOM updates via CRUD actions | Multi-element updates from form submissions       |
| ActionCable + Streams | Real-time server-pushed updates       | Chat, notifications, live dashboards              |
| Stimulus              | Lightweight client-side behavior      | Toggles, form feedback, debounced search          |

## Stimulus Essentials

Stimulus controllers add client-side behavior to HTML elements using data attributes.

### Naming Conventions

- `data-controller="search"` maps to `search_controller.js`
- `data-search-target="input"` accesses `this.inputTarget`
- `data-action="input->search#search"` calls `search()` method
- `data-search-url-value="/api/search"` accesses `this.urlValue`
- `data-search-active-class="highlighted"` accesses `this.activeClass`

Declare targets, values, and classes as static properties. Always implement `disconnect()` to clean up event listeners and timers.

## Turbo Frames Essentials

Turbo Frames decompose pages into independently updatable sections. Key principles:

- Use `dom_id` helper for unique, meaningful frame IDs
- Provide loading state content for lazy-loaded frames
- Use `data-turbo-frame="_top"` to break out of frame scope
- Wrap both show and edit views in the same frame tag for inline editing

## Turbo Streams Actions

| Action    | Description                        |
| --------- | ---------------------------------- |
| `append`  | Add to end of container            |
| `prepend` | Add to beginning of container      |
| `replace` | Replace entire element             |
| `update`  | Update content of element          |
| `remove`  | Remove element                     |
| `before`  | Insert before element              |
| `after`   | Insert after element               |
| `morph`   | Morph element (Rails 7.1+)         |
| `refresh` | Reload page via morph (Rails 7.1+) |

Respond with `format.turbo_stream` in controllers. Use `.turbo_stream.erb` templates for complex responses, or render inline for simple cases.

## Review Checklists

### Stimulus

- [ ] Controllers follow naming conventions (`name_controller.js`)
- [ ] Targets, values, and classes are declared as static properties
- [ ] Actions use proper event syntax (`event->controller#method`)
- [ ] No direct DOM queries — use targets instead
- [ ] `disconnect()` cleans up event listeners and timers

### Turbo Frames

- [ ] Frame IDs are unique and meaningful (use `dom_id` helper)
- [ ] Loading states provide user feedback
- [ ] Frame boundaries are logical (don't wrap too much or too little)
- [ ] Non-Turbo fallback works for progressive enhancement

### Turbo Streams

- [ ] Stream actions match the intended DOM update
- [ ] Target elements exist in the DOM before streaming
- [ ] Partials render correctly in isolation
- [ ] Broadcasting scope is appropriate (don't over-broadcast)

### Performance

- [ ] No unnecessary full-page reloads (Turbo Drive not disabled broadly)
- [ ] DOM updates are targeted (prefer replace over full refresh)
- [ ] Caching still works with frames and streams
- [ ] JavaScript bundle size is reasonable

## Quick Reference

| Need                    | Solution                      |
| ----------------------- | ----------------------------- |
| Navigate without reload | Turbo Drive (default)         |
| Update part of a page   | Turbo Frames                  |
| Multiple DOM updates    | Turbo Streams                 |
| Real-time server push   | ActionCable + Turbo Streams   |
| Client-side behavior    | Stimulus controller           |
| Form with live updates  | Turbo Frame wrapping form     |
| Toast notifications     | Turbo Stream append           |
| Infinite scroll         | Turbo Frame with lazy loading |

## Additional Resources

### Reference Files

For detailed code examples and implementation patterns, consult:

- **`references/stimulus-patterns.md`** — Stimulus controller examples (search, toggle, form feedback) and conventions table
- **`references/turbo-frames-patterns.md`** — Turbo Frames examples (basic frames, lazy loading, inline editing, breaking out) and Turbo Drive configuration
- **`references/turbo-streams-patterns.md`** — Turbo Streams controller responses, templates, inline streams, ActionCable model broadcasting, custom broadcasting, and morphing (Rails 7.1+)
