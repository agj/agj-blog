import { defineAudioPlayerCustomElement } from "./src-ts/custom-elements/audio-player.js";

defineAudioPlayerCustomElement();

type ElmPagesInit = {
  load: (elmLoaded: Promise<unknown>) => Promise<void>;
  flags: unknown;
};

const config: ElmPagesInit = {
  flags: () => {
    const configRaw = localStorage.getItem("config");
    const config = configRaw ? JSON.parse(configRaw) : null;
    return config;
  },

  load: async function (elmLoaded) {
    const app = await elmLoaded;
    console.log("App loaded", app);

    app.ports.saveConfig.subscribe((config) => {
      localStorage.setItem("config", JSON.stringify(config));
    });
  },
};

export default config;
