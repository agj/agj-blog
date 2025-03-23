import { defineAudioPlayerCustomElement } from "./src-ts/custom-elements/audio-player.js";

defineAudioPlayerCustomElement();

type ElmPagesInit = {
  load: (elmLoaded: Promise<unknown>) => Promise<void>;
  flags: unknown;
};

const setTheme = (theme: string) => {
  document.body.classList.remove("dark-theme");
  document.body.classList.remove("light-theme");
  if (["dark", "light"].includes(theme)) {
    document.body.classList.add(`${theme}-theme`);
  }
};

const config: ElmPagesInit = {
  flags: () => {
    const configRaw = localStorage.getItem("config");
    const config = configRaw ? JSON.parse(configRaw) : null;
    const theme = {
      set: config.theme,
      default: window.matchMedia?.("(prefers-color-scheme: dark)").matches
        ? "dark"
        : window.matchMedia?.("(prefers-color-scheme: light)").matches
          ? "light"
          : null,
    };

    setTheme(theme.set);

    return {
      ...config,
      theme,
    };
  },

  load: async function (elmLoaded) {
    const app = await elmLoaded;
    console.log("App loaded", app);

    app.ports.saveConfig.subscribe((config) => {
      localStorage.setItem("config", JSON.stringify(config));
    });

    app.ports.setTheme.subscribe(setTheme);
  },
};

export default config;
