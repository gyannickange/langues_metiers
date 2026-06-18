import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "error"]
  static values = { url: String, interval: { type: Number, default: 3000 } }

  connect() {
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  retry() {
    this.showLoading()
    this.poll()
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`PDF status request failed: ${response.status}`)

      const data = await response.json()
      if (data.ready) {
        clearInterval(this.timer)
        window.location.reload()
      }
    } catch (_error) {
      this.showError()
    }
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden")
    this.errorTarget.classList.add("hidden")
  }

  showError() {
    this.loadingTarget.classList.add("hidden")
    this.errorTarget.classList.remove("hidden")
  }
}
