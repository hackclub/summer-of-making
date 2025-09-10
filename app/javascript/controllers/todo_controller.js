import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["todoButton", "callout", "modal", "overlay"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.prefetchOnHover = this.prefetchOnHover.bind(this)

    if (this.hasTodoButtonTarget) {
      this.todoButtonTarget.addEventListener("mouseenter", this.prefetchOnHover)
      this.todoButtonTarget.addEventListener("touchstart", this.prefetchOnHover, { passive: true })
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
    if (this.hasTodoButtonTarget) {
      this.todoButtonTarget.removeEventListener("mouseenter", this.prefetchOnHover)
      this.todoButtonTarget.removeEventListener("touchstart", this.prefetchOnHover)
    }
  }

  async toggle() {
    if (this.modalTarget.style.display === "none" || this.modalTarget.style.display === "") {
      this.show()
      this.ensureLoaded()
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
        'Accept': 'application/json',
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

  async ensureLoaded() {
    if (this.modalLoaded) return
    const url = this.modalTarget.getAttribute('data-fetch-url')
    if (!url) { this.modalLoaded = true; return }
    try {
      if (!this.modalTarget.innerHTML || this.modalTarget.innerHTML.trim() === "") {
        const img = this.modalTarget.getAttribute('data-loading-img')
        const spinner = img ? `<img src="${img}" alt="Loading..." class="mx-auto my-6 h-12 w-12" />` : `<div class=\"animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-forest mx-auto my-6\"></div>`
        this.modalTarget.innerHTML = `
          <div class="p-6" style="background: radial-gradient(circle at 43.330392% 44.289383%, rgb(246, 219, 186), rgb(230, 212, 190));">
            <div class="flex items-center justify-between mb-4">
              <div class="flex flex-col">
                <h2 class="text-xl font-bold text-som-dark">Todo list:</h2>
                <p>Loading...</p>
              </div>
            </div>
            <div class="flex items-center justify-center py-2">
              ${spinner}
            </div>
          </div>`
      }
      const resp = await fetch(url, { headers: { 'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml' } })
      if (!resp.ok) throw new Error(`Failed to load todo modal: ${resp.status}`)
      const html = await resp.text()
      this.modalTarget.innerHTML = html
      this.modalLoaded = true
    } catch (e) {
      console.error(e)
      this.modalLoaded = true
    }
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

  prefetchOnHover() {
    this.ensureLoaded()
  }
}