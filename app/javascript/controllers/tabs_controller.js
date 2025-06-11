import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tabButton", "content"];
  static values = { currentTab: String };

  connect() {
    this.updateTabButtons();
  }

  switchTab(event) {
    const newTab = event.currentTarget.dataset.tab;
    this.currentTabValue = newTab;
    this.updateTabButtons();
    this.loadTabContent(newTab);
  }

  updateTabButtons() {
    this.tabButtonTargets.forEach((button) => {
      const isActive = button.dataset.tab === this.currentTabValue;
      const underline = button.querySelector('[data-kind="underline"]');

      if (isActive) {
        underline.classList.remove("opacity-0");
      } else {
        underline.classList.add("opacity-0");
      }
    });
  }

  loadTabContent(tab) {
    this.contentTargets.forEach((content) => {
      content.classList.add("hidden");
    });

    if (tab === "gallery") {
      const galleryContent = document.querySelector('[data-tab-content="gallery"]');
      if (galleryContent) {
        galleryContent.classList.remove("hidden");
      }
    } else {
      const devlogsContent = document.querySelector('[data-tab-content="explore"]');
      if (devlogsContent) {
        devlogsContent.classList.remove("hidden");
      }

      const devlogsListContainer = document.getElementById(
        "devlogs-list-container",
      );

      if (devlogsListContainer) {
        devlogsListContainer.innerHTML = `
          <div class="space-y-4 sm:space-y-6" id="devlogs-list">
          </div>
          <div id="load-more-devlogs">
          </div>
        `;
      }

      const devlogsList = document.getElementById("devlogs-list");
      const newInitialFrame = document.createElement("turbo-frame");
      newInitialFrame.id = "initial-devlogs";
      newInitialFrame.src = `/explore?tab=${tab}&format=turbo_stream`;
      newInitialFrame.loading = "eager";

      if (devlogsList) {
        devlogsList.appendChild(newInitialFrame);
      }
    }
  }
}
