import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "form"]
  static values = {
    loadingText: { type: String, default: "Processing..." },
    isConfirming: { type: Boolean, default: false }
  }

  connect() {
    this.submitting = false
    this.originalButtonText = null
  }

  disconnect() {
    if (this.submitting) {
      this.resetButton()
    }
  }

  validateAndPreventDoubleSubmission(event) {
    const attachmentField = this.element.querySelector('input[name="devlog[attachment]"]')
    if (attachmentField && (!attachmentField.value || attachmentField.value.trim() === '')) {
      event.preventDefault()
      alert('Please attach an attachment before posting your devlog.')
      return
    }
    
    this.preventDoubleSubmission(event)
  }

  preventDoubleSubmission(event) {
    if (this.submitting) {
      event.preventDefault()
      return
    }
    
    this.submitting = true
    this.disableSubmitButton()

    const turboDisabled = this.element.dataset.turbo === 'false'
    
    if (!turboDisabled) {
      this.element.addEventListener("turbo:submit-end", () => {
        this.resetButton()
        this.element.reset() 
      }, { once: true })
    }
  }

  disableSubmitButton() {
    try {
      const button = this.submitButtonTarget
      
      button.innerHTML = `
        <div class="inline-flex items-center">
          <span>${this.loadingTextValue}</span>
        </div>
      `
      button.disabled = true
      button.classList.add('opacity-75', 'cursor-not-allowed')
    } catch (error) {
      console.error('Error disabling submit button:', error)
      this.resetButton()
    }
  }

  resetButton() {
    try {
      const button = this.submitButtonTarget
      if (this.originalButtonText) {
        button.innerHTML = this.originalButtonText
      }
      button.disabled = false
      button.classList.remove('opacity-75', 'cursor-not-allowed', 'bg-vintage-red')
      this.submitting = false
      this.isConfirming = false
    } catch (error) {
      console.error('Error resetting button:', error)
    }
  }
} 