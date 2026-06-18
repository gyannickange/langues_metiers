import { Controller } from "@hotwired/stimulus"

// Shows behavioral-profile fields or métier (diagnostic) fields based on `kind`.
export default class extends Controller {
  static targets = ["kind", "behavioralFields", "professionFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const profession = this.kindTarget.value === "profession"
    this.behavioralFieldsTarget.hidden = profession
    this.professionFieldsTarget.hidden = !profession
  }
}
