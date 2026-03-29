import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "list"]

  add(event) {
    event.preventDefault()
    
    // Generate a unique index for inputs so they don't overwrite each other if needed
    // But since we're pushing to an array, the name="question[parsed_options][][text]" is fine.
    const content = this.templateTarget.innerHTML
    
    this.listTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    
    // Find the closest option row and completely remove it from the DOM
    const wrapper = event.target.closest(".option-row")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
