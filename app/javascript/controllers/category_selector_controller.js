import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "hiddenField"];
  static values = { selected: String };

  connect() {
    this.updateButtons();
  }

  selectCategory(event) {
    const category = event.currentTarget.dataset.category;
    this.selectedValue = category;
    this.hiddenFieldTarget.value = category;
    this.updateButtons();
  }

  updateButtons() {
    this.buttonTargets.forEach((button) => {
      const isSelected = button.dataset.category === this.selectedValue;
      
      if (isSelected) {
        button.classList.add("tab-element");
      } else {
        button.classList.remove("tab-element");
      }
    });
  }
}
