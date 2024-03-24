import { CollapsibleHeader } from "./customElements/collapsibleHeader";
import { LocaleNumber } from "./customElements/localeNumber";
import "@github/relative-time-element";

export function register() {
  customElements.define("collapsible-header", CollapsibleHeader);
  customElements.define("locale-number", LocaleNumber);
}
