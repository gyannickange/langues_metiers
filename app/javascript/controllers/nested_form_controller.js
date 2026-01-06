import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["template", "items", "item", "emptyState"];

  connect() {
    this.reindex();
  }

  add(event) {
    event.preventDefault();
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      Date.now().toString()
    );
    const templateWrapper = document.createElement("div");
    templateWrapper.innerHTML = content.trim();
    const newItem = templateWrapper.firstElementChild;

    if (newItem) {
      newItem.dataset.newRecord = "true";
      this.itemsTarget.appendChild(newItem);
      this.reindex();
    }
  }

  remove(event) {
    event.preventDefault();
    const item = event.target.closest("[data-nested-form-target='item']");
    if (!item) return;

    const destroyInput = item.querySelector("input[name$='[_destroy]']");
    if (destroyInput) {
      destroyInput.value = "1";
    }

    if (item.dataset.newRecord === "true") {
      item.remove();
    } else {
      item.classList.add("hidden");
    }

    this.reindex();
  }

  reindex() {
    let order = 1;
    this.itemTargets.forEach((item) => {
      if (item.classList.contains("hidden")) return;
      const orderField = item.querySelector("[data-nested-form-order-field]");
      if (orderField) {
        orderField.value = order;
      }
      order += 1;
    });

    if (this.hasEmptyStateTarget) {
      const hasVisibleItems = this.visibleItems().length > 0;
      this.emptyStateTarget.classList.toggle("hidden", hasVisibleItems);
    }
  }

  visibleItems() {
    return this.itemTargets.filter(
      (item) => !item.classList.contains("hidden")
    );
  }
}
