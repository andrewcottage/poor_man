import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="account-dropdown"
export default class extends Controller {
  static targets = ["menu"];

  connect() {
    console.log("Account dropdown controller connected");
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden");
  }
}
