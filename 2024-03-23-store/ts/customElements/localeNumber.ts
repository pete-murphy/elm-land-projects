/**
 * @example
 * <locale-number value="123456.789"></locale-number>
 *
 * @example
 * <locale-number locale="en-US" value="123456.789"></locale-number>
 *
 * @example
 * <locale-number locale="es" value="123456.789" fraction-digits="2"></locale-number>
 */
export class LocaleNumber extends HTMLElement {
  constructor() {
    super();
  }
  connectedCallback() {
    this.setTextContent();
  }
  attributeChangedCallback() {
    this.setTextContent();
  }
  static get observedAttributes() {
    return ["locale", "number", "fraction-digits"];
  }

  setTextContent() {
    const locale = this.getAttribute("locale") ?? undefined;
    const value = Number(this.getAttribute("value"));
    const fractionDigits = Number(this.getAttribute("fraction-digits")) ?? 0;

    this.textContent = value.toLocaleString(locale, {
      maximumFractionDigits: fractionDigits,
      minimumFractionDigits: fractionDigits,
    });
  }
}
