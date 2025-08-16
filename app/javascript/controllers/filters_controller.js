import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "status"]

  submit() {
    this.element.requestSubmit()
  }
}


