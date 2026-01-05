import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["item", "sentinel", "empty"];
  static values = {
    batchSize: { type: Number, default: 6 },
  };

  initialize() {
    this.visibleCount = 0;
    this.currentScope = [];
  }

  connect() {
    this.setScope(this.itemTargets);
    this.setupObserver();
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  setScope(items = []) {
    this.currentScope = items;
    this.visibleCount = 0;
    this.itemTargets.forEach((item) => item.classList.add("hidden"));
    this.loadNextBatch();
    this.toggleEmptyState();
    this.toggleSentinel();
  }

  loadMore() {
    if (!this.hasMore()) return;
    this.loadNextBatch();
    this.toggleSentinel();
  }

  hasMore() {
    return this.visibleCount < this.currentScope.length;
  }

  loadNextBatch() {
    const nextItems = this.currentScope.slice(
      this.visibleCount,
      this.visibleCount + this.batchSizeValue
    );
    nextItems.forEach((item) => item.classList.remove("hidden"));
    this.visibleCount += nextItems.length;
  }

  toggleEmptyState() {
    if (!this.hasEmptyTarget) return;
    const isEmpty = this.currentScope.length === 0;
    this.emptyTarget.classList.toggle("hidden", !isEmpty);
  }

  toggleSentinel() {
    if (!this.hasSentinelTarget) return;
    this.sentinelTarget.classList.toggle("hidden", !this.hasMore());
  }

  setupObserver() {
    if (!this.hasSentinelTarget) return;
    this.observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        this.loadMore();
      }
    });
    this.observer.observe(this.sentinelTarget);
  }
}
