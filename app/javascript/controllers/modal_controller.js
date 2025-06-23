import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    type: String
  }

  connect() {
    this.escapeHandler = this.escapeHandler.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
    
    this.clickOutsideHandler = this.clickOutsideHandler.bind(this)
    this.element.addEventListener("click", this.clickOutsideHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
    this.element.removeEventListener("click", this.clickOutsideHandler)
  }

  open(event) {
    const button = event.currentTarget
    const modalId = button.dataset.modalId
    const modalType = button.dataset.modalType || 'generic'

    let modalElement

    if (modalType === 'create-project') {
      modalElement = document.getElementById('create-project-modal')
    } else if (modalType === 'hackatime') {
      modalElement = document.getElementById('hackatime-modal')
    } else {
      if (!modalId) {
        console.error("No modalId provided")
        return
      }
    }
    
    switch (modalType) {
      case 'edit':
        modalElement = document.getElementById(`edit-modal-${modalId}`)
        break
      case 'comment':
        modalElement = document.getElementById(`comment-modal-${modalId}`)
        break
      case 'follower':
        modalElement = document.getElementById(`follower-modal-${modalId}`)
        break
      case 'is_shipped':
        modalElement = document.getElementById(`ship-modal-${modalId}`)
        break
      case 'timer':
        modalElement = document.getElementById(`timer-modal-${modalId}`)
        break
      case 'stonks':
        modalElement = document.getElementById(`stonks-modal-${modalId}`)
        break
      case 'delete':
        modalElement = document.getElementById(`delete-modal-${modalId}`)
        break
      case 'certification':
        modalElement = document.getElementById(`certification-modal-${modalId}`)
        break
    }
    
    if (!modalElement) {
      return
    }
    modalElement.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    if (modalElement.dataset) {
      modalElement.dataset.openModalType = modalType
    }
    
    setTimeout(() => {
      const firstInput = modalElement.querySelector("input, textarea")
      if (firstInput) firstInput.focus()
    }, 100)
  }

  close() {
    this.element.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    
    // Check if this is the hackatime modal and set localStorage
    if (this.element.id === 'hackatime-modal') {
      localStorage.setItem('hasSkippedHackatimeModal', 'true')
    }
  }

  escapeHandler(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      if (this.element.id && (
          this.element.id.startsWith('edit-modal-') || 
          this.element.id.startsWith('comment-modal-') || 
          this.element.id.startsWith('follower-modal-') || 
          this.element.id.startsWith('ship-modal-') ||
          this.element.id.startsWith('timer-modal-') || 
          this.element.id.startsWith('stonks-modal-') ||
          this.element.id.startsWith('delete-modal-') ||
          this.element.id.startsWith('certification-modal-') ||
          this.element.id === 'create-project-modal' ||
          this.element.id === 'hackatime-modal')) {
        this.close()
        event.stopPropagation()
      }
    }
  }

  clickOutsideHandler(event) {
    if (this.hasContainerTarget && 
        !this.containerTarget.contains(event.target) && 
        event.target === this.element) {
      this.close()
    }
  }
} 