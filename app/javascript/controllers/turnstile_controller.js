import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.widgetId = null
    this._ensureScript().then(() => this._renderWidget()).catch(() => {
      this._showError("Verification failed to load. Please try again.")
    })
  }

  disconnect() {
    try {
      if (window.turnstile && this.widgetId !== null) {
        window.turnstile.remove(this.widgetId)
      }
    } catch (_) {}
  }

  reset() {
    try {
      if (window.turnstile) {
        if (this.widgetId !== null) {
          window.turnstile.reset(this.widgetId)
        } else {
          window.turnstile.reset()
        }
      }
    } catch (_) {}
  }

  _ensureScript() {
    return new Promise((resolve, reject) => {
      if (window.turnstile) return resolve()

      let existing = document.querySelector('script[data-turnstile-script="true"]')
      if (existing) {
        existing.addEventListener('load', () => resolve())
        existing.addEventListener('error', () => reject())
        return
      }

      const script = document.createElement('script')
      script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js'
      script.async = true
      script.defer = true
      script.setAttribute('data-turnstile-script', 'true')
      script.addEventListener('load', () => resolve())
      script.addEventListener('error', () => reject())
      document.head.appendChild(script)
    })
  }

  _renderWidget() {
    try {
      if (!window.turnstile) return
      const sitekey = this.element.dataset.sitekey
      this.widgetId = window.turnstile.render(this.element, {
        sitekey: sitekey,
        theme: this.element.dataset.theme || 'auto'
      })
    } catch (_) {
      this._showError("Verification failed to initialize. Please retry.")
    }
  }

  _showError(message) {
    const target = document.getElementById('turnstile-error')
    if (target) {
      target.innerHTML = `<div class="text-vintage-red text-sm mt-2">${message}</div>`
    }
  }
}


