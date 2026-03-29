import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["kind", "optionsField"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const kind = this.kindTarget.value
    
    // Check if the current value is 'mcq'
    if (kind === "mcq") {
      this.optionsFieldTarget.classList.remove("hidden")
      this.optionsFieldTarget.classList.add("block", "animate-premium-in")
    } else {
      this.optionsFieldTarget.classList.add("hidden")
      this.optionsFieldTarget.classList.remove("block")
    }
  }
}
