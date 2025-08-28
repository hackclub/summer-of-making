import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "background", "dialogue", "focus", "video", "videoContainer", "videoHint", "avatar", "hint"]
  static values = {
    displayName: String,
    scene: String
  }

  connect() {
    this.dialogue = [
      // intro
      `Psst! Hey there! <span class="new-tutorial-shake">${this.displayNameValue || "Hey"}!</span>`,
      `Welcome to the... <span class="new-tutorial-shake">SUMMER OF MAKING!!!</span>`,
      `Oh... I don't believe I've introduced myself.<br>I'm Explorpheus!`,
      `I'm here to guide you through everything you need to know to start shipping and earning <span class="new-tutorial-bling">prizes</span>`,
      
      // campfire
      `You're currently at the Campfire! This is where the latest news is shared!`,
      `You should check back here every once in a while! There's always so much happening on the island!`,

      // currency
      `Shells are our currency here. You can get so much cool stuff with them, but to get 'em, you gotta...`,
      `<span class="new-tutorial-shake">Build cool projects and ship them!</span>`,
      `Awesome! Let's dive a bit deeper!`,
      `Check out this video!`,

      // step-by-step - skipped if watched video
      `I'll walk you through what this is about!`,
      `1. Come up with a cool project idea. Make it something you've always wanted to build.`,
      `2. Start building! Track how much time you spent with Hackatime.`,
      `3. As you build, post <span class="new-tutorial-shake">devlogs</span>! They're mini updates on your progress.`,
      `4. Once it's ready, <span class="new-tutorial-shake">ship it</span> to the world! It doesn't have to be perfect. A MVP is okay!`,
      `5. Our shipwrights will make sure your project is working. They'll give you feedback!`,
      `6. Your project will then be voted on by the community. You'll vote on others' projects as well.`,
      `7. You'll earn shells depending on the number of votes and how long you've worked on your project.`,
      `8. You can spend these shells in our shop for awesome prizes!`,
      `Alright, that was quite the ramble...`,

      // hackatime
      `Don't worry if this is confusing, I'll walk you through each step`
    ];

    // x, y, width, height are offsets
    this.stepAttributes = [
      // intro
      {},
      {},
      {},
      {},

      // campfire
      {focus: 'new-tutorial-campfire-title', x: 0, y: 10, width: 50, height: -50, radius: 20},
      {focus: 'new-tutorial-campfire-title', x: 0, y: 10, width: 50, height: -50, radius: 20},

      // currency
      {},
      {},
      {},

      // step by step flow
      {video: '/onboarding.mp4', skip: 20},
      {},
      {},
      {},
      {},
      {},
      {},
      {},
      {},
      {},
      {},

      // hackatime
      {}
    ]

    this.progress = 0;
    this.initialDelay = 750;
    this.nextDelay = 500;
    this.lastClickedNext = Date.now();
    this.textTarget.innerHTML = this.dialogue[this.progress];
    const attributes = this.stepAttributes[this.progress];
    this.focusedElement = attributes.focus ? document.getElementById(attributes.focus) : null;

    this.updateElements();

    // click to advance elements
    this.backgroundTarget.addEventListener("click", () => this.advance());
    this.dialogueTarget.addEventListener("click", () => this.advance());

    // update focus when window size changes, the user scrolls, or resizes
    window.addEventListener("resize", () => this.updateElements({was_advance: false}));
    document.addEventListener("scroll", () => this.updateElements({was_advance: false}));

    // video
    this.videoTarget.addEventListener("timeupdate", () => this.updateVideoProgress());
  }

  disconnect() {
    this.backgroundTarget.removeEventListener("click", () => this.advance());
    this.dialogueTarget.removeEventListener("click", () => this.advance());
    window.removeEventListener("resize", () => this.updateElements({was_advance: false}));
    document.removeEventListener("scroll", () => this.updateElements({was_advance: false}));
    this.videoTarget.removeEventListener("timeupdate", () => this.updateVideoProgress());

    // stop video
    this.videoTarget.pause();
  }

  updateElements(params = {}) {
    let was_advance = params.was_advance ?? true;
    let previous = params.previous ?? this.progress - 1;

    const attributes = this.stepAttributes[this.progress];
    const prevAttributes = this.stepAttributes[previous] || {};

    this.textTarget.innerHTML = this.dialogue[this.progress];

    console.log("Updating elements:", {was_advance, previous, focusedElement: this.focusedElement, attributes});

    // focus box
    this.focusedElement = attributes.focus ? document.getElementById(attributes.focus) : null;
    if (this.focusedElement) {
      const rect = this.focusedElement.getBoundingClientRect();
      this.dialogueFocus = {
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
        radius: 0,
        z: true
      };
      this.dialogueFocus.x += (attributes.x ?? 0) - (attributes.width ?? 0) / 2;
      this.dialogueFocus.y += (attributes.y ?? 0) - (attributes.height ?? 0) / 2;
      this.dialogueFocus.width += (attributes.width ?? 0);
      this.dialogueFocus.height += (attributes.height ?? 0);
      this.dialogueFocus.radius += (attributes.radius ?? 0);
      this.dialogueFocus.z = attributes.z ?? true;

      if (this.dialogueFocus.z) {
        this.focusedElement.style.zIndex = 100;
      } else {
        this.focusedElement.style.zIndex = "";
      }
    } else {
      this.dialogueFocus = {
        x: 0,
        y: 0,
        width: 0,
        height: 0,
        radius: 0,
        z: true
      };

      // clear previous focus
      if (prevAttributes.focus) {
        const prevFocusElement = document.getElementById(prevAttributes.focus);
        if (prevFocusElement) {
          prevFocusElement.style.zIndex = "";
        }
      }
    }
    this.focusTarget.setAttribute("x", this.dialogueFocus.x);
    this.focusTarget.setAttribute("y", this.dialogueFocus.y);
    this.focusTarget.setAttribute("width", this.dialogueFocus.width);
    this.focusTarget.setAttribute("height", this.dialogueFocus.height);
    this.focusTarget.setAttribute("rx", this.dialogueFocus.radius);
    this.focusTarget.setAttribute("ry", this.dialogueFocus.radius);

    // video
    if (attributes.video) {
      this.videoTarget.style.display = "";
      this.videoContainerTarget.style.display = "";

      if (was_advance) {
        this.videoTarget.src = attributes.video;
        this.videoTarget.currentTime = 0;

        setTimeout(() => {
          this.videoTarget.play();
        }, 760);

        this.avatarTarget.classList.add("new-tutorial-avatar-slide-out");
      }

      if (this.videoProgress > 0.95) {
        this.hintTarget.style.display = "";
        this.videoHintTarget.innerHTML = "Continue...";
        this.videoContainerTarget.style.pointerEvents = "none";
      } else {
        this.hintTarget.style.display = "none";
        this.videoHintTarget.innerHTML = "Skip for now..."
        this.videoContainerTarget.style.pointerEvents = "";
      }
    } else {
      this.videoTarget.pause();
      this.videoTarget.currentTime = 0;
      this.videoTarget.style.display = "none";
      this.videoContainerTarget.style.display = "none";
      this.hintTarget.style.display = "";

      this.avatarTarget.classList.remove("new-tutorial-avatar-slide-out");

      // clear previous video
      if (prevAttributes.video) {
        this.avatarTarget.classList.add("new-tutorial-avatar-slide-in");

        setTimeout(() => {
          this.avatarTarget.classList.remove("new-tutorial-avatar-slide-in");
        }, 510);
      }
    }
  }

  updateVideoProgress() {
    const attributes = this.stepAttributes[this.progress] || {};
    if (attributes.video) {
      const video = this.videoTarget;
      const progress = video.currentTime / video.duration;
      this.videoProgress = progress;
      
      this.updateElements({was_advance: false});

      console.log(`Video progress: ${progress * 100}%`);
    }
  }

  skipVideo() {
    this.advance({force: true, skipped: true});
  }

  advance(params = {}) {
    let force = params.force ?? false;
    let skipped = params.skipped ?? false;
    const attributes = this.stepAttributes[this.progress] || {};

    if (!force) {
      if (attributes.video && this.videoProgress < 0.95) {
        console.log("Advancing is disabled");
        return;
      }
    }

    if (Date.now() - this.lastClickedNext < (this.progress == 0 ? this.initialDelay : this.nextDelay)) {
      console.log("Clicked too soon");
      return;
    }
    this.lastClickedNext = Date.now();

    let previous = this.progress;
    if (attributes.video && attributes.skip && !skipped) {
      this.progress = attributes.skip;
    } else {
      this.progress++;
    }

    console.log(`Advancing to step: ${this.progress}`);
    if (this.progress < this.dialogue.length) {
      this.updateElements({previous: previous});
    } else {
      console.log("No more steps to advance.");
    }
  }
}
