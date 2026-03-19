import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="account-dropdown"
export default class extends Controller {
  static targets = ["button", "menu"];

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this);
    this.boundKeydown = this.keydown.bind(this);

    document.addEventListener("click", this.boundClickOutside);
    document.addEventListener("keydown", this.boundKeydown);

    this.close();
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside);
    document.removeEventListener("keydown", this.boundKeydown);
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();

    if (this.opened) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden");
    this.buttonTarget.setAttribute("aria-expanded", "true");
  }

  close() {
    this.menuTarget.classList.add("hidden");
    this.buttonTarget.setAttribute("aria-expanded", "false");
  }

  clickOutside(event) {
    if (!this.opened || this.element.contains(event.target)) return;

    this.close();
  }

  keydown(event) {
    if (!this.opened || event.key !== "Escape") return;

    this.close();
    this.buttonTarget.focus();
  }

  get opened() {
    return !this.menuTarget.classList.contains("hidden");
  }
}
