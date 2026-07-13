import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "label"]
  static values = {
    seconds: { type: Number, default: 30 },
    waitingLabel: String
  }

  connect() {
    this.remainingSeconds = this.secondsValue
    this.buttonTarget.disabled = true
    this.updateLabel()
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    window.clearInterval(this.timer)
  }

  tick() {
    this.remainingSeconds -= 1

    if (this.remainingSeconds <= 0) {
      window.clearInterval(this.timer)
      this.buttonTarget.disabled = false
      this.labelTarget.textContent = this.labelTarget.dataset.readyLabel || this.labelTarget.textContent.replace(/\s*\(.*\)$/, "")
      return
    }

    this.updateLabel()
  }

  updateLabel() {
    if (!this.labelTarget.dataset.readyLabel) {
      this.labelTarget.dataset.readyLabel = this.labelTarget.textContent.trim()
    }

    this.labelTarget.textContent = `${this.waitingLabelValue} (${this.remainingSeconds} s)`
  }
}
