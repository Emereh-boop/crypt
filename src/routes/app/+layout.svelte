<script lang="ts">
  import { onMount } from "svelte";
  import { link, replace } from "svelte-spa-router";
  import active from "svelte-spa-router/active";

  let refreshInterval: NodeJS.Timeout;
  let firmwareVersion: string | null = null;

  // const logout = () => {
  //   document.cookie =
  //     "sessionId=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
  //   replace("/login");
  // };
  const authCheck = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "validate_session",
        }),
      });
      const resJson = await response.json();
      if (resJson.error === "Invalid Session") {
        replace("/");
      }
    } catch {
      replace("/");
    }
  };

  const fetchFirmwareVersion = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "firmw_version",
        }),
      });
      const resJson = await response.json();
      if (resJson.success === true) {
        firmwareVersion = resJson.data.firmware_version;
      }
    } catch {}
  };

  onMount(() => {
    fetchFirmwareVersion();
    authCheck();
    refreshInterval = setInterval(() => {
      authCheck();
    }, 5000);
    return () => {
      clearInterval(refreshInterval);
    };
  });
</script>

<title>MTN-NG</title>
<div class="flex flex-col min-h-screen w-">
  <header class="bg-primary">
    <div class="w-full container px-2 md:px-0 mx-auto">
      <div class="flex justify-between text-[13px] text-black">
        <div class="mt-[30px] mb-4">
          <img src="/logo.svg" alt="mtn-logo" class="w-[85px]" />
          <div class="ml-[8px] font-normal leading-[14.95px] mt-[4px]">
            Setup Your MTN Hotspot Hub
          </div>
        </div>
        <div class="flex self-center gap-[23px]">
          <img src="/logout-icon.svg" alt="logout-icon" class="w-[16px]" />
          <a href="/" class="mr-[1vw]">Logout</a>
        </div>
      </div>

      <nav class="w-full">
        <ul class="flex justify-center font-normal text-[14px] text-gray-400">
          <li
            use:active={{
              path: "/overview",
              className: "border-b-[3px] border-b-black",
            }}
            class=" py-2 px-4"
          >
            <a
              href="#/overview"
              use:link
              use:active={{
                path: "/overview",
                className: "text-black font-bold",
              }}>Overview</a
            >
          </li>
          <!-- <li
            class="py-2 px-4"
            use:active={{
              path: "/register",
              className: "border-b-[3px] border-b-black",
            }}
          >
            <a
              href="#/register"
              use:link
              use:active={{
                path: "/register",
                className: "text-black font-bold",
              }}>Register Hotspot Hub</a
            >
          </li> -->
          <!-- <li class="py-2 px-4">
          <a href="/">SMS/USSD</a>
        </li> -->
          <li
            class="py-2 px-4"
            use:active={{
              path: "/myhub",
              className: "border-b-[3px] border-b-black",
            }}
          >
            <a
              href="#/myhub"
              use:link
              use:active={{
                path: "/myhub",
                className: "text-black font-bold",
              }}>My Hub</a
            >
          </li>
          <li
            class="py-2 px-4"
            use:active={{
              path: "/settings",
              className: "border-b-[3px] border-b-black",
            }}
          >
            <a
              href="#/settings"
              use:link
              use:active={{
                path: "/settings",
                className: "text-black font-bold",
              }}>Settings</a
            >
          </li>
        </ul>
      </nav>
    </div>
  </header>
  <main class="flex-grow">
    <slot />
  </main>
  <footer
    class="container mx-auto flex justify-between py-12 px-4 md:px-0 text-[10px] font-normal text-gray-400"
  >
    <div>Copyright Wicrypt All Right Reserved © 2024</div>
    <div class=" text-gray-100">Powered by Wicrypt OS</div>
    <div>Firmware Version {firmwareVersion ?? "-.-.-"}</div>
  </footer>
</div>
