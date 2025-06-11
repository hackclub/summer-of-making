import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "step1",
    "step2",
    "step3",
    "step4",
    "stepIndicator",
    "nextButton",
    "prevButton",
    "progressBar",
  ];
  static values = {
    email: String,
    currentStep: { type: Number, default: 1 },
  };

  connect() {
    this.h = this.h.bind(this);
    document.addEventListener("keydown", this.h);
  }

  initialize() {
    this.s(1);
    this.u();
    this.b();
    this.p();
  }

  disconnect() {
    document.removeEventListener("keydown", this.h);
  }

  h(e) {
    if (e.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close();
      e.stopPropagation();
    }
  }

  s(n) {
    this.step1Target.classList.add("hidden");
    this.step2Target.classList.add("hidden");
    this.step3Target.classList.add("hidden");
    this.step4Target.classList.add("hidden");

    switch (n) {
      case 1:
        this.step1Target.classList.remove("hidden");
        break;
      case 2:
        this.step2Target.classList.remove("hidden");
        break;
      case 3:
        this.step3Target.classList.remove("hidden");
        break;
      case 4:
        this.step4Target.classList.remove("hidden");
        break;
    }

    this.currentStepValue = n;
    this.u();
    this.b();
    this.p();
  }

  nextStep() {
    if (this.currentStepValue < 4) {
      this.s(this.currentStepValue + 1);
    } else if (this.currentStepValue === 4) {
      this.e();
    }
  }

  prevStep() {
    if (this.currentStepValue > 1) {
      this.s(this.currentStepValue - 1);
    }
  }

  u() {
    if (this.hasStepIndicatorTarget) {
      this.stepIndicatorTarget.textContent = this.currentStepValue;
    }
  }

  p() {
    if (this.hasProgressBarTarget) {
      const w = (this.currentStepValue / 4) * 100;
      this.progressBarTarget.style.width = `${w}%`;
    }
  }

  b() {
    if (this.hasPrevButtonTarget) {
      if (this.currentStepValue === 1) {
        this.prevButtonTarget.classList.add("opacity-50");
        this.prevButtonTarget.disabled = true;
      } else {
        this.prevButtonTarget.classList.remove("opacity-50");
        this.prevButtonTarget.disabled = false;
      }
    }

    if (this.hasNextButtonTarget) {
      if (this.currentStepValue === 4) {
        this.nextButtonTarget.textContent = "Send Invite Email";
        this.nextButtonTarget.classList.remove("bg-forest");
        this.nextButtonTarget.classList.add("bg-vintage-red");
      } else {
        this.nextButtonTarget.textContent = "Next →";
        this.nextButtonTarget.classList.remove("bg-vintage-red");
        this.nextButtonTarget.classList.add("bg-forest");
      }
    }
  }

  async e() {
    const btn = this.nextButtonTarget;
    const txt = btn.textContent;

    btn.textContent = "Sending...";
    btn.disabled = true;
    btn.classList.add("opacity-75");

    try {
      const r = await fetch("/sign-up", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify({ email: this.emailValue }),
      });

      if (r.ok) {
        const d = await r.json();
        this.ss(d);
      } else {
        const ed = await r.json();
        throw new Error(ed.error || "Failed to send signup email");
      }
    } catch (err) {
      console.error("Error sending signup email:", err);
      alert(`Error: ${err.message}`);

      btn.textContent = "Try Again";
      btn.disabled = false;
      btn.classList.remove("opacity-75");

      setTimeout(() => {
        btn.textContent = txt;
      }, 2000);
    }
  }

  ss(rd) {
    this.step1Target.classList.add("hidden");
    this.step2Target.classList.add("hidden");
    this.step3Target.classList.add("hidden");
    this.step4Target.classList.add("hidden");

    const sh = `
      <div class="flex flex-col items-center justify-center h-full text-center space-y-8 max-w-3xl mx-auto">
        <h2 class="text-4xl font-bold text-forest mb-6">Welcome aboard! ✨</h2>
        <p class="text-xl">Check your inbox (<strong>${
          rd.email
        }</strong>) for a email from Slack</p>
        
        ${
          rd.ok
            ? '<p class="text-green-600 font-semibold text-lg">✅ Email sent successfully!</p>'
            : `<p class="text-red-500 text-lg font-semibold">❌ Error: ${
                rd.error || "Unknown error"
              }</p>`
        }

        <button class="marble-button mt-8 px-8 py-4 text-lg" data-action="click->signup-wizard#close">
          Close
        </button>
      </div>
    `;

    const se = document.createElement("div");
    se.innerHTML = sh;
    se.classList.add("flex-1", "flex", "items-center", "justify-center");

    const cc = this.element.querySelector(".flex-1.p-8");
    if (cc) {
      cc.innerHTML = "";
      cc.appendChild(se);
    }

    const f = this.element.querySelector(".border-t");
    if (f) {
      f.classList.add("hidden");
    }

    this.upt();
  }

  upt() {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "100%";
    }
    if (this.hasStepIndicatorTarget) {
      this.stepIndicatorTarget.textContent = "✓";
    }
  }

  close() {
    this.element.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");

    setTimeout(() => {
      if (this.currentStepValue) {
        this.s(1);
      }
    }, 500);
  }

  co(e) {
    if (e.target === this.element) {
      this.close();
    }
  }
}
