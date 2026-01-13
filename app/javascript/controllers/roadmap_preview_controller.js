import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "toggleButton", "toggleText", "toggleIcon"];
  static values = {
    viewSteps: String,
    hideSteps: String,
  };

  connect() {
    this.isExpanded = false;
    // Initialize content styles
    const content = this.contentTarget;
    content.style.maxHeight = "0";
    content.style.opacity = "0";
    content.style.overflow = "hidden";
    content.style.transition =
      "max-height 0.3s ease-out, opacity 0.3s ease-out";
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
    const content = this.contentTarget;
    const button = this.toggleButtonTarget;

    // Remove hidden class and set initial state
    content.classList.remove("hidden");
    content.style.maxHeight = "0";
    content.style.opacity = "0";

    // Force reflow to ensure initial state is applied
    content.offsetHeight;

    // Calculate and set final height
    const height = content.scrollHeight;
    content.style.maxHeight = `${height}px`;
    content.style.opacity = "1";

    // Update button state
    this.toggleTextTarget.textContent = this.hasHideStepsValue
      ? this.hideStepsValue
      : "Masquer les étapes";
    this.toggleIconTarget.textContent = "expand_less";
    this.toggleIconTarget.style.transform = "rotate(180deg)";
    button.classList.add("bg-primary", "text-white");
    button.classList.remove(
      "text-primary",
      "hover:bg-primary",
      "hover:text-white"
    );
    button.setAttribute("aria-expanded", "true");

    this.isExpanded = true;
  }

  collapse() {
    const content = this.contentTarget;
    const button = this.toggleButtonTarget;

    // Set initial height for transition
    content.style.maxHeight = `${content.scrollHeight}px`;
    content.style.opacity = "1";

    // Force reflow
    content.offsetHeight;

    // Collapse
    content.style.maxHeight = "0";
    content.style.opacity = "0";

    // Hide after animation
    setTimeout(() => {
      if (!this.isExpanded) {
        content.classList.add("hidden");
      }
    }, 300);

    // Update button state
    this.toggleTextTarget.textContent = this.hasViewStepsValue
      ? this.viewStepsValue
      : "Voir les étapes";
    this.toggleIconTarget.textContent = "expand_more";
    this.toggleIconTarget.style.transform = "rotate(0deg)";
    button.classList.remove("bg-primary", "text-white");
    button.classList.add(
      "text-primary",
      "hover:bg-primary",
      "hover:text-white"
    );
    button.setAttribute("aria-expanded", "false");

    this.isExpanded = false;
  }
}
