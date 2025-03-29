import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="account-dropdown"
export default class extends Controller {
  static targets = ["menu"];

  connect() {
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden");
  }
}
