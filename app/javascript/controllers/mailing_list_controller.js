import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["emailInput", "errorMsg", "successMsg", "submitBtn"];

  connect() {
    if (this.hasEmailInputTarget) {
      this.emailInputTarget.addEventListener("input", () => {
        this.hideMessages();
      });
    }
  }

  async subscribe() {
    const email = this.hasEmailInputTarget
      ? this.emailInputTarget.value.trim().toLowerCase()
      : "";

    this.hideMessages();

    if (!email) {
      this.showError("Please enter your email");
      if (this.hasEmailInputTarget) this.emailInputTarget.focus();
      return;
    }

    if (!this.isValidEmail(email)) {
      this.showError("Please enter a valid email address");
      if (this.hasEmailInputTarget) this.emailInputTarget.focus();
      return;
    }

    const button = this.submitBtnTarget;
    const originalText = button.textContent;
    button.textContent = "Subscribing...";
    button.disabled = true;
    button.classList.add("opacity-75");

    try {
      const response = await this.sendSubscription(email);

      if (response.ok) {
        this.showSuccess("You're subscribed! We'll email you when we launch new programs.");
        if (this.hasEmailInputTarget) {
          this.emailInputTarget.value = "";
        }
      } else {
        const data = await response.json();
        this.showError(data.error || "Something went wrong. Please try again.");
      }
    } catch (error) {
      this.showError("Failed to subscribe. Please try again.");
    } finally {
      button.textContent = originalText;
      button.disabled = false;
      button.classList.remove("opacity-75");
    }
  }

  async sendSubscription(email) {
    let csrfToken = "";
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    if (metaTag) {
      csrfToken = metaTag.content;
    }

    return await fetch("/mailing-list-signup", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ email }),
    });
  }

  isValidEmail(email) {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
  }

  showError(message) {
    if (this.hasErrorMsgTarget) {
      this.errorMsgTarget.textContent = message;
      this.errorMsgTarget.classList.remove("hidden");
    }
  }

  showSuccess(message) {
    if (this.hasSuccessMsgTarget) {
      this.successMsgTarget.textContent = message;
      this.successMsgTarget.classList.remove("hidden");
    }
  }

  hideMessages() {
    if (this.hasErrorMsgTarget) {
      this.errorMsgTarget.classList.add("hidden");
    }
    if (this.hasSuccessMsgTarget) {
      this.successMsgTarget.classList.add("hidden");
    }
  }
}
