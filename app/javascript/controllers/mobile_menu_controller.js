// app/javascript/controllers/mobile_menu_controller.js
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["menu"];

  connect() {
  }

  toggle() {
    console.log("Toggling mobile menu");
    this.menuTarget.classList.toggle("hidden");
  }
}
