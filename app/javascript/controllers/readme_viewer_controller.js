import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];
  static values = { url: String, projectId: Number };

  connect() {
    this.loadReadme();
  }

  loadReadme() {
    const projectId = this.projectIdValue;
    console.log(projectId);
    this.contentTarget.innerHTML = `<div class="flex justify-center items-center h-64"><div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-forest"></div></div>`;
    fetch(`/projects/${projectId}/render_readme`)
      .then(response => {
        if (!response.ok) throw new Error('Failed to fetch README');
        return response.json();
      })
      .then(data => {
        if (data.error) {
          this.contentTarget.innerHTML = `<p class="text-vintage-red">${data.error}</p>`;
        } else {
          this.contentTarget.innerHTML = `<div class="markdown-content max-w-none">${data.html}</div>`;
        }
      })
      .catch(error => {
        this.contentTarget.innerHTML = `<p class="text-vintage-red">Failed to load README: ${error.message}</p>`;
      });
  }
}