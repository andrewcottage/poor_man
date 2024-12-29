import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="clipboard"
export default class extends Controller {
  connect() {}

  static targets = ["link"];

  copy(event) {
    event.preventDefault();
    const link = this.linkTarget.href;

    navigator.clipboard
      .writeText(link)
      .then(() => {
        alert("Copied Link!");
      })
      .catch((err) => {
        console.error("Failed to copy link: ", err);
      });
  }
}
