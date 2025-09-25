import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    // Auto-dismiss after 4 seconds
    this.timeout = setTimeout(() => this.dismissAll(), 4000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss(event) {
    const el = event?.currentTarget?.closest('[data-flash-target="item"]')
    if (el) el.remove()
  }

  dismissAll() {
    this.itemTargets.forEach((el) => el.remove())
  }
}


