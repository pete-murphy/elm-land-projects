import { setupWorker } from "msw/browser";
import { handlers, createPosts } from "./handlers";

export const worker = setupWorker(...handlers);
createPosts();
