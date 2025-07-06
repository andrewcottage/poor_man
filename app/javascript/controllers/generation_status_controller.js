import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { 
    url: String,
    complete: Boolean,
    interval: { type: Number, default: 5000 }
  }

  connect() {
    console.log("Generation status controller connected");
    if (!this.completeValue) {
      this.startPolling();
    }
  }

  disconnect() {
    this.stopPolling();
  }

  startPolling() {
    console.log("Starting polling for generation status");
    this.pollTimer = setInterval(() => {
      this.checkStatus();
    }, this.intervalValue);
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue + ".json");
      const data = await response.json();
      
      if (data.complete) {
        console.log("Generation complete, refreshing page");
        this.stopPolling();
        location.reload();
      } else {
        console.log("Generation still in progress");
      }
    } catch (error) {
      console.error("Error checking generation status:", error);
    }
  }
} 