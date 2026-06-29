import { Controller } from "@hotwired/stimulus"
import "tom-select"

export default class extends Controller {
  connect() {
    this.tomSelect = new window.TomSelect(this.element, { plugins: ["clear_button"] })
  }

  disconnect() {
    this.tomSelect.destroy()
  }
}
