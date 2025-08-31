import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["todoButton", "callout", "modal", "overlay"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  toggle() {
    if (this.modalTarget.style.display === "none" || this.modalTarget.style.display === "") {
      this.show()
    } else {
      this.close()
    }
  }

  toggleAndComplete() {
    if (this.hasOverlayTarget && this.overlayTarget.style.display !== "none") {
      this.completeTodoStep()
    }
    this.toggle()
  }

  completeAndHideOverlay() {
    this.completeTodoStep()
    this.toggle()
  }

  completeTodoStep() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    fetch('/tutorial/complete_soft_tutorial_step', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken || ''
      },
      body: JSON.stringify({ step_name: 'todo' })
    }).catch(error => {
      console.error('Error completing tutorial step:', error)
    })
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = 'none'
    }
  }

  show() {
    this.modalTarget.style.display = "block"
    // before animation
    setTimeout(() => {
      this.modalTarget.classList.remove("translate-x-full")
      this.modalTarget.classList.add("translate-x-0")
    }, 10)
    
    setTimeout(() => {
      document.addEventListener("click", this.handleOutsideClick)
    }, 100)
  }

  close() {
    this.modalTarget.classList.remove("translate-x-0")
    this.modalTarget.classList.add("translate-x-full")
    document.removeEventListener("click", this.handleOutsideClick)
    // after animation
    setTimeout(() => {
      this.modalTarget.style.display = "none"
    }, 300)
  }

  handleOutsideClick(event) {
    if (this.modalTarget.style.display === "none" || this.modalTarget.style.display === "") {
      return
    }
    
    if (!this.modalTarget.contains(event.target) && !this.todoButtonTarget.contains(event.target)) {
      this.close()
    }
  }
}