import NotFound from "./routes/NotFound.svelte";
import Overview from "./routes/app/+page.svelte";
import Register from "./routes/app/register/+page.svelte";
import Business from "./routes/app/linkHub/+page.svelte";
import WifiSettings from "./routes/app/settings/+page.svelte";
import Login from "./routes/auth/+page.svelte";
import ConnectedDevices from "./routes/app/connected-devices/+page.svelte";

export default {
  "/": Login,
  "/overview": Overview,
  "/connected-devices": ConnectedDevices,
  "/register": Register,
  "/business": Business,
  "/myhub": Business,
  "/settings": WifiSettings,
  "*": NotFound,
};
