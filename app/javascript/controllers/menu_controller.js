import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  toggle() {
    // On mobile, toggle translate-x classes to slide the sidebar
    const sidebar = this.sidebarTarget
    const isHidden = sidebar.classList.contains("-translate-x-full") || sidebar.classList.contains("hidden")
    sidebar.classList.toggle("hidden", !isHidden && window.innerWidth < 768)
    sidebar.classList.toggle("-translate-x-full")
  }
}


