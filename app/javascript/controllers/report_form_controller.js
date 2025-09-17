import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lowEffortInfo"]

  connect() {
    this.update()
  }

  update() {
    const selected = this.element.querySelector('input[name="report_kind"]:checked')
    const isLowEffort = selected && selected.value === 'low_quality'
    if (this.hasLowEffortInfoTarget) {
      this.lowEffortInfoTarget.classList.toggle('hidden', !isLowEffort)
    }
  }
}


