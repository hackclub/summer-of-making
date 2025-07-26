import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "video", "closeButton"]

  connect() {
    if (this.videoTarget) {
      this.videoTarget.play()
    }
    
    this.setupEventListeners()
  }

  disconnect() {
    if (this.videoTarget) {
      this.videoTarget.pause()
    }
    
    this.removeEventListeners()
  }

  setupEventListeners() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)

    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  removeEventListeners() {
    if (this.boundHandleKeydown) {
      document.removeEventListener("keydown", this.boundHandleKeydown)
    }
  }

  close() {
    this.stopVideo()
    this.hideModal()
    this.markVideoAsSeen()
  }

  closeOnVideoEnd() {
    this.close()
  }

  closeOnBackgroundClick(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.modalTarget.style.display !== "none") {
      this.close()
    }
  }

  stopVideo() {
    if (this.videoTarget) {
      this.videoTarget.pause()
      this.videoTarget.currentTime = 0
    }
  }

  hideModal() {
    this.modalTarget.style.display = "none"
  }

  markVideoAsSeen() {
    fetch(window.location.pathname + "?mark_video_seen=true", {
      method: "GET",
      headers: {
        "X-Requested-With": "XMLHttpRequest"
      }
    }).then(() => {
    }).catch(error => {
      console.error("Error marking video as seen:", error)
    })
  }
}
