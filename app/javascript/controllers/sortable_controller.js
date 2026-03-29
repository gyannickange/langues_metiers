import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String,
    paramName: { type: String, default: "position" }
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: "[data-sortable-handle]",
      ghostClass: "opacity-50",
      dragClass: "shadow-xl",
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  onEnd(event) {
    if (!this.urlValue) return;

    const itemId = event.item.dataset.id;
    const newPosition = event.newIndex + 1; // Sortable uses 0-based index, we want 1-based (or just pass array)

    // Alternatively, send the whole array of ordered IDs
    const orderedIds = Array.from(this.element.children).map(child => child.dataset.id);

    const data = new FormData();
    data.append("ordered_ids[]", orderedIds.join(',')); // Send as comma separated array

    // Iterate through orderedIds and append them
    orderedIds.forEach(id => {
      data.append("ordered_ids[]", id);
    });

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: data
    }).then(response => {
      if (!response.ok) {
        console.error("Failed to update order");
      }
    }).catch(error => {
      console.error("Error connecting to server to update order", error);
    });
  }
}
