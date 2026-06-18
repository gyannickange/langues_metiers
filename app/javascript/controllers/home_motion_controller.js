import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hero", "group"]

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.element.classList.add("home-motion-ready")
    this.observer = new IntersectionObserver(this.revealGroups.bind(this), {
      threshold: 0.18,
      rootMargin: "0px 0px -8% 0px"
    })

    this.groupTargets.forEach((group) => this.observer.observe(group))

    requestAnimationFrame(() => {
      this.heroTargets.forEach((item) => item.classList.add("is-visible"))
    })
  }

  disconnect() {
    this.observer?.disconnect()
    this.element.classList.remove("home-motion-ready")
  }

  revealGroups(entries) {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return

      entry.target.classList.add("is-visible")
      this.observer.unobserve(entry.target)
    })
  }
}
