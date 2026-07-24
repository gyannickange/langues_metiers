import { Controller } from "@hotwired/stimulus"

// Filters the diagnostic answer list client-side: no server round-trip,
// since every answer is already rendered in one response (no pagination here).
export default class extends Controller {
  static targets = ["row", "button", "empty"]
  static classes = ["active", "inactive"]

  filter(event) {
    const selected = event.params.filter

    this.buttonTargets.forEach(button => {
      const isSelected = button === event.currentTarget
      this.activeClasses.forEach(c => button.classList.toggle(c, isSelected))
      this.inactiveClasses.forEach(c => button.classList.toggle(c, !isSelected))
      button.setAttribute("aria-pressed", isSelected.toString())
    })

    let visibleRows = 0
    this.rowTargets.forEach(row => {
      const matches =
        selected === "all" ||
        (selected === "scored"
          ? row.dataset.scored === "true"
          : selected.startsWith("career-")
            ? (row.dataset.careers || "").split(",").includes(selected.replace("career-", ""))
            : row.dataset.category === selected)
      row.hidden = !matches
      if (matches) visibleRows += 1
    })

    this.emptyTargets.forEach(empty => { empty.hidden = visibleRows > 0 })
  }
}
