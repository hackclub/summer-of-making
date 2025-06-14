import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "introVideo",
    "modal",
    "container",
    "emailInput",
    "msg",
    "videoContainer",
  ];
  static values = { email: String };

  connect() {
    if (this.hasEmailInputTarget) {
      this.emailInputTarget.addEventListener("input", () => {
        this.hideError();
      });
    }
    this.play();
  }

  startSignup() {
    const x = this.hasEmailInputTarget
      ? this.emailInputTarget.value.trim()
      : "";
    this.hideError();
    if (!x) {
      this.error("pls enter your email");
      if (this.hasEmailInputTarget) this.emailInputTarget.focus();
      return;
    }
    if (!this.isValidEmail(x)) {
      this.error("pls enter a valid email address");
      if (this.hasEmailInputTarget) this.emailInputTarget.focus();
      return;
    }
    const button = this.element.querySelector(".marble-button");
    const originalText = button ? button.textContent : "";
    if (button) {
      button.textContent = "Sending your invite...";
      button.disabled = true;
      button.classList.add("opacity-75");
    }
    this.sendEmail(x)
      .then((data) => {
        if (button) {
          button.textContent = originalText;
          button.disabled = false;
          button.classList.remove("opacity-75");
        }
        if (
          data.invites &&
          data.invites[0] &&
          data.invites[0].error === "already_in_team"
        ) {
          window.location.href = window.location.origin + "/auth/slack";
          return;
        }
        const modal = document.getElementById("signup-wizard");
        if (modal) {
          const modalController =
            this.application.getControllerForElementAndIdentifier(
              modal,
              "signup-wizard"
            );
          if (modalController && modalController !== this) {
            modalController.emailValue = x;
            modalController.show();
          } else {
            // fallback: just show the modal
            modal.classList.remove("hidden");
            document.body.classList.add("overflow-hidden");
          }
        }
      })
      .catch(() => {
        if (button) {
          button.textContent = originalText;
          button.disabled = false;
          button.classList.remove("opacity-75");
        }
        this.error("Failed to send email. Please try again.");
      });
  }

  async sendEmail(email) {
    let csrfToken = "";
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    if (metaTag) {
      csrfToken = metaTag.content;
    }
    const response = await fetch("/sign-up", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ email: email }),
    });
    if (!response.ok) {
      throw new Error("Failed to send email");
    }
    return await response.json();
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

  play() {
    if (
      this.hasIntroVideoTarget &&
      !this.element.classList.contains("hidden")
    ) {
      this.introVideoTarget.loop = true;
      this.introVideoTarget.play().catch((error) => {
        if (!document.getElementById("manual-play-button")) {
          const playButton = document.createElement("button");
          playButton.id = "manual-play-button";
          playButton.className =
            "absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg";
          playButton.innerHTML = `
            <div class="bg-white/80 rounded-full p-3 hover:bg-white transition-all">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-vintage-red" viewBox="0 0 24 24">
                <path fill="currentColor" d="M8 5.14v14l11-7l-11-7Z"/>
              </svg>
            </div>
          `;
          playButton.addEventListener("click", () => {
            this.introVideoTarget.play();
            playButton.remove();
          });
          const videoContainer = this.introVideoTarget.parentElement;
          videoContainer.style.position = "relative";
          videoContainer.appendChild(playButton);
        }
      });
    }
  }

  show() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden");
      document.body.classList.add("overflow-hidden");
      setTimeout(() => {
        if (this.hasIntroVideoTarget) {
          this.introVideoTarget.loop = true;
          this.introVideoTarget.play().catch(() => {
            this.play();
          });
        }
      }, 50);
    }
  }

  hide() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden");
      document.body.classList.remove("overflow-hidden");
      if (this.hasIntroVideoTarget) {
        this.introVideoTarget.pause();
      }
    }
  }
}
