import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggle", "loading"]
  static values = { 
    shipEventId: Number,
    loaded: Boolean 
  }

  connect() {
    this.loadedValue = false
  }

  toggle() {
    if (this.contentTarget.classList.contains("hidden")) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  async expand() {
    this.contentTarget.classList.remove("hidden")
    this.toggleTarget.textContent = "Hide AI Feedback"
    
    if (!this.loadedValue) {
      await this.loadFeedback()
    }
  }

  collapse() {
    this.contentTarget.classList.add("hidden")
    this.toggleTarget.textContent = "Show AI Feedback"
  }

  async loadFeedback() {
    this.loadingTarget.classList.remove("hidden")
    
    try {
      const response = await fetch(`/ship_events/${this.shipEventIdValue}/feedback`)
      const data = await response.json()
      
      if (response.ok) {
        this.contentTarget.innerHTML = this.formatFeedback(data.feedback)
        this.loadedValue = true
      } else {
        this.contentTarget.innerHTML = `<p class="text-som-detail">No feedback available yet.</p>`
      }
    } catch (error) {
      console.error("Failed to load feedback:", error)
      this.contentTarget.innerHTML = `<p class="bg-[#FFBABA] text-som-dark p-2 rounded text-sm">Failed to load feedback.</p>`
    } finally {
      this.loadingTarget.classList.add("hidden")
    }
  }

  async regenerate() {
    if (!confirm("Are you sure you want to regenerate the AI feedback? This will overwrite the existing feedback.")) {
      return
    }

    this.loadingTarget.classList.remove("hidden")
    this.contentTarget.innerHTML = ""

    try {
      const response = await fetch(`/admin/ship_events/${this.shipEventIdValue}/regenerate_feedback`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
      
      const data = await response.json()
      
      if (response.ok && data.success) {
        this.contentTarget.innerHTML = this.formatFeedback(data.feedback)
        this.loadedValue = true
        
        const successMsg = document.createElement('div')
        successMsg.className = 'mb-3 p-2 bg-[#B8FFC2] text-som-dark text-sm rounded'
        successMsg.textContent = 'Feedback regenerated successfully!'
        this.contentTarget.insertBefore(successMsg, this.contentTarget.firstChild)
        
        setTimeout(() => successMsg.remove(), 3000)
      } else {
        this.contentTarget.innerHTML = `<p class="bg-[#FFBABA] text-som-dark p-2 rounded text-sm">Failed to regenerate feedback: ${data.message || 'Unknown error'}</p>`
      }
    } catch (error) {
      console.error("Failed to regenerate feedback:", error)
      this.contentTarget.innerHTML = `<p class="bg-[#FFBABA] text-som-dark p-2 rounded text-sm">Failed to regenerate feedback.</p>`
    } finally {
      this.loadingTarget.classList.add("hidden")
    }
  }

  formatFeedback(feedback) {
    return `<div class="prose max-w-none text-som-dark">${this.escapeHtml(feedback).replace(/\n/g, '<br>')}</div>`
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}