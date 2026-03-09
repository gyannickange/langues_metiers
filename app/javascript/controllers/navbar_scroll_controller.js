import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar-scroll"
export default class extends Controller {
  static targets = ["nav"]

  connect() {
    this.lastScrollTop = 0
    this.ticking = false
  }

  handleScroll() {
    if (!this.ticking) {
      window.requestAnimationFrame(() => {
        this.updateNav()
        this.ticking = false
      })
      this.ticking = true
    }
  }

  updateNav() {
    const st = window.pageYOffset || document.documentElement.scrollTop
    
    // Safety check for bouncing
    if (st < 0) return 

    // If scrolling DOWN and past the top section
    if (st > this.lastScrollTop && st > 100) {
      // Hide navbar
      this.element.classList.remove("translate-y-0")
      this.element.classList.add("-translate-y-full")
    } else {
      // Show navbar
      this.element.classList.remove("-translate-y-full")
      this.element.classList.add("translate-y-0")
    }

    this.lastScrollTop = st
  }
}
