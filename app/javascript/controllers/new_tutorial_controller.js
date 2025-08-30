import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "text", "background", "dialogue", "focus", "video", "videoContainer", "videoHint", "avatar", "hint"]
  static values = {
    displayName: String,
    scene: String,
    hackatimeCondition: Boolean,
    checkpoint: String,
    currentPath: String
  }

  connect() {
    if (this.currentPathValue == "/campfire") {
      this.start("intro")
    }
  }

  disconnect() {
    this.backgroundTarget.removeEventListener("click", () => this.advance());
    this.dialogueTarget.removeEventListener("click", () => this.advance());
    window.removeEventListener("resize", () => this.updateElements({was_advance: false}));
    document.removeEventListener("scroll", () => this.updateElements({was_advance: false}));
    this.videoTarget.removeEventListener("timeupdate", () => this.updateVideoProgress());

    // stop video
    this.videoTarget.pause();

    if (this.containerTarget) {
      this.containerTarget.style.display = "none";
    }
  }

  start(scene = this.sceneValue, checkpoint = this.checkpointValue) {
    if (this.containerTarget) {
      this.containerTarget.style.display = "";
    }

    this.scene = scene;
    this.startingCheckpoint = checkpoint;
    this.startingProgress = this.startingCheckpoint ? getNewTutorialCheckpointStep(this.scene, this.startingCheckpoint) : 0;
    console.log("Starting new tutorial scene:", this.scene, "and values: ", {displayName: this.displayNameValue, hackatimeCondition: this.hackatimeConditionValue, checkpoint: this.checkpointValue, startingProgress: this.startingProgress, currentPath: this.currentPathValue});

    this.dialogue = getNewTutorialDialogue(this.scene, { displayName: this.displayNameValue });

    this.progress = this.startingProgress;
    this.initialDelay = 750;
    this.nextDelay = 500;
    this.lastClickedNext = Date.now();

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

  startShipScene() {
    this.start("ship");
  }

  end() {
    if (this.scene == "ship") {
      location.reload();
    } else {
      console.log("Ending new tutorial:", this.scene);
      this.containerTarget.classList.remove("bg-fade-in");
      this.containerTarget.classList.add("bg-fade-out");

      setTimeout(() => {
        this.containerTarget.style.display = "none";
        this.containerTarget.classList.remove("bg-fade-out");
        this.containerTarget.classList.add("bg-fade-in");
      }, 250);
    }
  }

  updateElements(params = {}) {
    let was_advance = params.was_advance ?? true;
    let previous = params.previous ?? this.progress - 1;

    const attributes = this.dialogue[this.progress];
    const prevAttributes = this.dialogue[previous] || {};
    
    this.textTarget.innerHTML = attributes.text || "";

    console.debug("Updating elements:", {was_advance, previous, focusedElement: this.focusedElement, attributes});

    // focus/spotlight
    this.focusedElement = attributes.focus ? document.getElementById(attributes.focus) : null;
    this.focusedOtherElements = attributes.focusOther ? attributes.focusOther.map(id => document.getElementById(id)).filter(el => el) : [];
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
        this.focusedOtherElements.forEach(el => el.style.zIndex = 99);
      } else {
        this.focusedElement.style.zIndex = "";
        this.focusedOtherElements.forEach(el => el.style.zIndex = "");
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
      if (prevAttributes.focus) {
        const prevFocusElement = document.getElementById(prevAttributes.focus);
        const prevOtherFocusElements = prevAttributes.focusOther ? prevAttributes.focusOther.map(id => document.getElementById(id)).filter(el => el) : [];
        if (prevFocusElement) {
          prevFocusElement.style.zIndex = "";
        }
        prevOtherFocusElements.forEach(el => el.style.zIndex = ""); 
      }
    }
    this.focusTarget.setAttribute("x", this.dialogueFocus.x);
    this.focusTarget.setAttribute("y", this.dialogueFocus.y);
    this.focusTarget.setAttribute("width", this.dialogueFocus.width);
    this.focusTarget.setAttribute("height", this.dialogueFocus.height);
    this.focusTarget.setAttribute("rx", this.dialogueFocus.radius);
    this.focusTarget.setAttribute("ry", this.dialogueFocus.radius);

    if (this.focusedElement) {
      if (this.dialogueFocus.z) {
        this.focusedElement.style.zIndex = 100;
      } else {
        this.focusedElement.style.zIndex = "";
        this.focusedOtherElements.forEach(el => el.style.zIndex = "");
      }
    }
    if (this.dialogueFocus.z) {
      this.focusedOtherElements.forEach(el => el.style.zIndex = 99);
    } else {
      this.focusedOtherElements.forEach(el => el.style.zIndex = "");
    }

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

      if (prevAttributes.video) {
        this.avatarTarget.classList.add("new-tutorial-avatar-slide-in");

        setTimeout(() => {
          this.avatarTarget.classList.remove("new-tutorial-avatar-slide-in");
        }, 510);
      }
    }

    // prevent advance
    if (attributes.preventAdvance) {
      this.hintTarget.style.display = "none";
    } else {
      this.hintTarget.style.display = "";
    }
  }

  updateVideoProgress() {
    const attributes = this.dialogue[this.progress] || {};
    if (attributes.video) {
      const video = this.videoTarget;
      const progress = video.currentTime / video.duration;
      this.videoProgress = progress;
      
      this.updateElements({was_advance: false});

      console.debug(`Video progress: ${progress * 100}%`);
    }
  }

  skipVideo() {
    this.advance({force: true, skipped: true});
  }

  advance(params = {}) {
    let force = params.force ?? false;
    let skipped = params.skipped ?? false;
    const attributes = this.dialogue[this.progress] || {};

    if (!force) {
      if (attributes.video && this.videoProgress < 0.95 || attributes.preventAdvance) {
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
      this.progress += attributes.skip;
    } else {
      this.progress++;
    }

    console.log(`Advancing to step: ${this.progress}`);
    if (this.progress < this.dialogue.length) {
      let attributes = this.dialogue[this.progress] || {};
      if (attributes.condition) {
        if (this.processConditions(attributes.condition)) {
          attributes = {...attributes, ...attributes.alt};
          if (attributes.skip) {
            this.progress += attributes.skip;
          }
        }
        this.dialogue[this.progress] = attributes;
      }

      this.updateElements({previous: previous});
    } else {
      this.end();
    }
  }

  processConditions(condition) {
    if (condition == "hackatime") {
      return this.hackatimeConditionValue;
    }
  }
}
