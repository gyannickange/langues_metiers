import { Controller } from "@hotwired/stimulus"

// Shows the per-kind fields (disc_type / filiere_slug / competence) based on `kind`.
export default class extends Controller {
  static targets = ["kind", "discField", "filiereField", "competenceField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const kind = this.kindTarget.value
    this.discFieldTarget.hidden = kind !== "disc"
    this.filiereFieldTarget.hidden = kind !== "interest"
    this.competenceFieldTarget.hidden = kind !== "competence"
  }
}
