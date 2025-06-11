import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "container", "iframe"];

  connect() {
    this.escape = this.escape.bind(this);
  }

  disconnect() {
    this.close();
  }

  open(event) {
    event.preventDefault();
    this.modalTarget.classList.remove("hidden");
    if (this.hasIframeTarget) {
      this.iframeTarget.src =
        "https://streamable.com/e/ay62z2?autoplay=1&loop=0";
    }
    this.modalTarget.style.opacity = "0";
    this.containerTarget.style.transform = "scale(0.9)";
    this.containerTarget.style.opacity = "0";
    this.modalTarget.offsetHeight;
    setTimeout(() => {
      this.modalTarget.style.transition = "opacity 250ms ease-out";
      this.containerTarget.style.transition = "all 250ms ease-out";
      this.modalTarget.style.opacity = "1";
      this.containerTarget.style.transform = "scale(1)";
      this.containerTarget.style.opacity = "1";
    }, 10);

    document.addEventListener("keydown", this.escape);
    document.body.style.overflow = "hidden";
  }

  close() {
    this.modalTarget.style.transition = "opacity 250ms ease-in";
    this.containerTarget.style.transition = "all 250ms ease-in";
    this.modalTarget.style.opacity = "0";
    this.containerTarget.style.transform = "scale(0.9)";
    this.containerTarget.style.opacity = "0";

    setTimeout(() => {
      this.modalTarget.classList.add("hidden");
      this.modalTarget.style.transition = "";
      this.containerTarget.style.transition = "";
      this.containerTarget.style.transform = "";
      if (this.hasIframeTarget) {
        this.iframeTarget.src = "";
      }
    }, 250);

    document.removeEventListener("keydown", this.escape);
    document.body.style.overflow = "auto";
  }

  closeBackground(event) {
    if (
      event.target === event.currentTarget ||
      !this.containerTarget.contains(event.target)
    ) {
      this.close();
    }
  }

  escape(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }
}
