import LazyListController from "./lazy_list_controller";

export default class extends LazyListController {
  static targets = ["select", "item", "sentinel", "empty"];
  static values = {
    batchSize: { type: Number, default: 4 },
  };

  connect() {
    super.connect();
    this.applyFilter();
  }

  filter() {
    this.applyFilter();
  }

  applyFilter() {
    const selectedId = this.hasSelectTarget ? this.selectTarget.value : "";
    const scopedItems = this.itemTargets.filter(
      (item) => selectedId === "" || item.dataset.roadmapId === selectedId
    );
    this.setScope(scopedItems);
  }
}
