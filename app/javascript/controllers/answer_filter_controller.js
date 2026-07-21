import { Controller } from "@hotwired/stimulus"

// Filters the diagnostic answer list client-side: no server round-trip,
// since every answer is already rendered in one response (no pagination here).
export default class extends Controller {
  static targets = ["row", "button"]
  static classes = ["active", "inactive"]

  filter(event) {
    const selected = event.params.filter

    this.buttonTargets.forEach(button => {
      const isSelected = button === event.currentTarget
      this.activeClasses.forEach(c => button.classList.toggle(c, isSelected))
      this.inactiveClasses.forEach(c => button.classList.toggle(c, !isSelected))
    })

    this.rowTargets.forEach(row => {
      const matches =
        selected === "all" ||
        (selected === "scored" ? row.dataset.scored === "true" : row.dataset.category === selected)
      row.hidden = !matches
    })
  }
}
