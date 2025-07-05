import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "prompt", "loadingSpinner", "error", "form"]
  static values = { 
    titleTarget: String,
    blurbTarget: String,
    instructionsTarget: String,
    tagsTarget: String,
    costTarget: String,
    difficultyTarget: String,
    prepTimeTarget: String,
    slugTarget: String,
    imagePreviewTarget: String
  }

  connect() {
    this.generateUrl = "/recipes/generate_with_ai"
  }

  openModal() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    this.clearError()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    this.promptTarget.value = ""
    this.clearError()
  }

  async generateRecipe() {
    const prompt = this.promptTarget.value.trim()
    
    if (!prompt) {
      this.showError("Please enter a recipe prompt")
      return
    }

    this.showLoading()
    this.clearError()

    try {
      const response = await fetch(this.generateUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt: prompt })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || "Failed to generate recipe")
      }

      const recipeData = await response.json()
      this.populateForm(recipeData)
      this.closeModal()
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.hideLoading()
    }
  }

  populateForm(recipeData) {
    // Get form elements
    const titleInput = document.querySelector('input[name="recipe[title]"]')
    const blurbTextarea = document.querySelector('textarea[name="recipe[blurb]"]')
    const instructionsEditor = document.querySelector('trix-editor[input="recipe_instructions"]')
    const tagsInput = document.querySelector('input[name="recipe[tag_names]"]')
    const costInput = document.querySelector('input[name="recipe[cost]"]')
    const difficultySelect = document.querySelector('select[name="recipe[difficulty]"]')
    const prepTimeInput = document.querySelector('input[name="recipe[prep_time]"]')
    const slugInput = document.querySelector('input[name="recipe[slug]"]')
    const categorySelect = document.querySelector('select[name="recipe[category_id]"]')
    const imagePreview = document.querySelector('#generated-image-preview')
    const imageContainer = document.querySelector('#generated-image-container')

    // Populate form fields
    if (titleInput) titleInput.value = recipeData.title || ""
    if (blurbTextarea) blurbTextarea.value = recipeData.blurb || ""
    if (instructionsEditor) instructionsEditor.value = recipeData.instructions || ""
    if (tagsInput) tagsInput.value = recipeData.tag_names || ""
    if (costInput) costInput.value = recipeData.cost || ""
    if (difficultySelect) difficultySelect.value = recipeData.difficulty || ""
    if (prepTimeInput) prepTimeInput.value = recipeData.prep_time || ""
    if (slugInput) slugInput.value = recipeData.slug || ""

    // Try to smart-select category based on generated content
    if (categorySelect && recipeData.suggested_category_id) {
      categorySelect.value = recipeData.suggested_category_id
    }

    // Show generated image preview if available
    if (recipeData.image_url) {
      if (imagePreview) {
        imagePreview.src = recipeData.image_url
        imagePreview.classList.remove("hidden")
      }
      if (imageContainer) {
        imageContainer.classList.remove("hidden")
      }
      
      // Store the image URL for later use
      this.generatedImageUrl = recipeData.image_url
    }

    // Trigger slug generation event if needed
    if (titleInput) {
      titleInput.dispatchEvent(new Event('input'))
    }

    // Show a success message
    this.showSuccessMessage("Recipe generated successfully! You can now review and edit the details before saving.")
  }

  showLoading() {
    this.loadingSpinnerTarget.classList.remove("hidden")
  }

  hideLoading() {
    this.loadingSpinnerTarget.classList.add("hidden")
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearError() {
    this.errorTarget.classList.add("hidden")
    this.errorTarget.textContent = ""
  }

  showSuccessMessage(message) {
    // Create a temporary success message
    const successDiv = document.createElement('div')
    successDiv.className = 'fixed top-4 right-4 bg-green-50 border border-green-200 rounded-md p-4 z-50'
    successDiv.innerHTML = `
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-green-800">${message}</p>
        </div>
        <div class="ml-auto pl-3">
          <div class="-mx-1.5 -my-1.5">
            <button type="button" class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600" onclick="this.parentElement.parentElement.parentElement.parentElement.remove()">
              <span class="sr-only">Dismiss</span>
              <svg class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    `
    document.body.appendChild(successDiv)

    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (successDiv.parentElement) {
        successDiv.remove()
      }
    }, 5000)
  }

  // Handle clicking outside modal to close
  handleBackdropClick(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }
}