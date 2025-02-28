import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mainImage", "thumbnail"];

  connect() {
    this.currentIndex = 0;
    this.showImage(this.currentIndex);
  }

  previous() {
    this.currentIndex =
      (this.currentIndex - 1 + this.mainImageTargets.length) %
      this.mainImageTargets.length;
    this.showImage(this.currentIndex);
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.mainImageTargets.length;
    this.showImage(this.currentIndex);
  }

  select(event) {
    this.currentIndex = parseInt(event.currentTarget.dataset.index);
    this.showImage(this.currentIndex);
  }

  showImage(index) {
    this.mainImageTargets.forEach((image, i) => {
      image.classList.toggle("hidden", i !== index);
    });
  }
}
