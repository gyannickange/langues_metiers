import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "toggleButton", "toggleText", "toggleIcon"];

  connect() {
    this.isExpanded = false;
  }

  toggle() {
    this.isExpanded = !this.isExpanded;

    if (this.isExpanded) {
      this.expand();
    } else {
      this.collapse();
    }
  }

  expand() {
    this.contentTarget.classList.remove("hidden");
    this.toggleTextTarget.textContent = "Masquer les étapes";
    this.toggleIconTarget.textContent = "expand_less";
    this.toggleButtonTarget.classList.add("bg-primary", "text-white");
    this.toggleButtonTarget.classList.remove(
      "text-primary",
      "hover:bg-primary",
      "hover:text-white"
    );
  }

  collapse() {
    this.contentTarget.classList.add("hidden");
    this.toggleTextTarget.textContent = "Voir les étapes";
    this.toggleIconTarget.textContent = "expand_more";
    this.toggleButtonTarget.classList.remove("bg-primary", "text-white");
    this.toggleButtonTarget.classList.add(
      "text-primary",
      "hover:bg-primary",
      "hover:text-white"
    );
  }
}
