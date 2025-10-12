import { Controller } from "@hotwired/stimulus";
import { toPng } from "html-to-image";

export default class extends Controller {
  static targets = ["slide", "progressBar", "counter", "shareFeedback", "bento", "downloadButton", "audio", "audioToggle", "slideContainer", "overlay"];
  static values = {
    interval: { type: Number, default: 3700 },
    shareUrl: String,
    username: String
  };

  connect() {
    this.currentIndex = 0;
    this.showHasStarted = false;
    this.overlayHideTimeout = null;
    this.boundKeydown = this.handleKeydown.bind(this);
    window.addEventListener("keydown", this.boundKeydown);
    this.element.style.setProperty("--wrapped-interval", `${this.intervalValue}ms`);
    this.animatedCounters = new WeakSet();
    this.shareFeedbackTimeout = null;
    this.updateSlides();
    this.setupAudio();
    this.resetOverlayState();

    if (!this.hasOverlayTarget) {
      this.startShow();
    }
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundKeydown);
    this.stopTimer();
    this.teardownAudio();
    if (this.shareFeedbackTimeout) {
      clearTimeout(this.shareFeedbackTimeout);
      this.shareFeedbackTimeout = null;
    }
    if (this.overlayHideTimeout) {
      clearTimeout(this.overlayHideTimeout);
      this.overlayHideTimeout = null;
    }
  }

  previous(event) {
    if (event) event.preventDefault();
    if (!this.hasSlideTarget) return;
    if (!this.showHasStarted) return;

    this.currentIndex = (this.currentIndex - 1 + this.slideTargets.length) % this.slideTargets.length;
    this.updateSlides();
    this.restartTimer();
  }

  next(event) {
    if (event) event.preventDefault();
    if (!this.hasSlideTarget) return;
    if (!this.showHasStarted) return;

    this.currentIndex = (this.currentIndex + 1) % this.slideTargets.length;
    this.updateSlides();
    this.restartTimer();
  }

  handleKeydown(event) {
    if (event.defaultPrevented) return;
    const tag = event.target.tagName;
    if (["INPUT", "TEXTAREA", "SELECT"].includes(tag)) return;
    if (event.target.isContentEditable) return;

    if (!this.showHasStarted) return;

    if (event.key === "ArrowRight") {
      event.preventDefault();
      this.next();
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      this.previous();
    }
  }

  handleTap(event) {
    if (!this.hasSlideContainerTarget) return;
    if (event.defaultPrevented) return;
    if (event.detail > 1) return;
    if (!this.showHasStarted) return;

    if (this.shouldIgnoreTap(event)) return;

    const clientX = this.extractClientX(event);
    if (clientX === null) return;

    const rect = this.slideContainerTarget.getBoundingClientRect();
    if (!rect || rect.width === 0) return;

    if (clientX < rect.left || clientX > rect.right) return;

    const relativeX = clientX - rect.left;
    if (relativeX < rect.width / 2) {
      this.previous();
    } else {
      this.next();
    }
  }

  startTimer() {
    this.stopTimer();
    if (!this.showHasStarted) return;
    if (this.slideTargets.length <= 1) return;

    const interval = this.intervalValue;
    this.timer = setTimeout(() => this.next(), interval);
    this.animateCurrentProgressBar(interval);
  }

  restartTimer() {
    if (!this.showHasStarted) return;
    this.startTimer();
  }

  startShow() {
    if (this.showHasStarted) return;

    this.showHasStarted = true;
    this.animateCountersForCurrentSlide();
    this.startTimer();
  }

  resetOverlayState() {
    if (!this.hasOverlayTarget) return;

    this.overlayTarget.classList.remove("hidden", "pointer-events-none", "opacity-0");
    this.overlayTarget.setAttribute("aria-hidden", "false");
    this.overlayHideTimeout = null;
  }

  hideOverlay() {
    if (!this.hasOverlayTarget) return;

    this.overlayTarget.classList.add("opacity-0", "pointer-events-none");
    this.overlayTarget.setAttribute("aria-hidden", "true");

    if (this.overlayHideTimeout) {
      clearTimeout(this.overlayHideTimeout);
    }

    this.overlayHideTimeout = window.setTimeout(() => {
      this.overlayTarget.classList.add("hidden");
      this.overlayHideTimeout = null;
    }, 400);
  }

  async startExperience(event) {
    if (event) event.preventDefault();

    const audioPromise = this.playAudioElement();

    if (!this.showHasStarted) {
      this.startShow();
    }

    this.hideOverlay();

    await audioPromise;
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
    if (!this.showHasStarted) return;

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

  async shareWrapped(event) {
    if (event) event.preventDefault();
    if (!this.hasShareUrlValue) return;

    const url = this.shareUrlValue;
    const title = this.hasUsernameValue && this.usernameValue ? `${this.usernameValue}'s Summer of Making Wrapped` : "Summer of Making Wrapped";

    if (navigator.share) {
      try {
        await navigator.share({ title, url });
        this.showShareFeedback();
        return;
      } catch (error) {
        if (error && error.name === "AbortError") return;
        console.warn("Native share failed, falling back to copy", error);
      }
    }

    this.copyShareLink();
  }

  copyShareLink(event) {
    if (event) event.preventDefault();
    if (!this.hasShareUrlValue) return;

    const url = this.shareUrlValue;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard
        .writeText(url)
        .then(() => this.showShareFeedback())
        .catch(() => this.fallbackCopy(url));
    } else {
      this.fallbackCopy(url);
    }
  }

  async downloadBento(event) {
    event.preventDefault();
    if (!this.hasBentoTarget) return;

    this.toggleDownloadButton(true);
    const captureContext = this.prepareBentoForCapture();
    const bentoNode = captureContext && captureContext.node ? captureContext.node : this.bentoTarget;

    try {
      await Promise.all([this.waitForLayout(), this.ensureFontsLoaded()]);

      const exportOptions = {
        backgroundColor: "#f8fafc",
        cacheBust: true,
        pixelRatio: captureContext && captureContext.pixelRatio ? captureContext.pixelRatio : Math.min(window.devicePixelRatio || 2, 3),
        style: {
          transform: "scale(1)",
          transformOrigin: "top left"
        },
      };

      const dataUrl = await toPng(bentoNode, exportOptions);

      const link = document.createElement("a");
      link.download = `${this.filenameForBento()}.png`;
      link.href = dataUrl;
      link.click();
      this.dispatch("bento-export-success");
    } catch (error) {
      console.error("Failed to export bento grid", error);
      this.dispatch("bento-export-error", { detail: { error } });
    } finally {
      if (captureContext && typeof captureContext.restore === "function") {
        captureContext.restore();
      }
      this.toggleDownloadButton(false);
    }
  }

  prepareBentoForCapture() {
    if (!this.hasBentoTarget) return null;

    const container = document.createElement("div");
    container.style.position = "fixed";
    container.style.inset = "0";
    container.style.zIndex = "-1";
    container.style.pointerEvents = "none";
    container.style.opacity = "0";
    container.style.display = "flex";
    container.style.alignItems = "flex-start";
    container.style.justifyContent = "flex-start";
    container.style.overflow = "visible";
    container.style.background = "transparent";

    const templateRoot = this.bentoTarget.querySelector("[data-wrapped-bento-root]");
    const nodeToClone = templateRoot || this.bentoTarget;
    const clone = nodeToClone.cloneNode(true);

    clone.classList.remove("hidden");
    clone.style.opacity = "1";
    clone.style.position = "static";
    clone.style.top = "auto";
    clone.style.left = "auto";
    clone.style.right = "auto";
    clone.style.bottom = "auto";
    clone.style.margin = "0";
    clone.style.width = "auto";
    clone.style.height = "auto";
    clone.style.maxWidth = "none";
    clone.style.transform = "none";
    clone.style.pointerEvents = "none";
    clone.style.display = "block";

    container.appendChild(clone);
    document.body.appendChild(container);

    const rect = clone.getBoundingClientRect();
    const width = Math.max(1, Math.ceil(rect.width));
    const height = Math.max(1, Math.ceil(rect.height));

    if (width > 0 && height > 0) {
      clone.style.width = `${width}px`;
      clone.style.height = `${height}px`;
    }

    return {
      node: clone,
      width,
      height,
      pixelRatio: 2,
      restore() {
        if (container.parentNode) {
          container.parentNode.removeChild(container);
        }
      }
    };
  }

  waitForLayout() {
    return new Promise((resolve) => {
      requestAnimationFrame(() => {
        requestAnimationFrame(resolve);
      });
    });
  }

  ensureFontsLoaded() {
    if (document.fonts && typeof document.fonts.ready === "object") {
      return document.fonts.ready.catch(() => {});
    }
    return Promise.resolve();
  }

  fallbackCopy(text) {
    try {
      const temp = document.createElement("textarea");
      temp.value = text;
      temp.setAttribute("readonly", "");
      temp.style.position = "absolute";
      temp.style.left = "-9999px";
      document.body.appendChild(temp);
      temp.select();
      document.execCommand("copy");
      document.body.removeChild(temp);
      this.showShareFeedback();
    } catch (error) {
      console.error("Copy failed", error);
      this.dispatch("copy-error", { detail: { error } });
    }
  }

  showShareFeedback() {
    if (!this.hasShareFeedbackTarget) return;

    this.shareFeedbackTargets.forEach((element) => element.classList.remove("hidden"));
    if (this.shareFeedbackTimeout) clearTimeout(this.shareFeedbackTimeout);
    this.shareFeedbackTimeout = setTimeout(() => {
      this.shareFeedbackTargets.forEach((element) => element.classList.add("hidden"));
    }, 2000);
  }

  toggleDownloadButton(isBusy) {
    if (!this.hasDownloadButtonTarget) return;

    const button = this.downloadButtonTarget;
    if (!button.dataset.originalText) {
      button.dataset.originalText = button.textContent.trim();
    }
    button.disabled = isBusy;
    button.classList.toggle("opacity-60", isBusy);
    button.classList.toggle("cursor-not-allowed", isBusy);
    button.textContent = isBusy ? "Preparing..." : button.dataset.originalText;
  }

  filenameForBento() {
    if (this.hasUsernameValue && this.usernameValue) {
      const slug = this.slugify(this.usernameValue);
      return slug ? `${slug}-wrapped` : "wrapped";
    }
    return "wrapped";
  }

  slugify(value) {
    return value
      .toString()
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
  }

  setupAudio() {
    if (!this.hasAudioTarget) return;

    this.audioElement = this.audioTarget;
    this.audioElement.loop = true;
    this.audioElement.defaultPlaybackRate = 0.8;
    this.audioElement.playbackRate = 0.8;

    this.boundAudioPlay = this.handleAudioPlay.bind(this);
    this.boundAudioPause = this.handleAudioPause.bind(this);

    this.audioElement.addEventListener("play", this.boundAudioPlay);
    this.audioElement.addEventListener("pause", this.boundAudioPause);

    this.updateAudioButtonLabel();
  }

  teardownAudio() {
    if (!this.audioElement) return;

    this.audioElement.pause();
    this.audioElement.removeEventListener("play", this.boundAudioPlay);
    this.audioElement.removeEventListener("pause", this.boundAudioPause);
    this.boundAudioPlay = null;
    this.boundAudioPause = null;
    this.audioElement = null;
    this.updateAudioButtonLabel();
  }

  async playAudioElement() {
    if (!this.audioElement) return false;
    if (!this.audioElement.paused) return true;

    try {
      await this.audioElement.play();
      this.updateAudioButtonLabel();
      return true;
    } catch (error) {
      console.warn("Audio playback was prevented", error);
      this.dispatch("audio-playback-error", { detail: { error } });
      this.updateAudioButtonLabel();
      return false;
    }
  }

  async toggleAudio(event) {
    if (event) event.preventDefault();
    if (!this.audioElement) return;

    if (this.audioElement.paused) {
      await this.playAudioElement();
    } else {
      this.audioElement.pause();
    }
  }

  handleAudioPlay() {
    if (!this.audioElement) return;

    this.audioElement.defaultPlaybackRate = 0.8;
    this.audioElement.playbackRate = 0.8;
    this.updateAudioButtonLabel();
  }

  handleAudioPause() {
    this.updateAudioButtonLabel();
  }

  updateAudioButtonLabel() {
    if (!this.hasAudioToggleTarget) return;

    const button = this.audioToggleTarget;
    const isPlaying = this.audioElement && !this.audioElement.paused;
    const label = isPlaying ? "Pause soundtrack" : "Play soundtrack";

    button.setAttribute("aria-pressed", isPlaying ? "true" : "false");
    button.setAttribute("aria-label", label);

    const srOnlyText = button.querySelector(".sr-only");
    if (srOnlyText) {
      srOnlyText.textContent = label;
    }
  }

  shouldIgnoreTap(event) {
    const target = event.target;
    if (!target) return false;

    if (target.closest("button, a, input, textarea, select, label, [data-wrapped-tap-ignore], [role='button']")) {
      return true;
    }

    const selection = window.getSelection ? window.getSelection() : null;
    if (selection && selection.type === "Range") {
      return true;
    }

    return false;
  }

  extractClientX(event) {
    if (typeof event.clientX === "number") {
      return event.clientX;
    }

    if (event.touches && event.touches[0]) {
      return event.touches[0].clientX;
    }

    if (event.changedTouches && event.changedTouches[0]) {
      return event.changedTouches[0].clientX;
    }

    return null;
  }
}
