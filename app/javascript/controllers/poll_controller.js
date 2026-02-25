// app/javascript/controllers/poll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setInterval(() => this.#poll(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  #poll() {
    fetch(this.urlValue, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      .then(r => r.text())
      .then(html => {
        const target = document.getElementById("payment-status")
        if (target) target.outerHTML = html
      })
  }
}
