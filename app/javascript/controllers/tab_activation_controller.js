import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]
  static classes = ["active", "inactive"]

  activate(event) {
    // Immediate visual feedback
    this.tabTargets.forEach(tab => {
      // Remove active classes
      this.activeClasses.forEach(c => tab.classList.remove(c))
      // Add inactive classes
      this.inactiveClasses.forEach(c => tab.classList.add(c))
    })

    const selectedTab = event.currentTarget
    // Remove inactive classes from selected
    this.inactiveClasses.forEach(c => selectedTab.classList.remove(c))
    // Add active classes to selected
    this.activeClasses.forEach(c => selectedTab.classList.add(c))
  }
}
