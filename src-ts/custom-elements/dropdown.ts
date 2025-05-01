/**
 * Custom element `<custom-dropdown>` that uses absolute positioning to place
 * itself right below its parent element. Useful as a `popovertarget`.
 */
export const defineDropdownCustomElement = () => {
  customElements.define(
    "custom-dropdown",
    class DropdownElement extends HTMLElement {
      constructor() {
        super();
      }

      observer?: IntersectionObserver;

      connectedCallback() {
        this.reposition();

        this.observer = new IntersectionObserver(() => this.reposition());
        this.observer.observe(this);
      }

      disconnectedCallback() {
        this.observer?.disconnect();
        this.observer = undefined;
      }

      /**
       * Positions the dropdown so that it's right below its parent element.
       */
      reposition() {
        const parentRect = this.parentElement?.getBoundingClientRect();
        const isVisible = this.checkVisibility();

        if (!parentRect || !isVisible) {
          return;
        }

        const selfRect = this.getBoundingClientRect();
        const parentWidth = parentRect.right - parentRect.left;
        const xParentMiddle = parentRect.left + parentWidth / 2;
        const selfWidth = selfRect.right - selfRect.left;
        const top = parentRect.bottom;
        const left = xParentMiddle - selfWidth / 2;

        this.style = `inset: unset; top: calc(0.5rem + ${top}px); left: ${left}px`;
      }
    },
  );
};
