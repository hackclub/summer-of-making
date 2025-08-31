import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "title",
    "description",
    "readme",
    "demo",
    "repo",
    "titleError",
    "descriptionError",
    "readmeError",
    "demoError",
    "repoError",
    "hackatimeProjects",
    "hackatimeSelect",
    "selectedProjects",
    "usedAiCheckboxReal",
    "usedAiCheckboxFake",
    "yswsSubmissionCheckboxReal",
    "yswsSubmissionCheckboxFake",
    "yswsTypeContainer",
    "yswsType",
    "yswsTypeError",
    "bannerInput",
    "bannerPreview",
    "bannerDropZone",
    "bannerDropText",
    "bannerTextContainer",
    "bannerOverlay",
    "projectFormStep",
    "rulesStep",
    "rulesConfirmationCheckbox",
    "rulesConfirmationCheckboxFake",
    "nextButton",
    "submitButton",
    "createButton",
  ];

  connect() {
    this.element.setAttribute("novalidate", true);
    this.dragCounter = 0;
    this.isSubmitting = false;
    this.isInitialized = false;
    this.initRetryCount = 0;
    this.maxRetries = 10;
    this.rulesRetryCount = 0;
    this.pendingTimeouts = [];

    requestAnimationFrame(() => {
      if (this.element) {
        this.initializeController();
      }
    });
  }

  initializeController() {
    if (!this.element) {
      return;
    }

    if (!this.verifyCriticalTargets()) {
      if (this.initRetryCount < this.maxRetries) {
        this.initRetryCount++;
        
        const timeoutId = setTimeout(() => {
          const index = this.pendingTimeouts.indexOf(timeoutId);
          if (index > -1) {
            this.pendingTimeouts.splice(index, 1);
          }
          
          if (this.element) {
            this.initializeController();
          }
        }, 100);
        
        this.pendingTimeouts.push(timeoutId);
      }
      return;
    }

    this.boundHandleHackatimeSelection = this.handleHackatimeSelection.bind(this);

    if (this.hasHackatimeSelectTarget) {
      this.hackatimeSelectTarget.addEventListener(
        "change",
        this.boundHandleHackatimeSelection,
      );
    }

    this.isInitialized = true;
  }

  disconnect() {
    this.isInitialized = false;
    
    this.initRetryCount = 0;
    this.rulesRetryCount = 0;
    
    if (this.pendingTimeouts) {
      this.pendingTimeouts.forEach(timeoutId => {
        clearTimeout(timeoutId);
      });
      this.pendingTimeouts = [];
    }
    
    if (this.hasHackatimeSelectTarget && this.boundHandleHackatimeSelection) {
      this.hackatimeSelectTarget.removeEventListener(
        "change",
        this.boundHandleHackatimeSelection,
      );
    }
  }

  verifyCriticalTargets() {
    const criticalTargets = [
      'hasTitleTarget',
      'hasDescriptionTarget'
    ];

    return criticalTargets.every(targetCheck => {
      return this[targetCheck];
    });
  }

  validateRulesStepContent() {
    if (!this.hasRulesStepTarget) {
      return false;
    }

    const rulesElement = this.rulesStepTarget;
    
    if (!rulesElement.children || rulesElement.children.length === 0) {
      console.warn("Rules step target exists but has no children");
      return false;
    }

    const hasVisibleContent = Array.from(rulesElement.children).some(child => {
      const computedStyle = window.getComputedStyle(child);
      return computedStyle.display !== 'none' && 
             computedStyle.visibility !== 'hidden' && 
             child.textContent.trim().length > 0;
    });

    if (!hasVisibleContent) {
      console.warn("Rules step target exists but has no visible content");
      return false;
    }

    if (this.hasRulesConfirmationCheckboxTarget) {
      const checkbox = this.rulesConfirmationCheckboxTarget;
      if (!checkbox.parentElement || !checkbox.parentElement.textContent.trim()) {
        console.warn("Rules confirmation checkbox exists but parent has no content");
        return false;
      }
    }

    return true;
  }



  validateFormFields() {
    if (!this.isInitialized) {
      return false;
    }

    this.clearErrors();
    let isValid = true;

    if (this.hasTitleTarget && !this.titleTarget.value.trim()) {
      if (this.hasTitleErrorTarget) {
        this.showError(this.titleErrorTarget, "Title is required");
      }
      isValid = false;
    }

    if (this.hasDescriptionTarget && !this.descriptionTarget.value.trim()) {
      if (this.hasDescriptionErrorTarget) {
        this.showError(this.descriptionErrorTarget, "Description is required");
      }
      isValid = false;
    }

    if (this.hasYswsSubmissionCheckboxRealTarget && this.yswsSubmissionCheckboxRealTarget.checked) {
      if (this.hasYswsTypeTarget && !this.yswsTypeTarget.value) {
        if (this.hasYswsTypeErrorTarget) {
          this.showError(this.yswsTypeErrorTarget, "Please select a YSWS program");
        }
        isValid = false;
      }
    }

    const urlFields = [];
    
    if (this.hasReadmeTarget && this.hasReadmeErrorTarget) {
      urlFields.push({
        field: this.readmeTarget,
        error: this.readmeErrorTarget,
        name: "Readme link",
      });
    }
    
    if (this.hasDemoTarget && this.hasDemoErrorTarget) {
      urlFields.push({
        field: this.demoTarget,
        error: this.demoErrorTarget,
        name: "Demo link",
      });
    }
    
    if (this.hasRepoTarget && this.hasRepoErrorTarget) {
      urlFields.push({
        field: this.repoTarget,
        error: this.repoErrorTarget,
        name: "Repository link",
      });
    }

    urlFields.forEach(({ field, error, name }) => {
      if (field && field.value) {
        const value = field.value.trim();
        if (value && !this.isValidUrl(value)) {
          this.showError(error, `${name} must be a valid URL`);
          isValid = false;
        }
      }
    });

    if (!isValid) {
      const firstError = this.element.querySelector(".text-vintage-red");
      if (firstError) {
        firstError.scrollIntoView({ behavior: "smooth", block: "center" });
      }
    }

    return isValid;
  }

  showRules(event) {
    if (event) {
      event.preventDefault();
    }
    
    if (!this.isInitialized) {
      return;
    }
    
    if (!this.validateFormFields()) {
      return;
    }

    if (!this.hasProjectFormStepTarget || !this.hasRulesStepTarget) {
      return;
    }

    if (!this.hasNextButtonTarget || !this.hasSubmitButtonTarget) {
      return;
    }

    if (!this.validateRulesStepContent()) {
      if (this.rulesRetryCount < this.maxRetries) {
        this.rulesRetryCount++;
        setTimeout(() => this.showRules(event), 100);
        return;
      }
    }

    this.rulesRetryCount = 0;

    this.projectFormStepTarget.classList.add("hidden");
    this.rulesStepTarget.classList.remove("hidden");
    
    this.nextButtonTarget.classList.add("hidden");
    this.submitButtonTarget.classList.remove("hidden");
  }

  toggleRulesConfirmation(event) {
    if (!this.hasRulesConfirmationCheckboxFakeTarget) {
      return;
    }

    const isChecked = event.target.checked;
    const checkboxContainer = this.rulesConfirmationCheckboxFakeTarget.parentElement;

    if (isChecked) {
      this.rulesConfirmationCheckboxFakeTarget.classList.remove("hidden");
      checkboxContainer.classList.add("checked");
      if (this.hasCreateButtonTarget) {
        this.createButtonTarget.disabled = false;
      }
    } else {
      this.rulesConfirmationCheckboxFakeTarget.classList.add("hidden");
      checkboxContainer.classList.remove("checked");
      if (this.hasCreateButtonTarget) {
        this.createButtonTarget.disabled = true;
      }
    }
  }

  validateForm(event) {
    if (!this.validateFormFields()) {
      event.preventDefault();
      return;
    }

    if (this.hasProjectFormStepTarget && !this.projectFormStepTarget.classList.contains("hidden")) {
      event.preventDefault();
      this.showRules();
      return;
    }
  }

  resetForm(event) {
    if (event) {
      event.preventDefault();
    }
    
    this.isSubmitting = false;
    
    this.rulesRetryCount = 0;
    
    if (this.hasRulesConfirmationCheckboxTarget) {
      this.rulesConfirmationCheckboxTarget.checked = false;
      if (this.hasRulesConfirmationCheckboxFakeTarget) {
        this.rulesConfirmationCheckboxFakeTarget.classList.add("hidden");
        const checkboxContainer = this.rulesConfirmationCheckboxFakeTarget.parentElement;
        checkboxContainer.classList.remove("checked");
      }
    }

    if (this.hasProjectFormStepTarget && this.hasRulesStepTarget) {
      this.projectFormStepTarget.classList.remove("hidden");
      this.rulesStepTarget.classList.add("hidden");
    }

    if (this.hasNextButtonTarget && this.hasSubmitButtonTarget) {
      this.nextButtonTarget.classList.remove("hidden");
      this.submitButtonTarget.classList.add("hidden");
    }

    if (this.hasCreateButtonTarget) {
      this.createButtonTarget.disabled = true;
      this.createButtonTarget.textContent = "Create Project";
    }
  }

  submitProject(event) {
    if (this.isSubmitting) {
      event.preventDefault();
      return;
    }

    if (!this.isInitialized) {
      event.preventDefault();
      return;
    }

    if (!this.hasRulesConfirmationCheckboxTarget || !this.rulesConfirmationCheckboxTarget.checked) {
      event.preventDefault();
      alert("You must agree to the rules and guidelines before proceeding.");
      return;
    }

    this.isSubmitting = true;
    
    if (this.hasCreateButtonTarget) {
      this.createButtonTarget.disabled = true;
      this.createButtonTarget.textContent = "Submitting...";
    }

    this.element.submit();
  }

  isValidUrl(string) {
    try {
      const url = new URL(string);
      return url.protocol === 'http:' || url.protocol === 'https:';
    } catch (_) {
      return false;
    }
  }

  showError(errorElement, message) {
    if (!errorElement) {
      console.error("Error element not found when trying to show error:", message);
      return;
    }
    
    errorElement.textContent = message;
    errorElement.classList.remove("hidden");
    
    if (errorElement.id) {
      const inputId = errorElement.id.replace("Error", "");
      const input = document.getElementById(inputId);
      if (input) {
        input.classList.add("border-vintage-red");
      }
    }
  }

  clearErrors() {
    if (!this.isInitialized) {
      return;
    }

    const errorTargets = [];
    
    if (this.hasTitleErrorTarget) errorTargets.push(this.titleErrorTarget);
    if (this.hasDescriptionErrorTarget) errorTargets.push(this.descriptionErrorTarget);
    if (this.hasReadmeErrorTarget) errorTargets.push(this.readmeErrorTarget);
    if (this.hasDemoErrorTarget) errorTargets.push(this.demoErrorTarget);
    if (this.hasRepoErrorTarget) errorTargets.push(this.repoErrorTarget);
    if (this.hasYswsTypeErrorTarget) errorTargets.push(this.yswsTypeErrorTarget);

    errorTargets.forEach((target) => {
      target.textContent = "";
      target.classList.add("hidden");
    });

    this.element.querySelectorAll("input, textarea, select").forEach((el) => {
      el.classList.remove("border-vintage-red");
    });
  }

  addHackatimeProject(event) {
    event.preventDefault();

    if (this.hasHackatimeSelectTarget) {
      this.hackatimeSelectTarget.selectedIndex = 0;
      this.hackatimeSelectTarget.classList.remove("hidden");
    }
  }

  handleHackatimeSelection(event) {
    const select = event.target;
    const selectedValue = select.value;
    const selectedOption = select.options[select.selectedIndex];

    if (!selectedValue || selectedValue === "") return;

    this.addProjectToSelected(selectedValue, selectedOption.text);
    selectedOption.disabled = true;
    select.selectedIndex = 0;
  }

  addProjectToSelected(key, text) {
    if (!this.hasSelectedProjectsTarget) return;

    const projectElement = document.createElement("div");
    projectElement.className = "flex items-center p-2";
    projectElement.dataset.projectKey = key;

    const formattedTime = text.match(/\(\d+h \d+m\)/)
      ? text.match(/\(\d+h \d+m\)/)[0]
      : "";
    const projectName = text.replace(/\s*\(\d+h \d+m\)/, "");

    projectElement.innerHTML = `
      <input type="hidden" name="project[hackatime_project_keys][]" value="${key}">
      <div class="flex-grow">
        <p class="font-bold">${projectName}</p>
        <p class="text-xs text-gray-600">Time tracked: ${formattedTime.replace(/[()]/g, "")}</p>
      </div>
      <button type="button" class="ml-2 text-vintage-red hover:text-red-700" data-action="click->project-form#removeSelectedProject">
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <path d="M5 5h2v2H5V5zm4 4H7V7h2v2zm2 2H9V9h2v2zm2 0h-2v2H9v2H7v2H5v2h2v-2h2v-2h2v-2h2v2h2v2h2v2h2v-2h-2v-2h-2v-2h-2v-2zm2-2v2h-2V9h2zm2-2v2h-2V7h2zm0 0V5h2v2h-2z" fill="currentColor"/>
        </svg>
      </button>
    `;

    this.selectedProjectsTarget.appendChild(projectElement);
  }

  toggleUsedAiCheck() {
    if (!this.hasUsedAiCheckboxRealTarget || !this.hasUsedAiCheckboxFakeTarget) {
      return;
    }

    const checked = this.usedAiCheckboxRealTarget.checked;
    const checkboxContainer = this.usedAiCheckboxFakeTarget.parentElement;

    if (checked) {
      this.usedAiCheckboxFakeTarget.classList.remove("hidden");
      checkboxContainer.classList.add("checked");
    } else {
      this.usedAiCheckboxFakeTarget.classList.add("hidden");
      checkboxContainer.classList.remove("checked");
    }
  }

  toggleYswsSubmission() {
    if (!this.hasYswsSubmissionCheckboxRealTarget || !this.hasYswsSubmissionCheckboxFakeTarget) {
      return;
    }

    const checked = this.yswsSubmissionCheckboxRealTarget.checked;
    const checkboxContainer = this.yswsSubmissionCheckboxFakeTarget.parentElement;

    if (checked) {
      this.yswsSubmissionCheckboxFakeTarget.classList.remove("hidden");
      checkboxContainer.classList.add("checked");

      if (this.hasYswsTypeContainerTarget) {
        this.yswsTypeContainerTarget.classList.remove("hidden");
      }
    } else {
      this.yswsSubmissionCheckboxFakeTarget.classList.add("hidden");
      checkboxContainer.classList.remove("checked");
      
      if (this.hasYswsTypeContainerTarget) {
        this.yswsTypeContainerTarget.classList.add("hidden");
        if (this.hasYswsTypeTarget) {
          this.yswsTypeTarget.selectedIndex = 0;
        }
      }
    }
  }

  removeSelectedProject(event) {
    event.preventDefault();
    let target = event.target;

    while (
      target &&
      !target.closest("[data-project-key]") &&
      target !== document.body
    ) {
      target = target.parentElement;
    }

    const projectElement = target ? target.closest("[data-project-key]") : null;
    if (!projectElement) return;

    const projectKey = projectElement.dataset.projectKey;
    if (this.hasHackatimeSelectTarget) {
      const select = this.hackatimeSelectTarget;
      for (let i = 0; i < select.options.length; i++) {
        if (select.options[i].value === projectKey) {
          select.options[i].disabled = false;
          break;
        }
      }
    }

    projectElement.remove();

    if (
      this.hasSelectedProjectsTarget &&
      this.selectedProjectsTarget.children.length === 0
    ) {
      const emptyInput = document.createElement("input");
      emptyInput.type = "hidden";
      emptyInput.name = "project[hackatime_project_keys][]";
      emptyInput.value = "";
      this.selectedProjectsTarget.appendChild(emptyInput);
    }
  }

  updateBannerPreview(event) {
    const file = event.target.files[0];
    if (file) {
      this.updateBannerFromFile(file);
    }
  }

  handleDragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
    
    if (this.dragCounter === 0) {
      if (this.hasBannerDropZoneTarget) {
        this.bannerDropZoneTarget.classList.add('border-forest', 'bg-forest/10');
        this.bannerDropZoneTarget.classList.remove('border-saddle-taupe');
      }
      
      if (this.hasBannerDropTextTarget) {
        this.bannerDropTextTarget.textContent = 'Drop to upload';
      }
      
      if (this.hasBannerTextContainerTarget) {
        this.bannerTextContainerTarget.classList.remove('opacity-0');
        this.bannerTextContainerTarget.classList.add('opacity-100');
      }
      
      if (this.hasBannerOverlayTarget) {
        this.bannerOverlayTarget.classList.add('!bg-[#F3ECD8]/75');
      }
    }
    
    this.dragCounter++;
  }

  handleDragLeave(event) {
    event.preventDefault();
    
    this.dragCounter--;
    
    if (this.dragCounter <= 0) {
      this.dragCounter = 0;
      
      if (this.hasBannerDropZoneTarget) {
        this.bannerDropZoneTarget.classList.remove('border-forest', 'bg-forest/10');
        this.bannerDropZoneTarget.classList.add('border-saddle-taupe');
      }
      
      if (this.hasBannerDropTextTarget) {
        this.bannerDropTextTarget.textContent = 'Upload a banner';
      }
      
      if (this.hasBannerTextContainerTarget) {
        this.bannerTextContainerTarget.classList.add('opacity-0');
        this.bannerTextContainerTarget.classList.remove('opacity-100');
      }
      
      if (this.hasBannerOverlayTarget) {
        this.bannerOverlayTarget.classList.remove('!bg-[#F3ECD8]/75');
      }
    }
  }

  handleDrop(event) {
    event.preventDefault();
    
    this.dragCounter = 0;
    
    if (this.hasBannerDropZoneTarget) {
      this.bannerDropZoneTarget.classList.remove('border-forest', 'bg-forest/10');
      this.bannerDropZoneTarget.classList.add('border-saddle-taupe');
    }
    
    if (this.hasBannerTextContainerTarget) {
      this.bannerTextContainerTarget.classList.add('opacity-0');
      this.bannerTextContainerTarget.classList.remove('opacity-100');
    }
    
    if (this.hasBannerOverlayTarget) {
      this.bannerOverlayTarget.classList.remove('!bg-[#F3ECD8]/75');
    }
    
    const files = event.dataTransfer.files;
    if (files.length > 0 && files[0].type.startsWith('image/')) {
      this.bannerInputTarget.files = files;
      this.updateBannerFromFile(files[0]);
    }
  }

  updateBannerFromFile(file) {
    if (file && this.hasBannerPreviewTarget) {
      const reader = new FileReader();
      reader.onload = (e) => {
        this.bannerPreviewTarget.src = e.target.result;
        this.bannerPreviewTarget.classList.remove('hidden');
        
        if (this.hasBannerDropZoneTarget) {
          this.bannerDropZoneTarget.classList.remove('bg-gray-100', 'bg-[#FFEAD0]');
        }
        
        if (this.hasBannerDropTextTarget) {
          this.bannerDropTextTarget.textContent = 'Upload a new banner';
        }
      };
      reader.readAsDataURL(file);
    }
  }
}
