import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["emailInput", "msg"];

  connect() {
    this.emailInputTarget.addEventListener("input", () => {
      this.hideError();
    });
  }

  startWizard() {
    const x = this.emailInputTarget.value.trim();

    this.hideError();

    if (!x) {
      this.error("pls enter your email");
      this.emailInputTarget.focus();
      return;
    }

    if (!this.isValidEmail(x)) {
      this.error("pls enter a valid email address");
      this.emailInputTarget.focus();
      return;
    }

    const y = document.getElementById("signup-wizard");
    if (y) {
      const z = this.application.getControllerForElementAndIdentifier(
        y,
        "signup-wizard"
      );
      if (z) {
        z.emailValue = x;
        z.initialize();
      }

      y.classList.remove("hidden");
      document.body.classList.add("overflow-hidden");
    }
  }

  isValidEmail(a) {
    const b = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return b.test(a);
  }

  error(message) {
    if (this.hasMsgTarget) {
      this.msgTarget.textContent = message;
      this.msgTarget.classList.remove("hidden");
    }
  }

  hideError() {
    if (this.hasMsgTarget) {
      this.msgTarget.classList.add("hidden");
    }
  }
}
