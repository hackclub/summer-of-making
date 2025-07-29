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
    this.dragCounter = 0; // Track drag enter/leave events

    if (this.hasHackatimeSelectTarget) {
      this.hackatimeSelectTarget.addEventListener(
        "change",
        this.handleHackatimeSelection.bind(this),
      );
    }
  }



  validateFormFields() {
    this.clearErrors();
    let isValid = true;

    if (!this.titleTarget.value.trim()) {
      this.showError(this.titleErrorTarget, "Title is required");
      isValid = false;
    }

    if (!this.descriptionTarget.value.trim()) {
      this.showError(this.descriptionErrorTarget, "Description is required");
      isValid = false;
    }

    if (this.hasYswsSubmissionCheckboxRealTarget && this.yswsSubmissionCheckboxRealTarget.checked) {
      if (this.hasYswsTypeTarget && !this.yswsTypeTarget.value) {
        this.showError(this.yswsTypeErrorTarget, "Please select a YSWS program");
        isValid = false;
      }
    }

    const urlFields = [
      {
        field: this.readmeTarget,
        error: this.readmeErrorTarget,
        name: "Readme link",
      },
      {
        field: this.demoTarget,
        error: this.demoErrorTarget,
        name: "Demo link",
      },
      {
        field: this.repoTarget,
        error: this.repoErrorTarget,
        name: "Repository link",
      },
    ];

    urlFields.forEach(({ field, error, name }) => {
      const value = field.value.trim();
      if (value && !this.isValidUrl(value)) {
        this.showError(error, `${name} must be a valid URL`);
        isValid = false;
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
    
    if (!this.validateFormFields()) {
      return;
    }

    this.projectFormStepTarget.classList.add("hidden");
    this.rulesStepTarget.classList.remove("hidden");
    
    this.nextButtonTarget.classList.add("hidden");
    this.submitButtonTarget.classList.remove("hidden");
  }

  toggleRulesConfirmation(event) {
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
  }

  submitProject(event) {
    if (!this.rulesConfirmationCheckboxTarget.checked) {
      event.preventDefault();
      alert("You must agree to the rules and guidelines before proceeding.");
      return;
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
    errorElement.textContent = message;
    errorElement.classList.remove("hidden");
    const inputId = errorElement.id.replace("Error", "");
    const input = document.getElementById(inputId);
    if (input) {
      input.classList.add("border-vintage-red");
    }
  }

  clearErrors() {
    const errorTargets = [
      this.titleErrorTarget,
      this.descriptionErrorTarget,
      this.readmeErrorTarget,
      this.demoErrorTarget,
      this.repoErrorTarget,
    ];

    // Add YSWS type error if it exists
    if (this.hasYswsTypeErrorTarget) {
      errorTargets.push(this.yswsTypeErrorTarget);
    }

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
    const checked = this.yswsSubmissionCheckboxRealTarget.checked;
    const checkboxContainer = this.yswsSubmissionCheckboxFakeTarget.parentElement;

    if (checked) {
      this.yswsSubmissionCheckboxFakeTarget.classList.remove("hidden");
      checkboxContainer.classList.add("checked");

      // Show the YSWS type dropdown
      if (this.hasYswsTypeContainerTarget) {
        this.yswsTypeContainerTarget.classList.remove("hidden");
      }
    } else {
      this.yswsSubmissionCheckboxFakeTarget.classList.add("hidden");
      checkboxContainer.classList.remove("checked");
      
      // Hide the YSWS type dropdown and clear selection
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

    // Thanks Cursor for this one. If thou shall remove this code, thou shalt not be able to empty the hackatime_project_keys array.
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
    
    // Only apply styles on first drag enter
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
    
    // Only reset styles when completely leaving the drop zone
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
    
    // Reset drag counter and styles
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
