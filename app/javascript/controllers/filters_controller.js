import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "form"]
  static values = {
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
    this.boundKeyDown = this.handleKeyDown.bind(this)
    document.addEventListener("keydown", this.boundKeyDown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeyDown)
  }

  submit() {
    if (this.timeout) clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      if (this.hasFormTarget) {
        this.formTarget.requestSubmit()
      } else {
        this.element.requestSubmit()
      }
    }, this.delayValue)
  }

  clear() {
    if (this.hasQueryTarget) {
      this.queryTarget.value = ""
      this.submit()
    }
  }

  handleKeyDown(event) {
    if (event.key === "/" && !["INPUT", "TEXTAREA"].includes(document.activeElement.tagName)) {
      event.preventDefault()
      if (this.hasQueryTarget) {
        this.queryTarget.focus()
      }
    }
  }
}


