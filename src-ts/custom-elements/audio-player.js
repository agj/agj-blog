
export const defineAudioPlayerCustomElement = () => {
  customElements.define('audio-player', class AudioPlayerElement extends HTMLElement {
    constructor() {
      super();
    }

    static get observedAttributes() {
      return ['src', 'playing', 'current-time'];
    }

    connectedCallback() {
      this.audioElement = new Audio();

      this.onTimeUpdate = (event) => {
        this.dispatchEvent(new CustomEvent('timeupdate', {
          detail: {
            currentTime: this.audioElement.currentTime,
            duration: this.audioElement.duration
          },
        }));
      };
      this.audioElement.addEventListener('timeupdate', this.onTimeUpdate);

      this.appendChild(this.audioElement);
      this.update();
    }

    attributeChangedCallback() {
      this.update();
    }

    disconnectedCallback() {
      this.audioElement?.stop?.();
      this.audioElement?.removeEventListener('timeupdate', this.onTimeUpdate);
      this.audioElement = null;
    }

    update() {
      if (!this.audioElement) {
        return;
      }

      const src = this.getAttribute('src');
      const playing = this.getAttribute('playing');
      const currentTime = this.getAttribute('current-time');

      const currentSrc = this.audioElement.getAttribute('src');
      const currentCurrentTime = this.audioElement.currentTime;

      if (src !== currentSrc) {
        this.audioElement.setAttribute('src', src);
      }

      if (Math.abs(currentTime - currentCurrentTime) > 2) {
        this.audioElement.currentTime = currentTime;
      }

      if (playing === 'true') {
        this.audioElement.play?.();
      } else {
        this.audioElement.pause?.();
      }
    }
  });
};
