import { Controller } from "@hotwired/stimulus"
import "tom-select"

export default class extends Controller {
  connect() {
    const plugins = this.element.multiple ? ["remove_button"] : ["clear_button"]
    this.tomSelect = new window.TomSelect(this.element, { plugins })
  }

  disconnect() {
    this.tomSelect.destroy()
  }
}
