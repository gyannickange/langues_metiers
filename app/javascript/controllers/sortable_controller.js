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

  onEnd() {
    if (!this.urlValue) return;

    const orderedIds = Array.from(this.element.children).map(child => child.dataset.id);

    const data = new FormData();
    orderedIds.forEach(id => data.append("ordered_ids[]", id));

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
