export class CollapsibleHeader extends HTMLElement {
  constructor() {
    super();
  }
  connectedCallback() {
    this.attachScrollListener();
  }
  attributeChangedCallback() {}

  attachScrollListener() {
    let previousScrollY = 0;
    let offset = 0;
    let shadowOpacity = 0;

    window.addEventListener(
      "scroll",
      () => {
        const navHeight = this.getBoundingClientRect().height;
        offset = Math.max(
          0,
          Math.min(
            navHeight,
            offset + window.scrollY - previousScrollY,
            window.scrollY
          )
        );
        shadowOpacity = Math.min(
          1 - offset / navHeight,
          (window.scrollY - navHeight) / navHeight,
          1
        );
        this.style.setProperty("transform", `translateY(-${offset}px)`);
        this.style.setProperty("--shadow-opacity", `${shadowOpacity}`);
        previousScrollY = window.scrollY;
      },
      { passive: true }
    );
  }
}
