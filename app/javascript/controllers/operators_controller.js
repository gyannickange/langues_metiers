// app/javascript/controllers/operators_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["country", "list"];

  updateList() {
    const country = this.countryTarget.value;
    const url = this.data.get("url") || "/mobile_operators";
    fetch(`${url}?country=${country}`, {
      headers: { Accept: "text/html" },
    })
      .then((r) => r.text())
      .then((html) => {
        this.listTarget.innerHTML = html;
      });
  }
}
