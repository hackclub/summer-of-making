import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "label"]
  static values = { 
    criterion: String,
    labels: Array
  }

  connect() {
    this.selectedRating = 0
  }

  selectRating(event) {
    const value = parseInt(event.currentTarget.dataset.value)
    this.selectedRating = value
    
    const hiddenInput = this.element.querySelector('input[type="hidden"]')
    hiddenInput.value = this.labelsValue[value - 1]
    
    this.starTargets.forEach((star, index) => {
      const starSpan = star.querySelector('span')
      if (index < value) {
        starSpan.classList.remove('text-gray-300')
        starSpan.classList.add('text-yellow-400')
      } else {
        starSpan.classList.remove('text-yellow-400')
        starSpan.classList.add('text-gray-300')
      }
    })
    
    this.labelTarget.textContent = this.labelsValue[value - 1]
  }

  hoverRating(event) {
    const value = parseInt(event.currentTarget.dataset.value)
    
    this.starTargets.forEach((star, index) => {
      const starSpan = star.querySelector('span')
      if (index < value) {
        starSpan.classList.add('opacity-70')
      } else {
        starSpan.classList.remove('opacity-70')
      }
    })
  }

  leaveRating() {
    this.starTargets.forEach(star => {
      const starSpan = star.querySelector('span')
      starSpan.classList.remove('opacity-70')
    })
  }
}
