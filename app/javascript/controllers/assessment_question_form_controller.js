import { Controller } from "@hotwired/stimulus"

// Shows the per-kind fields (disc_type / academic_field_slug / skill) based on `kind`.
export default class extends Controller {
  static targets = ["kind", "discField", "academicField", "skillField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const kind = this.kindTarget.value
    this.discFieldTarget.hidden = kind !== "disc"
    this.academicFieldTarget.hidden = kind !== "interest"
    this.skillFieldTarget.hidden = kind !== "skill"
  }
}
