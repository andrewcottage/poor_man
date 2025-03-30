import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "slug"];

  generateSlug() {
    const title = this.titleTarget.value;
    const slug = title
      .toLowerCase()
      .trim()
      .replace(/[^\w\s-]/g, "") // Remove special characters
      .replace(/\s+/g, "-"); // Replace spaces with -

    this.slugTarget.value = slug;
  }
}
