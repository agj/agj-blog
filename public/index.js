
customElements.define('audio-player', class AudioPlayerElement extends HTMLElement {
  constructor() {
    super();
  }

  static get observedAttributes() {
    return ['src', 'playing', 'current-time'];
  }

  connectedCallback() {
    this.audioElement = new Audio();
    this.appendChild(this.audioElement);
    this.update();
  }

  attributeChangedCallback() {
    this.update();
  }

  disconnectedCallback() {
    this.audioElement?.stop?.();
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

    if (src !== currentSrc) {
      this.audioElement.setAttribute('src', src);
    }

    if (playing === 'true') {
      this.audioElement.play?.();
    } else {
      this.audioElement.pause?.();
    }
  }
});

/** @typedef {{load: (Promise<unknown>); flags: (unknown)}} ElmPagesInit */

/** @type ElmPagesInit */
export default {
  load: async function (elmLoaded) {
    const app = await elmLoaded;
    console.log("App loaded", app);
  },
  flags: function () {
    return "You can decode this in Shared.elm using Json.Decode.string!";
  },
};
