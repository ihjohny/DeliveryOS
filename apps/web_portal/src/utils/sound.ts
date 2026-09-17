/**
 * Sound Alert Engine for DeliveryOS Web Portal
 * Supports both Web Audio API synthetic bell chimes (zero external assets)
 * and optional HTMLAudioElement file playback (/sounds/order-alarm.mp3).
 */

class SoundEngine {
  private audioCtx: AudioContext | null = null;
  private alarmInterval: number | null = null;
  private audioTag: HTMLAudioElement | null = null;
  private isMuted: boolean = false;

  constructor() {
    // Unlock Web Audio API on first user gesture
    if (typeof window !== 'undefined') {
      const unlock = () => {
        this.getAudioContext();
        window.removeEventListener('click', unlock);
        window.removeEventListener('keydown', unlock);
        window.removeEventListener('touchstart', unlock);
      };
      window.addEventListener('click', unlock, { once: true });
      window.addEventListener('keydown', unlock, { once: true });
      window.addEventListener('touchstart', unlock, { once: true });
    }
  }

  private getAudioContext(): AudioContext | null {
    if (!this.audioCtx && typeof window !== 'undefined') {
      const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioContextClass) {
        this.audioCtx = new AudioContextClass();
      }
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
    return this.audioCtx;
  }

  public setMuted(muted: boolean) {
    this.isMuted = muted;
    if (muted) {
      this.stopOrderAlarm();
    }
  }

  public getIsMuted(): boolean {
    return this.isMuted;
  }

  /**
   * Synthesizes a bright, pleasant notification chime (D5 -> A5)
   */
  public playChime() {
    if (this.isMuted) return;
    const ctx = this.getAudioContext();
    if (!ctx) return;

    try {
      const now = ctx.currentTime;

      // Note 1: 587.33 Hz (D5)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(587.33, now);
      gain1.gain.setValueAtTime(0.3, now);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.5);

      // Note 2: 880 Hz (A5)
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(880, now + 0.15);
      gain2.gain.setValueAtTime(0.35, now + 0.15);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.7);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.15);
      osc2.stop(now + 0.7);
    } catch (e) {
      console.warn('SoundEngine chime error:', e);
    }
  }

  /**
   * Starts a persistent kitchen order alarm loop until acknowledged
   */
  public startOrderAlarm() {
    if (this.isMuted || this.alarmInterval) return;

    // Try HTML Audio element first if file exists
    if (!this.audioTag && typeof window !== 'undefined') {
      this.audioTag = new Audio('/sounds/order-alarm.mp3');
      this.audioTag.loop = true;
    }

    if (this.audioTag) {
      this.audioTag.play().catch(() => {
        // Fallback to synthetic alarm chime loop
        this.playChime();
        this.alarmInterval = window.setInterval(() => {
          this.playChime();
        }, 3000);
      });
    } else {
      this.playChime();
      this.alarmInterval = window.setInterval(() => {
        this.playChime();
      }, 3000);
    }
  }

  /**
   * Stops the ongoing kitchen order alarm
   */
  public stopOrderAlarm() {
    if (this.alarmInterval) {
      clearInterval(this.alarmInterval);
      this.alarmInterval = null;
    }
    if (this.audioTag) {
      this.audioTag.pause();
      this.audioTag.currentTime = 0;
    }
  }
}

export const soundEngine = new SoundEngine();
