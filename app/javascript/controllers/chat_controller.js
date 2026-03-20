import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "submit", "form", "emptyState", "attachmentsInput", "attachmentPreview"]

  connect() {
    this.observeMessages()
    this.scrollToBottom()
  }

  send(event) {
    const content = this.inputTarget.value.trim()
    const hasAttachments = this.hasAttachmentsInputTarget && this.attachmentsInputTarget.files.length > 0

    if (!content && !hasAttachments) {
      event.preventDefault()
      return
    }

    // Let Turbo handle the form submission naturally.
    // Clear UI after a tick so the form data is captured first.
    this.submitTarget.disabled = true

    setTimeout(() => {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"
      if (this.hasAttachmentsInputTarget) {
        this.attachmentsInputTarget.value = ""
      }
      if (this.hasAttachmentPreviewTarget) {
        this.attachmentPreviewTarget.innerHTML = ""
        this.attachmentPreviewTarget.classList.add("hidden")
      }

      if (this.hasEmptyStateTarget) {
        this.emptyStateTarget.remove()
      }
    }, 0)
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 160) + "px"
  }

  fillSuggestion(event) {
    const suggestion = event.currentTarget.dataset.suggestion
    this.inputTarget.value = suggestion
    this.inputTarget.focus()
  }

  openFilePicker() {
    if (this.hasAttachmentsInputTarget) {
      this.attachmentsInputTarget.click()
    }
  }

  previewAttachments() {
    if (!this.hasAttachmentsInputTarget || !this.hasAttachmentPreviewTarget) return

    const files = Array.from(this.attachmentsInputTarget.files || [])
    this.attachmentPreviewTarget.innerHTML = ""

    if (files.length === 0) {
      this.attachmentPreviewTarget.classList.add("hidden")
      return
    }

    this.attachmentPreviewTarget.classList.remove("hidden")

    files.slice(0, 3).forEach((file) => {
      const wrapper = document.createElement("div")
      wrapper.className = "relative h-20 w-20 overflow-hidden rounded-2xl border border-stone-200 bg-stone-100 shadow-sm"

      const image = document.createElement("img")
      image.className = "h-full w-full object-cover"
      image.alt = file.name
      image.src = URL.createObjectURL(file)
      image.onload = () => URL.revokeObjectURL(image.src)

      wrapper.appendChild(image)
      this.attachmentPreviewTarget.appendChild(wrapper)
    })
  }

  // Private

  observeMessages() {
    if (!this.hasMessagesTarget) return

    const observer = new MutationObserver(() => {
      this.scrollToBottom()
      this.enableInput()
    })

    observer.observe(this.messagesTarget, { childList: true, subtree: true })
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return

    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }

  enableInput() {
    if (!document.getElementById("chat_thinking")) {
      this.submitTarget.disabled = false
      this.inputTarget.focus()
    }
  }
}
