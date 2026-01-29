import { setGlobalOptions } from "firebase-functions";

setGlobalOptions({ maxInstances: 10 });

// Export handlers
export { validateMatchUpdateHandler as validateMatchUpdate } from "./handlers/validateMatch";
