import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["todayTime", "totalTime", "noDataAlert"]
  static values = { 
    updateInterval: { type: Number, default: 30000 } // 30 seconds
  }

  connect() {
    this._onVisibilityChange = this.onVisibilityChange?.bind(this) || (() => {})
    document.addEventListener('visibilitychange', this._onVisibilityChange)
    if (!document.hidden) this.startPolling()
  }

  disconnect() {
    document.removeEventListener('visibilitychange', this._onVisibilityChange)
    this.stopPolling()
  }

  startPolling() {
    if (this.pollInterval) return
    this.updateDashboard()
    this.pollInterval = setInterval(() => this.updateDashboard(), this.updateIntervalValue)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
    this.abortInFlight()
  }

  updateDashboard() {
    this.abortInFlight()
    this._abortController = new AbortController()
    fetch('/campfire/hackatime_status', { signal: this._abortController.signal })
      .then(response => response.json())
      .then(data => {
        if (data.dashboard) {
          if (this.hasTodayTimeTarget) {
            this.todayTimeTarget.textContent = data.dashboard.today_time_formatted
          }
          
          if (this.hasTotalTimeTarget) {
            this.totalTimeTarget.textContent = data.dashboard.total_time_formatted
          }
          
          if (this.hasNoDataAlertTarget) {
            if (data.dashboard.has_time_recorded) {
              this.noDataAlertTarget.style.display = 'none'
            } else {
              this.noDataAlertTarget.style.display = 'block'
            }
          }
        }
      })
      .catch(error => {
        console.log('Dashboard update failed:', error)
      })
  }

  refresh() {
    this.updateDashboard()
  }

  onVisibilityChange() {
    if (document.hidden) {
      this.stopPolling()
    } else {
      this.startPolling()
    }
  }

  abortInFlight() {
    try { this._abortController?.abort() } catch (_) {}
    this._abortController = null
  }
} 