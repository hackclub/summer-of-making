import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timeOnTab", "timeOffTab"]

  connect() {
    this.startTime = Date.now()
    this.timeOnTab = 0
    this.timeOffTab = 0
    this.isVisible = !document.hidden
    this.lastVisibilityChange = Date.now()

    document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this))

    window.addEventListener('blur', this.handleBlur.bind(this))
    window.addEventListener('focus', this.handleFocus.bind(this))

    window.addEventListener('beforeunload', this.handleBeforeUnload.bind(this))
  }

  disconnect() {
    document.removeEventListener('visibilitychange', this.handleVisibilityChange.bind(this))
    window.removeEventListener('blur', this.handleBlur.bind(this))
    window.removeEventListener('focus', this.handleFocus.bind(this))
    window.removeEventListener('beforeunload', this.handleBeforeUnload.bind(this))

    this.updateTimeTracking()
  }

  handleVisibilityChange() {
    this.updateTimeTracking()
    this.isVisible = !document.hidden
    this.lastVisibilityChange = Date.now()
  }

  handleBlur() {
    if (this.isVisible) {
      this.updateTimeTracking()
      this.isVisible = false
      this.lastVisibilityChange = Date.now()
    }
  }

  handleFocus() {
    if (!this.isVisible) {
      this.updateTimeTracking()
      this.isVisible = true
      this.lastVisibilityChange = Date.now()
    }
  }

  updateTimeTracking() {
    const now = Date.now()
    const timeSinceLastChange = now - this.lastVisibilityChange

    if (this.isVisible) {
      this.timeOnTab += timeSinceLastChange
    } else {
      this.timeOffTab += timeSinceLastChange
    }

    this.lastVisibilityChange = now
  }

  handleBeforeUnload() {
    this.updateTimeTracking()
    this.updateHiddenFields()
  }

  updateHiddenFields() {
    if (this.hasTimeOnTabTarget) {
      this.timeOnTabTarget.value = Math.round(this.timeOnTab)
    }
    if (this.hasTimeOffTabTarget) {
      this.timeOffTabTarget.value = Math.round(this.timeOffTab)
    }
  }

  prepareForSubmission() {
    this.updateTimeTracking()
    this.updateHiddenFields()
  }

  get timeOnTabValue() {
    this.updateTimeTracking()
    return Math.round(this.timeOnTab)
  }

  get timeOffTabValue() {
    this.updateTimeTracking()
    return Math.round(this.timeOffTab)
  }
}