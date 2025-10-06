import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slide", "progressBar", "counter"];
  static values = {
    interval: { type: Number, default: 8000 }
  };

  connect() {
    this.currentIndex = 0;
    this.boundKeydown = this.handleKeydown.bind(this);
    window.addEventListener("keydown", this.boundKeydown);
    this.element.style.setProperty("--wrapped-interval", `${this.intervalValue}ms`);
    this.animatedCounters = new WeakSet();
    this.updateSlides();
    this.startTimer();
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundKeydown);
    this.stopTimer();
  }

  previous(event) {
    if (event) event.preventDefault();
    if (!this.hasSlideTarget) return;

    this.currentIndex = (this.currentIndex - 1 + this.slideTargets.length) % this.slideTargets.length;
    this.updateSlides();
    this.restartTimer();
  }

  next(event) {
    if (event) event.preventDefault();
    if (!this.hasSlideTarget) return;

    this.currentIndex = (this.currentIndex + 1) % this.slideTargets.length;
    this.updateSlides();
    this.restartTimer();
  }

  handleKeydown(event) {
    if (event.defaultPrevented) return;
    const tag = event.target.tagName;
    if (["INPUT", "TEXTAREA", "SELECT"].includes(tag)) return;
    if (event.target.isContentEditable) return;

    if (event.key === "ArrowRight") {
      event.preventDefault();
      this.next();
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      this.previous();
    }
  }

  startTimer() {
    this.stopTimer();
    if (this.slideTargets.length <= 1) return;

    const interval = this.intervalValue;
    this.timer = setTimeout(() => this.next(), interval);
    this.animateCurrentProgressBar(interval);
  }

  restartTimer() {
    this.startTimer();
  }

  stopTimer() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  updateSlides() {
    this.slideTargets.forEach((slide, index) => {
      if (index === this.currentIndex) {
        slide.classList.remove("opacity-0", "pointer-events-none", "scale-95");
        slide.classList.add("opacity-100", "pointer-events-auto", "scale-100");
      } else {
        slide.classList.add("opacity-0", "pointer-events-none", "scale-95");
        slide.classList.remove("opacity-100", "pointer-events-auto", "scale-100");
      }
    });

    this.progressBarTargets.forEach((bar, index) => {
      bar.style.transition = "none";
      if (index < this.currentIndex) {
        bar.style.width = "100%";
      } else if (index === this.currentIndex) {
        bar.style.width = "0%";
      } else {
        bar.style.width = "0%";
      }
    });

    this.animateCountersForCurrentSlide();
  }

  animateCurrentProgressBar(interval) {
    if (!this.hasProgressBarTarget) return;

    const currentBar = this.progressBarTargets[this.currentIndex];
    if (!currentBar) return;

    currentBar.style.transition = "none";
    currentBar.style.width = "0%";
    currentBar.offsetWidth; // Force reflow
    currentBar.style.transition = `width ${interval}ms linear`;
    currentBar.style.width = "100%";
  }

  animateCountersForCurrentSlide() {
    const slide = this.slideTargets[this.currentIndex];
    if (!slide) return;

    const counters = this.counterTargets.filter((counter) => slide.contains(counter));
    counters.forEach((counter) => this.startCounter(counter));
  }

  startCounter(counter) {
    if (this.animatedCounters.has(counter)) return;

    const finalValue = parseFloat(counter.dataset.wrappedCounterValue || "0");
    const startValue = parseFloat(counter.dataset.wrappedCounterStart || "0");
    const duration = parseInt(counter.dataset.wrappedCounterDuration || "1200", 10);
    const type = counter.dataset.wrappedCounterType || "integer";

    const startTime = performance.now();

    const step = (now) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = this.easeOutQuad(progress);
      const value = startValue + (finalValue - startValue) * eased;

      counter.textContent = this.formatCounterValue(type, value, counter.dataset.wrappedCounterPrecision);

      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        this.animatedCounters.add(counter);
      }
    };

    requestAnimationFrame(step);
  }

  easeOutQuad(t) {
    return t * (2 - t);
  }

  formatCounterValue(type, value, precisionAttr) {
    switch (type) {
      case "currency":
        return new Intl.NumberFormat("en-US", {
          style: "currency",
          currency: "USD",
          maximumFractionDigits: 0
        }).format(value);
      case "decimal": {
        const precision = precisionAttr ? parseInt(precisionAttr, 10) : 2;
        return value.toFixed(precision);
      }
      case "shells":
        return Math.round(value).toLocaleString();
      default:
        return Math.round(value).toLocaleString();
    }
  }
}
