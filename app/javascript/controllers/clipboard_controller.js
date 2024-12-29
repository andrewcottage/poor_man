import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="clipboard"
export default class extends Controller {
  connect() {}

  static targets = ["link"];

  share(event) {
    event.preventDefault();
    const link = this.linkTarget.href;
    const pageTitle = document.title;
    const pageDescription = document.querySelector('meta[name="description"]');

    if (navigator.share) {
      navigator
        .share({
          title: pageTitle,
          text: pageDescription ? pageDescription.content : "",
          url: link
        })
        .then(() => console.log("Successfully shared"))
        .catch((error) => console.error("Error sharing", error));
    } else {
      // Fallback for browsers without Web Share API
      navigator.clipboard
        .writeText(link)
        .then(() => {
          alert("Link copied to clipboard! Share it manually.");
        })
        .catch((err) => {
          console.error("Failed to copy link: ", err);
        });
    }
  }
}
