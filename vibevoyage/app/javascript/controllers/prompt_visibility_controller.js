import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "processing", "timeline"]

  connect() {
    this.showForm()
  }

  showForm() {
    this.formTarget.classList.remove("hidden")
    this.processingTarget.classList.add("hidden")
    if (this.hasTimelineTarget) {
      this.timelineTarget.classList.add("hidden")
    }
  }

  submitPrompt(event) {
    event.preventDefault()
    this.formTarget.classList.add("hidden")
    this.processingTarget.classList.remove("hidden")
    if (this.hasTimelineTarget) {
      setTimeout(() => {
        this.processingTarget.classList.add("hidden")
        this.timelineTarget.classList.remove("hidden")
      }, 2000) // Simula procesamiento AI
    }
    // Aquí puedes disparar la petición real al backend
  }
}
