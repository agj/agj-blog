import "@total-typescript/ts-reset";
import { fields, type Infer, primitiveUnion } from "tiny-decoders";
import { defineAudioPlayerCustomElement } from "./src-ts/custom-elements/audio-player.js";
import { defineDropdownCustomElement } from "./src-ts/custom-elements/dropdown.js";

defineAudioPlayerCustomElement();
defineDropdownCustomElement();

const setTheme = (theme: Theme) => {
  document.body.classList.remove("dark-theme");
  document.body.classList.remove("light-theme");
  if (theme !== null && (["dark", "light"] as const).includes(theme)) {
    document.body.classList.add(`${theme}-theme`);
  }
};

const config: ElmPagesInit = {
  flags: () => {
    const storedConfig = localStorage.getItem("config");
    const configDecodeResult = configDecoder.decoder(
      storedConfig ? JSON.parse(storedConfig) : {},
    );
    const config =
      configDecodeResult.tag === "Valid" ? configDecodeResult.value : null;

    const theme = {
      set: config?.theme ?? null,
      default: window.matchMedia?.("(prefers-color-scheme: dark)").matches
        ? "dark"
        : window.matchMedia?.("(prefers-color-scheme: light)").matches
          ? "light"
          : null,
    };

    setTheme(theme.set);

    return { ...config, theme };
  },

  load: async function (elmLoaded) {
    const app = await elmLoaded;
    console.log("App loaded", app);

    app.ports.sendToJs.subscribe(({ msg, value }) => {
      if (msg === "saveConfig") {
        localStorage.setItem("config", JSON.stringify(value));
      } else if (msg === "setTheme") {
        setTheme(value);
      }
    });

    window.addEventListener("popstate", (event) => {
      app.ports.receiveFromJs.send({
        msg: "urlChanged",
        value: location.href,
      });
    });
  },
};

// Decoders.

const themeDecoder = primitiveUnion(["dark", "light", null]);

const configDecoder = fields({
  theme: themeDecoder,
});

// Types.

type ElmPagesInit = {
  load: (elmLoaded: Promise<ElmApp>) => Promise<void>;
  flags: unknown;
};

type ElmApp = {
  ports: {
    sendToJs: InPort;
    receiveFromJs: OutPort;
  };
};

type InPort = {
  subscribe: (callback: (value: PortOutValue) => void) => void;
};

type OutPort = {
  send: (value: { msg: string; value: unknown }) => void;
};

type PortOutValue =
  | {
      msg: "saveConfig";
      value: { theme: Theme };
    }
  | {
      msg: "setTheme";
      value: Theme;
    };

type Theme = Infer<typeof themeDecoder>;

export default config;
