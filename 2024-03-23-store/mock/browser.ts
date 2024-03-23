import { setupWorker } from "msw/browser";
import { handlers, run } from "./handlers";

export const worker = setupWorker(...handlers);
run();
