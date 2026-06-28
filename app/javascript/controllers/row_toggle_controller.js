import { Controller } from "@hotwired/stimulus"

// Shows/hides a row's paired form-row with no network request.
// The form's own submit (handled elsewhere, via fetch) is what talks to the server.
export default class extends Controller {
  static targets = ["newRow"]

  openNew() {
    this.newRowTarget.hidden = false
    this.newRowTarget.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  cancelNew() {
    const form = this.newRowTarget.querySelector("form")
    if (form) form.reset()
    this.newRowTarget.hidden = true
  }

  // Pairing is by element id, not DOM adjacency: drag-and-drop reordering
  // (sortable_controller.js) moves a display row without its hidden edit-form
  // sibling, so nextElementSibling/previousElementSibling can't be trusted here.
  openEdit(event) {
    document.getElementById(event.params.displayId).hidden = true
    document.getElementById(event.params.editId).hidden = false
  }

  cancelEdit(event) {
    const editRow = document.getElementById(event.params.editId)
    const form = editRow.querySelector("form")
    if (form) form.reset()
    editRow.hidden = true
    document.getElementById(event.params.displayId).hidden = false
  }
}
