export const defineDropdownCustomElement = () => {
  customElements.define(
    "custom-dropdown",
    class DropdownElement extends HTMLElement {
      constructor() {
        super();
      }

      connectedCallback() {
        this.reposition();
      }

      /**
       * Positions the dropdown so that it's right below its parent element.
       */
      reposition() {
        const parentRect = this.parentElement?.getBoundingClientRect();

        if (!parentRect) {
          return;
        }

        const top = parentRect.bottom;
        const left = parentRect.left;

        this.style = `inset: unset; top: calc(0.5rem + ${top}px); left: ${left}px`;
      }
    },
  );
};
