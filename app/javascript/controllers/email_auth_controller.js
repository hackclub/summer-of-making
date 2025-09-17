import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "container",
    "emailInput", 
    "errorMessage",
    "successMessage",
    "submitButton",
    "form"
  ];

  connect() {
    console.log("EmailAuth controller connected");
    if (this.hasEmailInputTarget) {
      this.emailInputTarget.addEventListener("input", () => {
        this.hideMessages();
      });
    }
  }

  show() {
    console.log("EmailAuth show method called");
    const modal = document.getElementById("email-auth-modal");
    const container = modal?.querySelector('[data-email-auth-target="container"]');
    
    if (modal && container) {
      console.log("Found modal, showing it");
      
      // Show modal and start animation
      modal.style.display = "flex";
      document.body.classList.add("overflow-hidden");
      
      // Trigger animations
      requestAnimationFrame(() => {
        modal.classList.remove("opacity-0");
        modal.classList.add("opacity-100");
        container.classList.remove("scale-95");
        container.classList.add("scale-100");
      });
      
      // Focus on email input after animation
      setTimeout(() => {
        const emailInput = modal.querySelector('input[type="email"]');
        if (emailInput) {
          emailInput.focus();
        }
      }, 150);
    } else {
      console.error("Modal not found!");
    }
  }

  close() {
    const modal = document.getElementById("email-auth-modal");
    const container = modal?.querySelector('[data-email-auth-target="container"]');
    
    if (modal && container) {
      // Start close animation
      modal.classList.remove("opacity-100");
      modal.classList.add("opacity-0");
      container.classList.remove("scale-100");
      container.classList.add("scale-95");
      
      // Hide modal after animation completes
      setTimeout(() => {
        modal.style.display = "none";
        document.body.classList.remove("overflow-hidden");
        this.resetForm();
      }, 200);
    }
  }

  closeBackground(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.sendMagicLink(event);
    }
  }

  async sendMagicLink(event) {
    event.preventDefault();
    
    const email = this.hasEmailInputTarget 
      ? this.emailInputTarget.value.trim().toLowerCase() 
      : "";

    this.hideMessages();

    if (!email) {
      this.showError("Please enter your email address");
      if (this.hasEmailInputTarget) this.emailInputTarget.focus();
      return;
    }

    if (!this.isValidEmail(email)) {
      this.showError("Please enter a valid email address");
      if (this.hasEmailInputTarget) this.emailInputTarget.focus();
      return;
    }

    const button = this.hasSubmitButtonTarget ? this.submitButtonTarget : null;
    const originalText = button ? button.textContent : "";
    
    if (button) {
      button.textContent = "Sending...";
      button.disabled = true;
      button.style.opacity = "0.75";
    }

    try {
      await this.sendAuthEmail(email);
      this.showSuccess("Magic link sent! Check your email and click the link to sign in.");
      
      // Clear the form
      if (this.hasEmailInputTarget) {
        this.emailInputTarget.value = "";
      }
    } catch (error) {
      // Show the specific error message from the server if available
      const errorMessage = error.message || "Failed to send email. Please try again.";
      this.showError(errorMessage);
    } finally {
      // Restore button state
      if (button) {
        button.textContent = originalText;
        button.disabled = false;
        button.style.opacity = "";
      }
    }
  }

  async sendAuthEmail(email) {
    const csrfToken = this.getCsrfToken();

    const response = await fetch("/auth/email", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ email }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || "Failed to send email");
    }

    return await response.json();
  }

  getCsrfToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : "";
  }

  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message;
      this.errorMessageTarget.style.display = "block";
    }
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.style.display = "none";
    }
  }

  showSuccess(message) {
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.textContent = message;
      this.successMessageTarget.style.display = "block";
    }
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.style.display = "none";
    }
  }

  hideMessages() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.style.display = "none";
    }
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.style.display = "none";
    }
  }

  resetForm() {
    if (this.hasEmailInputTarget) {
      this.emailInputTarget.value = "";
    }
    this.hideMessages();
  }
}
