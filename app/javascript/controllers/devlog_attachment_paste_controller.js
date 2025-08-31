import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["devlogText", "fileInput"]

  connect() {
    if (this.hasDevlogTextTarget && this.hasFileInputTarget) {
      this.devlogTextTarget.addEventListener("paste", this.handlePaste.bind(this))
    }
  }

  handlePaste(event) {
    if (event.clipboardData && event.clipboardData.files && event.clipboardData.files.length > 0) {
      const file = event.clipboardData.files[0]
      if (this.isValidFileType(file)) {
        this.fileInputTarget.files = this.fileListFromFile(file)
        this.fileInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
      } else {
        alert('Only images, audio, and video files are allowed.')
      }
    }
  }

  isValidFileType(file) {
    const validTypes = ['image/', 'video/', 'audio/']
    return validTypes.some(type => file.type.startsWith(type))
  }

  fileListFromFile(file) {
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    return dataTransfer.files
  }
}
