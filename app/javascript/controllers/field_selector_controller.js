import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  redirect() {
    const selectedValue = this.selectTarget.value;
    if (selectedValue) {
      window.location.href = selectedValue;
    }
  }
}
