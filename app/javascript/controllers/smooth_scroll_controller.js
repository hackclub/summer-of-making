import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.links = this.element.querySelectorAll('a[href^="#"]');
    this.links.forEach((l) => {
      l.addEventListener("click", this.scroll.bind(this));
    });
  }

  scroll(e) {
    const id = e.currentTarget.getAttribute("href");
    const el = document.querySelector(id);

    if (el) {
      e.preventDefault();
      el.scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
      window.history.pushState(null, null, id);
    }
  }

  disconnect() {
    this.links.forEach((l) => {
      l.removeEventListener("click", this.scroll);
    });
  }
}
