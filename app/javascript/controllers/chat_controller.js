import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "submit", "form", "emptyState"]

  connect() {
    this.observeMessages()
    this.scrollToBottom()
  }

  send(event) {
    const content = this.inputTarget.value.trim()
    if (!content) {
      event.preventDefault()
      return
    }

    // Let Turbo handle the form submission naturally.
    // Clear UI after a tick so the form data is captured first.
    this.submitTarget.disabled = true

    setTimeout(() => {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"

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
