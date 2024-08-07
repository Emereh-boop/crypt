<script lang="ts">
  import { onMount } from "svelte";
  import Layout from "../+layout.svelte";

  let devRegistered = false;
  let registrationSuccessful = false;
  let hubOwnerEmail: String | null = null;
  let errorMsg: string | null = null;
  let successMsg: string | null = null;
  let firmwareEnabled: boolean | null = null;
  let progress = 0;
  let showProgress = false;
  let code = "";

  const fetchRegStatus = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "reg_status",
        }),
      });
      const resp = await response.json();
      if (resp.isSuccessful) {
        devRegistered = resp.data.isRegistered;
      } else {
        errorMsg = resp.message;
      }
    } catch (e) {
      errorMsg = "Failed to fetch registration status";
    }
  };

  const fetchFirmwareStatus = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "firmw_status",
        }),
      });
      const resp = await response.json();
      firmwareEnabled = resp.spikeserviceprocd.enabled;
    } catch (e) {}
  };

  const saveChanges = async (event: any) => {
    event.preventDefault();
    errorMsg = null;
    successMsg = null;
    if (firmwareEnabled === null) {
      return;
    }
    if (!devRegistered) {
      errorMsg = "Device not registered";
      return;
    }
    if (firmwareEnabled) {
      progress = 0;
      try {
        const interval = setInterval(
          () => {
            progress += 1;
            if (progress >= 100) {
              clearInterval(interval);
            }
          },
          (100 * 1000) / 100
        );
        showProgress = true;
        const response = await fetch(
          "http://192.168.0.1:8080/cgi-bin/api.cgi",
          {
            method: "POST",
            credentials: "include",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              cmd: "setup_firmw",
            }),
          }
        );
        const resp = await response.json();
        if (resp.success) {
          progress = 90;
          const response_e = await fetch(
            "http://192.168.0.1:8080/cgi-bin/api.cgi",
            {
              method: "POST",
              credentials: "include",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                cmd: "firmw_enable",
              }),
            }
          );
          const resp_e = await response_e.json();
          if (resp_e.success) {
            successMsg = "Business enabled successfully";
            clearInterval(interval);
            progress = 100;
          } else {
            errorMsg = resp.message;
            clearInterval(interval);
            progress = 100;
            showProgress = false;
          }
        } else {
          errorMsg = resp.message;
          clearInterval(interval);
          progress = 100;
          showProgress = false;
        }
      } catch (e) {
        errorMsg = "Failed to save changes";
        clearInterval(interval);
        progress = 100;
        showProgress = false;
      }
    } else {
      try {
        const response = await fetch(
          "http://192.168.0.1:8080/cgi-bin/api.cgi",
          {
            method: "POST",
            credentials: "include",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              cmd: "firmw_disable",
            }),
          }
        );
        const resp = await response.json();
        if (resp.success) {
          successMsg = "Business disabled successfully";
        } else {
          errorMsg = resp.message;
        }
      } catch (error) {
        errorMsg = "Failed to save changes";
      }
    }
  };

  // async function handlePaste() {
  //   try {
  //     if (navigator.clipboard) {
  //       const text = await navigator.clipboard.readText();
  //       code = text;
  //     } else if (document.execCommand) {
  //       const pasteTarget = document.getElementById("code");
  //       pasteTarget.focus();
  //       document.execCommand("paste");
  //       code = pasteTarget.value;
  //     } else {
  //       alert("Your browser doesn't support any known clipboard methods");
  //     }
  //   } catch (err) {
  //     console.error("Failed to paste text: ", err);
  //   }
  // }
  const handleModeChange = (event: any) => {
    firmwareEnabled = event.target.id === "enable-business";
  };
  async function enableBusiness() {
    progress = 0;
    try {
      const interval = setInterval(
        () => {
          progress += 1;
          if (progress >= 100) {
            clearInterval(interval);
          }
        },
        (100 * 1000) / 100
      );
      showProgress = true;
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "setup_firmw",
        }),
      });
      const resp = await response.json();
      if (resp.success) {
        progress = 90;
        const response_e = await fetch(
          "http://192.168.0.1:8080/cgi-bin/api.cgi",
          {
            method: "POST",
            credentials: "include",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              cmd: "firmw_enable",
            }),
          }
        );
        const resp_e = await response_e.json();
        if (resp_e.success) {
          successMsg = "Business enabled successfully";
          clearInterval(interval);
          progress = 100;
        } else {
          errorMsg = resp.message;
          clearInterval(interval);
          progress = 100;
          showProgress = false;
        }
      } else {
        errorMsg = resp.message;
        clearInterval(interval);
        progress = 100;
        showProgress = false;
      }
    } catch (e) {
      const interval = setInterval(
        () => {
          progress += 1;
          if (progress >= 100) {
            clearInterval(interval);
          }
        },
        (100 * 1000) / 100
      );
      errorMsg = "Failed to save changes";
      clearInterval(interval);
      progress = 100;
      showProgress = false;
    }
  }

  onMount(() => {
    fetchRegStatus();
    fetchFirmwareStatus();
  });
  async function link_hub(event: any) {
    event.preventDefault();
    errorMsg = null;
    const formData = new FormData(event.target);
    const code = formData.get("code");
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "link_hub",
          code: code,
        }),
      });

      if (response.ok) {
        let res = await response.json();
        if (res.isSuccessful === true) {
          registrationSuccessful = true;
          hubOwnerEmail = res.data.hubOwnerEmail;
          enableBusiness();
          errorMsg = null;
        } else {
          errorMsg = res.message;
        }
      } else {
        errorMsg = "Registration failed: Network error";
      }
    } catch (err) {
      errorMsg = "An error occurred";
    }
  }
