import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["step", "counter", "timer"];

  connect() {
    this.index = 0;
    this.update();
    this.requestWakeLock();
  }

  disconnect() {
    if (this.wakeLock) {
      this.wakeLock.release();
    }
    clearInterval(this.timerInterval);
  }

  next() {
    this.index = Math.min(this.index + 1, this.stepTargets.length - 1);
    this.update();
  }

  previous() {
    this.index = Math.max(this.index - 1, 0);
    this.update();
  }

  startTimer() {
    const minutes = parseInt(this.currentStepTarget.dataset.timerMinutes || "0", 10);
    if (!minutes) {
      this.timerTarget.textContent = "No timer in this step";
      return;
    }

    let remaining = minutes * 60;
    clearInterval(this.timerInterval);
    this.renderTimer(remaining);

    this.timerInterval = setInterval(() => {
      remaining -= 1;
      this.renderTimer(remaining);

      if (remaining <= 0) {
        clearInterval(this.timerInterval);
        this.timerTarget.textContent = "Timer complete";
      }
    }, 1000);
  }

  update() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle("hidden", index !== this.index);
    });

    this.counterTarget.textContent = `${this.index + 1} / ${this.stepTargets.length}`;
    this.timerTarget.textContent = "No timer set";
  }

  renderTimer(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    this.timerTarget.textContent = `${minutes}:${remainingSeconds.toString().padStart(2, "0")} remaining`;
  }

  get currentStepTarget() {
    return this.stepTargets[this.index];
  }

  async requestWakeLock() {
    if (!("wakeLock" in navigator)) return;

    try {
      this.wakeLock = await navigator.wakeLock.request("screen");
    } catch (_error) {
      // Ignore unsupported wake lock failures.
    }
  }
}
