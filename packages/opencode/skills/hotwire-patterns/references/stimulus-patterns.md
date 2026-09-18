# Stimulus Controller Patterns

## Basic Controller Structure

```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results"];
  static values = { url: String, debounce: { type: Number, default: 300 } };
  static classes = ["active", "loading"];

  connect() {
    // Called when controller connects to DOM
  }

  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.performSearch();
    }, this.debounceValue);
  }

  performSearch() {
    const query = this.inputTarget.value;
    // Perform search...
  }

  disconnect() {
    // Cleanup when controller disconnects
    clearTimeout(this.timeout);
  }
}
```

## Toggle Controller

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];
  static classes = ["hidden"];

  toggle() {
    this.contentTarget.classList.toggle(this.hiddenClass);
  }
}
```

```erb
<div data-controller="toggle" data-toggle-hidden-class="hidden">
  <button data-action="click->toggle#toggle">Toggle</button>
  <div data-toggle-target="content">Content here</div>
</div>
```

## Form Submission Feedback

```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submit"];

  submitting() {
    this.submitTarget.disabled = true;
    this.submitTarget.value = "Saving...";
  }
}
```

## Stimulus Conventions

| Concept | HTML Attribute | JavaScript Access |
| --- | --- | --- |
| Controller | `data-controller="search"` | `search_controller.js` |
| Target | `data-search-target="input"` | `this.inputTarget` |
| Action | `data-action="input->search#search"` | `search()` method |
| Value | `data-search-url-value="/api/search"` | `this.urlValue` |
| Class | `data-search-active-class="highlighted"` | `this.activeClass` |
