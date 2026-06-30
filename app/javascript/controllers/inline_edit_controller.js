import { Controller } from "@hotwired/stimulus"

// Turns a table cell into an input on click, and PATCHes the change as a
// Turbo Stream request so the row re-renders in place (success or with an
// inline validation error) without a page navigation.
export default class extends Controller {
  static targets = ["display", "field", "error"]
  static values = { url: String, param: String, kindFilter: String }

  edit() {
    this.displayTarget.hidden = true
    this.fieldTarget.hidden = false
    this.fieldTarget.focus()
    this.fieldTarget.select()
  }

  cancel() {
    this.fieldTarget.value = this.fieldTarget.defaultValue
    this.fieldTarget.hidden = true
    this.displayTarget.hidden = false
  }

  save(event) {
    if (event.type === "keydown") event.preventDefault()

    if (this.fieldTarget.value === this.fieldTarget.defaultValue) {
      this.fieldTarget.hidden = true
      this.displayTarget.hidden = false
      return
    }

    this.submit(this.fieldTarget.value)
  }

  toggle(event) {
    this.submit(event.target.checked ? "1" : "0", event.target)
  }

  submit(value, checkbox = null) {
    const data = new FormData()
    data.append(`diagnostic_question[${this.paramValue}]`, value)
    if (this.kindFilterValue) data.append("kind", this.kindFilterValue)

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "X-Inline-Edit": "true"
      },
      body: data
    })
      .then(response => response.text())
      .then(html => window.Turbo.renderStreamMessage(html))
      .catch(error => {
        console.error("Error saving inline edit", error)
        // Network failure: no stream came back to restore state, so roll back by hand.
        if (checkbox) checkbox.checked = !checkbox.checked
        if (this.hasFieldTarget) {
          this.fieldTarget.hidden = true
          this.displayTarget.hidden = false
        }
        if (this.hasErrorTarget) {
          this.errorTarget.textContent = "Échec de l'enregistrement, réessayez."
          this.errorTarget.hidden = false
        }
      })
  }
}
