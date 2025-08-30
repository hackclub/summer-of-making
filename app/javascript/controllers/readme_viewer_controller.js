import { Controller } from "@hotwired/stimulus";
import { marked } from "marked";

export default class extends Controller {
    static targets = ["content"];
    static values = { url: String };

    connect() {
        this.loadReadme();
    }

    loadReadme() {
        if (!this.urlValue) return;

        marked.setOptions({
            breaks: true,
            gfm: true
        });

        fetch(this.urlValue)
            .then(response => {
                if (!response.ok) throw new Error('Failed to fetch README');
                return response.text();
            })
            .then(text => {
                const html = marked.parse(text);
                this.contentTarget.innerHTML = `<div class="markdown-content max-w-none">${html}</div>`;
            })
            .catch(error => {
                this.contentTarget.innerHTML = `<p class="text-vintage-red">Failed to load README: ${error.message}</p>`;
            });
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}