</script>

<Layout>
  <div class="lg:grid lg:grid-cols-12 container mx-auto">
    <div class="col-span-2 flex justify-between md:justify-center">
      <div class="flex col-span-2 items-start justify-center p-[35.5px]">
        <a href="#/overview" class=" my-[4px] gap-[12px] ml-3 flex"
          ><img
            src="/backArrowIcon.svg"
            class="w-[12.41px] ml-[7px]"
            alt="view-all-connected-devices-icon"
          />Previous
        </a>
      </div>
      <div class="flex md:hidden items-start justify-center p-[35.5px]">
        <a href="#/settings" class=" my-[4px] ml-3 flex"
          >Next <img
            src="/foward-icon.svg"
            class="w-[12.41px] ml-[7px]"
            alt="view-all-connected-devices-icon"
          /></a
        >
      </div>
    </div>
    <div
      class="lg:col-span-8 col-start-2 p-[39px] border shadow-xl min-h-[420px]"
    >
      {#if errorMsg}
        <div
          class="border-peach-400 mb-[16px] bg-peach-100 w-full sm:w-4/5 lg:w-3/5 rounded-[4px] p-4 border flex items-center"
        >
          <img src="/info-red.svg" class=" col-span-1 mr-4" alt="" />
          <p class="text-gray-400 col-span-4">{errorMsg}</p>
        </div>
      {/if}
      {#if successMsg}
        <div
          class="border-black mb-[16px] w-full sm:w-4/5 lg:w-3/5 rounded-[4px] p-4 border flex items-center"
        >
          <img src="/info-icon.svg" class=" col-span-1 mr-4" alt="" />
          <p class="text-gray-400 col-span-4">{successMsg}</p>
        </div>
      {/if}
      <div class="h-[205px] justify-evenly flex flex-col">
        <div>
          <div class="text-[18px] font-bold text-black">
            Link Hub to your account
          </div>
          <p class="text-gray-400">
            Copy your 6-digit link code from your dashboard to link your hub
          </p>
        </div>
        {#if devRegistered}
          <div
            class="ring-[#00C087]/50 bg-[#00C087]/20 mb-[16px] w-full sm:w-4/5 lg:w-3/5 rounded-[4px] p-4 border flex items-center"
          >
            <img class="col-span-1 mr-4" src="/Check circle.svg" alt="" />
            <p class="text-gray-400 col-span-4">Your Hub is Linked</p>
          </div>
        {:else if !devRegistered}
          <form
            on:submit={link_hub}
            class="h-[112px] flex flex-col justify-between w-[389px]"
          >
            <!-- Pin  -->
            <div
              class="w-[385px] h-[35px] gap-[35px] flex text-[13px] items-center text-gray-400"
            >
              <label for="linkCode">Link Code: </label>
              <div
                class="flex ring-1 ring-[#C4C4C4] rounded-[16px] p-4 items-center h-[35px] w-[255px]"
              >
                <input
                  type="text"
                  name="code"
                  id="code"
                  placeholder="12345"
                  required
                  maxlength="10"
                  bind:value={code}
                  class="flex-1 font-mono text-[#1d1d1d] h-[35px] focus:outline-none"
                />
              </div>
            </div>
            <!-- Register -->
            <button
              type="submit"
              class="text-[14px] px-12 self-center bg-primary text-white h-[37px] w-[134px] rounded-[20px]"
            >
              Register
            </button>
          </form>
        {:else if registrationSuccessful}
          <div
            class="h-[43px] w-[457px] ring-1 ring-[#00C087]/50 rounded-[12px] text-[14px] font-[700] text-[#00C087] bg-[#00C087]/10 flex justify-around self-center items-center"
          >
            <p>{hubOwnerEmail} is linked</p>
            <img
              class="w-[24px] h-[24px]"
              src="/Check circle.svg"
              alt="check circle"
            />
          </div>
        {/if}
      </div>

      <hr class="my-10" />
      <div>
        <!-- <div class="grid grid-cols-3 gap-2">
          <div class="col-span-2">
            <div class="text-[18px] font-bold text-black">Hub switch</div>
            <p class="mt-[14px] text-gray-400">
              This tab allows you to switch preference of your smart Hotspot Hub
              option either for Personal Mode or Business Mode
            </p>
          </div>
        </div>
        <div class="mt-[37px] col-span-1 flex justify-between h-[37px]">
          <div class="flex gap-10 self-start">
            <div class="flex flex-row-reverse gap-5">
              <input
                type="radio"
                name="fm"
                id="enable-business"
                value="enabled"
                on:change={handleModeChange}
                checked={firmwareEnabled}
                style="box-shadow: inset 0 0 0 2px white;"
                class="appearance-none w-[21px] h-[21px] border-[2px] rounded-full border-primary checked:bg-primary"
              />
              <label for="enable-business" class="ml-2">Personal</label>
            </div>
            <div class="flex flex-row-reverse gap-5">
              <input
                type="radio"
                name="fm"
                id="disable-business"
                on:change={handleModeChange}
                checked={firmwareEnabled === false}
                style="box-shadow: inset 0 0 0 2px white;"
                class="appearance-none w-[21px] h-[21px] border-[2px] rounded-full border-primary checked:bg-primary"
              />
              <label for="disable-business" class="ml-2">Business</label>
            </div>
          </div>
          <button
            type="submit"
            class="text-[14px] px-12 bg-primary text-white h-[37px] rounded-[20px]"
          >
            Submit
          </button>
        </div>

        <div class="text-black text-[16px] font-bold mt-[24px]">
          Personal Mode
        </div>
        <p class="text-gray-400 mt-[4px]">
          Personal Mode is designed for individual use, specifically for
          personal use. It offers easy device connection as a key benefit. Here
          the splash screen page is disabled as users don't require it
          for login purposes.
        </p>
        <div class="text-black text-[16px] font-bold mt-[24px]">
          Business Mode
        </div>
        <p class="text-gray-400 mt-[4px]">
          Business Mode is a versatile system tailored for home, business, and
          enterprise environments. It allows administrators to manage
          connections using various tokens and limits via a hub admin. Suitable
          for homes, businesses, enterprises, and public domains alike, this
          mode has a wide range of applications such as timed tokens, parental
          controls, ad sharing, and custom forms. Internet access is restricted
          via a splash screen, enabling only authorized users to connect.
        </p> -->

        {#if showProgress}
          <div class="grid grid-cols-3 md:grid-cols-12 mt-6">
            <div
              class="col-span-3 md:col-span-10 relative h-4 bg-primary/20 rounded-full"
            >
              <div
                class="absolute h-full bg-primary rounded-full"
                style="width: {progress}%;"
              ></div>
              <span
                class="absolute inset-0 flex items-center justify-center text-gray-400 font-bold text-[14px]"
                >Setting up...</span
              >
            </div>
            <span
              class=" hidden md:block pl-3 md:col-span-2 font-normal text-[14px] text-primary"
              >{progress}%</span
            >
          </div>
        {/if}
      </div>
    </div>
    <div
      class="hidden md:flex col-span-2 col-start-11 items-start justify-center p-[35.5px]"
    >
      <a href="#/settings" class=" my-[4px] ml-3 flex"
        >Next <img
          src="/foward-icon.svg"
          class="w-[12.41px] ml-[7px]"
          alt="view-all-connected-devices-icon"
        /></a
      >
    </div>
  </div>
</Layout>
