import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "modal",
    "form",
    "no404Checkbox",
    "no404Check",
    "no404CheckboxParent",
    "submitButton",
    "page1",
    "page2",
    "page3",
    "nextButton1",
    "nextButton2",
    "backButton1",
    "backButton2",
    "statusText",
    "linkStatus",
    "confirmCheckbox",
    "whatIsAShipVideo"
  ];

  connect() {
    this.escapeHandler = this.escapeHandler.bind(this);
    this.whatIsAShipVideo = new Vimeo.Player(this.whatIsAShipVideoTarget);

    document.addEventListener("keydown", this.escapeHandler);

    if (this.hasNo404CheckboxTarget && this.hasSubmitButtonTarget) {
      this.updateSubmitButton();
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler);
  }

  open() {
    this.modalTarget.classList.remove("hidden");

    // this.whatIsAShipVideo.play();

    document.body.classList.add("overflow-hidden");

    this.showPage(1);

    setTimeout(() => {
      const firstInput = this.modalTarget.querySelector("input, textarea");
      if (firstInput) firstInput.focus();
    }, 100);
  }

  close() {
    (async () => {
      await this.whatIsAShipVideo.setCurrentTime(0);
      await this.whatIsAShipVideo.pause();
    })();

    this.whatIsAShipVideoPaused = true;

    this.modalTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");
  }

  closeBackground(event) {
    if (event.target === this.modalTarget) {
      this.close();
    }
  }

  showPage(pageNumber) {
    this.page1Target.classList.add("hidden");
    this.page2Target.classList.add("hidden");
    this.page3Target.classList.add("hidden");

    if (this.hasNextButton1Target)
      this.nextButton1Target.classList.add("hidden");
    if (this.hasNextButton2Target)
      this.nextButton2Target.classList.add("hidden");
    if (this.hasBackButton1Target)
      this.backButton1Target.classList.add("hidden");
    if (this.hasBackButton2Target)
      this.backButton2Target.classList.add("hidden");

    if (pageNumber === 1) {
      this.page1Target.classList.remove("hidden");
      if (this.hasNextButton1Target)
        this.nextButton1Target.classList.remove("hidden");
    } else if (pageNumber === 2) {
      this.page2Target.classList.remove("hidden");
      if (this.hasNextButton2Target)
        this.nextButton2Target.classList.remove("hidden");
      if (this.hasBackButton1Target)
        this.backButton1Target.classList.remove("hidden");
    } else if (pageNumber === 3) {
      this.page3Target.classList.remove("hidden");
      if (this.hasBackButton2Target)
        this.backButton2Target.classList.remove("hidden");
    }
  }

  next1() {
    this.showPage(2);
  }

  next2() {
    const allRequirementsMet = this.element.querySelector(
      "#all-requirements-met",
    );

    if (allRequirementsMet && allRequirementsMet.value === "true") {
      this.showPage(3);
      this.checkLinks();
    } else {
      alert(
        "Please complete all the shipping requirements listed above before proceeding.\n\nEach requirement with a red message needs to be addressed.",
      );
    }
  }

  back1() {
    this.showPage(1);
  }

  back2() {
    this.showPage(2);
  }

  checkLinks() {
    const repoLink = this.element.querySelector("#repo-link").value;
    const readmeLink = this.element.querySelector("#readme-link").value;
    const demoLink = this.element.querySelector("#demo-link").value;

    this.statusTextTarget.textContent = "Checking links for 404 errors...";

    this.resetLinkStatus();

    const links = [
      { url: repoLink, name: "Repository" },
      { url: readmeLink, name: "Readme" },
      { url: demoLink, name: "Demo" },
    ];

    const validLinks = links.filter(
      (link) => link.url && link.url.trim() !== "",
    );

    if (validLinks.length === 0) {
      this.statusTextTarget.textContent = "No links to check.";
      return;
    }

    let completedChecks = 0;
    let allValid = true;

    this.confirmCheckboxTarget.style.cursor = "not-allowed";
    [...this.confirmCheckboxTarget.children].forEach((c) => {
      c.style.pointerEvents = "auto";
    });

    validLinks.forEach((link) => {
      this.checkLinkStatus(link.url, link.name).then((isValid) => {
        completedChecks++;

        if (!isValid) {
          allValid = false;
        }

        if (completedChecks === validLinks.length) {
          if (allValid) {
            const checkIcon = document
              .getElementById("valid-check-icon")
              .cloneNode(true);
            checkIcon.querySelector("svg").classList.add("h-5", "w-5");
            checkIcon.querySelector("svg").classList.remove("h-4", "w-4");
            this.statusTextTarget.innerHTML = "All links are valid! ";
            this.statusTextTarget.appendChild(checkIcon);
            this.statusTextTarget.classList.remove("text-vintage-red");
            this.statusTextTarget.classList.add("text-forest");

            // Enable confirm checkbox and label
            this.confirmCheckboxTarget.style.cursor = "default";
            [...this.confirmCheckboxTarget.children].forEach((c) => {
              c.style.pointerEvents = "default";
            });
          } else {
            this.statusTextTarget.textContent =
              "Some links returned errors. Please fix them before shipping.";
            this.statusTextTarget.classList.remove("text-forest");
            this.statusTextTarget.classList.add("text-vintage-red");
          }
        }
      });
    });
  }

  resetLinkStatus() {
    const statuses = this.linkStatusTargets;
    statuses.forEach((status) => {
      status.textContent = "Checking...";
      status.classList.remove("text-forest", "text-vintage-red");
      status.classList.add("text-gray-600");
    });
  }

  checkLinkStatus(url, linkName) {
    return new Promise((resolve) => {
      const statusElement = this.element.querySelector(
        `[data-link-name="${linkName}"]`,
      );
      let linkType = linkName.toLowerCase();

      if (linkType === "repository") linkType = "repo";
      if (linkType === "documentation") linkType = "readme";
      if (linkType === "demo") linkType = "demo";

      fetch("/check_link", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          url: url,
          link_type: linkType,
        }),
      })
        .then((response) => response.json())
        .then((data) => {
          console.log({ data });
          if (data.valid) {
            const checkIcon = document
              .getElementById("valid-check-icon")
              .cloneNode(true);
            statusElement.innerHTML = "Valid ";
            statusElement.appendChild(checkIcon);
            statusElement.classList.remove("text-gray-600", "text-vintage-red");
            statusElement.classList.add("text-forest");
            resolve(true);
          } else {
            statusElement.textContent = "Error: " + data.error;
            statusElement.classList.remove("text-gray-600", "text-forest");
            statusElement.classList.add("text-vintage-red");
            resolve(false);
          }
        })
        .catch((error) => {
          statusElement.textContent = "Could not check: " + error.message;
          statusElement.classList.remove("text-gray-600", "text-forest");
          statusElement.classList.add("text-vintage-red");
          resolve(false);
        });
    });
  }

  toggleNo404Check() {
    const checked = this.no404CheckboxTarget.checked;

    if (checked) {
      this.no404CheckTarget.classList.remove("hidden");
      this.no404CheckboxParentTarget.classList.add("checked");
    } else {
      this.no404CheckTarget.classList.add("hidden");
      this.no404CheckboxParentTarget.classList.remove("checked");
    }

    this.updateSubmitButton();
  }

  updateSubmitButton() {
    if (this.no404CheckboxTarget.checked) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.classList.remove("disabled");
    } else {
      this.submitButtonTarget.disabled = true;
      this.submitButtonTarget.classList.add("disabled");
    }
  }

  escapeHandler(event) {
    if (
      event.key === "Escape" &&
      !this.modalTarget.classList.contains("hidden")
    ) {
      this.close();
      event.stopPropagation();
    }
  }

  submit(event) {
    if (!this.no404CheckboxTarget.checked) {
      event.preventDefault();
      alert(
        "Please confirm that none of your project links return 404 errors.",
      );
      return;
    }
  }
}
