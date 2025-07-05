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
    this.setFieldValue(form, "recipe[image_url]", recipeData.image);

    // Handle rich text editor (Trix) - improved approach
    this.populateTrixEditor(recipeData.instructions);

    // Show generated image preview and inject into form
    if (recipeData.image_url) {
      this.showImagePreview(recipeData.image_url);
      this.injectImageIntoForm(recipeData.image_url);
    }

    // Trigger slug generation
    const titleField = form.querySelector('[name="recipe[title]"]');
    if (titleField) {
      titleField.dispatchEvent(new Event('input', { bubbles: true }));
    }

    // Show success message
    this.showSuccessMessage("Recipe and image generated successfully! You can now edit the fields or save the recipe.");
  }

  populateTrixEditor(content) {
    // Try multiple approaches to find and populate the Trix editor
    const trixEditor = document.querySelector('trix-editor');
    
    if (trixEditor) {
      // Wait for the editor to be ready if it's not already
      if (trixEditor.editor) {
        trixEditor.editor.loadHTML(content);
      } else {
        // Wait for the editor to initialize
        trixEditor.addEventListener('trix-initialize', () => {
          trixEditor.editor.loadHTML(content);
        }, { once: true });
      }
    } else {
      // Fallback: try to find the hidden input field
      const hiddenInput = document.querySelector('input[name="recipe[instructions]"]');
      if (hiddenInput) {
        hiddenInput.value = content;
      }
    }
  }

  showImagePreview(imageUrl) {
    // Find the image upload field container
    const imageField = document.querySelector('input[type="file"][name="recipe[image]"]');
    if (!imageField) return;

    // Remove any existing preview
    const existingPreview = document.querySelector('#ai-generated-image-preview');
    if (existingPreview) {
      existingPreview.remove();
    }

    // Create preview container
    const previewContainer = document.createElement('div');
    previewContainer.id = 'ai-generated-image-preview';
    previewContainer.className = 'mt-3 p-3 border rounded-lg bg-green-50';

    // Create preview content
    previewContainer.innerHTML = `
      <div class="flex items-center space-x-3">
        <img src="${imageUrl}" alt="AI Generated Image" class="w-16 h-16 object-cover rounded">
        <div>
          <p class="text-sm font-medium text-green-800">✓ AI Generated Image Attached</p>
          <p class="text-xs text-green-600">This image has been added to the form and will be saved with the recipe</p>
        </div>
      </div>
    `;

    // Insert preview after the image field
    imageField.parentNode.appendChild(previewContainer);
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

  async injectImageIntoForm(imageUrl) {
    try {
      // Find the file input field
      const fileInput = document.querySelector('input[type="file"][name="recipe[image]"]');
      if (!fileInput) return;

      // Fetch the image
      const response = await fetch(imageUrl);
      const blob = await response.blob();
      
      // Create a File object from the blob
      const file = new File([blob], 'ai_generated_image.jpg', { 
        type: 'image/jpeg',
        lastModified: Date.now()
      });

      // Create a DataTransfer object to hold the file
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file);
      
      // Set the files property of the input
      fileInput.files = dataTransfer.files;
      
      // Trigger change event so the form knows a file was selected
      fileInput.dispatchEvent(new Event('change', { bubbles: true }));
      
      console.log('Image successfully injected into form');
    } catch (error) {
      console.error('Failed to inject image into form:', error);
    }
  }
}