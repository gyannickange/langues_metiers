import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "input"];
  static values = {
    delay: { type: Number, default: 300 },
  };

  connect() {
    this.timeout = null;
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  submit() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, this.delayValue);
  }
}
