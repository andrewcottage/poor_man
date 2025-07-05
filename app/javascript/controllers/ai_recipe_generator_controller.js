import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "form", "prompt", "loading", "error"];
  static values = { 
    generateUrl: String,
    categoriesUrl: String 
  };

  connect() {
    this.hideModal();
  }

  showModal() {
    this.modalTarget.classList.remove("hidden");
    this.modalTarget.classList.add("flex");
    this.promptTarget.focus();
  }

  hideModal() {
    this.modalTarget.classList.add("hidden");
    this.modalTarget.classList.remove("flex");
    this.clearError();
  }

  async generateRecipe(event) {
    event.preventDefault();
    
    const prompt = this.promptTarget.value.trim();
    if (!prompt) {
      this.showError("Please enter a recipe prompt");
      return;
    }

    this.showLoading();
    this.clearError();

    try {
      const response = await fetch(this.generateUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt: prompt })
      });

      const data = await response.json();

      if (response.ok) {
        this.populateForm(data);
        this.hideModal();
      } else {
        this.showError(data.error || "Failed to generate recipe");
      }
    } catch (error) {
      this.showError("Network error. Please try again.");
      console.error("AI Generation Error:", error);
    } finally {
      this.hideLoading();
    }
  }

  populateForm(recipeData) {
    const form = document.querySelector("#recipe-form");
    if (!form) return;

    // Populate form fields
    this.setFieldValue(form, "recipe[title]", recipeData.title);
    this.setFieldValue(form, "recipe[blurb]", recipeData.blurb);
    this.setFieldValue(form, "recipe[tag_names]", recipeData.tag_names);
    this.setFieldValue(form, "recipe[difficulty]", recipeData.difficulty);
    this.setFieldValue(form, "recipe[prep_time]", recipeData.prep_time);
    this.setFieldValue(form, "recipe[cost]", recipeData.cost);
    this.setFieldValue(form, "recipe[category_id]", recipeData.category_id);

    // Handle rich text editor (Trix)
    const instructionsField = form.querySelector('[name="recipe[instructions]"]');
    if (instructionsField && instructionsField.editor) {
      instructionsField.editor.loadHTML(recipeData.instructions);
    }

    // Trigger slug generation
    const titleField = form.querySelector('[name="recipe[title]"]');
    if (titleField) {
      titleField.dispatchEvent(new Event('input', { bubbles: true }));
    }

    // Show success message
    this.showSuccessMessage("Recipe generated successfully! You can now edit the fields and add an image.");
  }

  setFieldValue(form, fieldName, value) {
    const field = form.querySelector(`[name="${fieldName}"]`);
    if (field && value !== undefined && value !== null) {
      field.value = value;
    }
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden");
    this.formTarget.classList.add("hidden");
  }

  hideLoading() {
    this.loadingTarget.classList.add("hidden");
    this.formTarget.classList.remove("hidden");
  }

  showError(message) {
    this.errorTarget.textContent = message;
    this.errorTarget.classList.remove("hidden");
  }

  clearError() {
    this.errorTarget.classList.add("hidden");
  }

  showSuccessMessage(message) {
    const existingMessage = document.querySelector("#ai-success-message");
    if (existingMessage) {
      existingMessage.remove();
    }

    const successDiv = document.createElement("div");
    successDiv.id = "ai-success-message";
    successDiv.className = "bg-green-50 text-green-500 px-3 py-2 font-medium rounded-lg mt-3";
    successDiv.textContent = message;

    const formContainer = document.querySelector("#recipe-form").parentElement;
    formContainer.insertBefore(successDiv, document.querySelector("#recipe-form"));

    setTimeout(() => {
      successDiv.remove();
    }, 5000);
  }
}