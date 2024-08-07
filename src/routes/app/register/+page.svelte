<script lang="ts">
  import Layout from "../+layout.svelte";

  let registrationSuccessful = false;
  let errorMsg: string | null = null;

  async function registerDevice(event: any) {
    event.preventDefault();
    errorMsg = null;
    const formData = new FormData(event.target);
    const email = formData.get("email");
    const pin = formData.get("pin");
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "register_device",
          email: email,
          pin: pin,
        }),
      });

      if (response.ok) {
        let res = await response.json();
        if (res.isSuccessful === true) {
          registrationSuccessful = true;
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
    <div class="lg:col-span-2"></div>
    <div
      class="lg:col-span-8 p-[39px] pt-[67px] border shadow-xl min-h-[420px]"
    >
      <img src="/logo.svg" alt="mtn-log" class="w-[64px] h-[32px]" />
      <div class="text-black text-[18px] font-bold mt-[21px]">
        MTN Hotspot Hub Registration
      </div>
      <div class="my-[34px] text-gray-400">
        Connect your hub to your MTN account to enjoy our services
      </div>
      {#if registrationSuccessful}
        <div class="w-full flex flex-col items-center mt-[100px]">
          <img
            src="/success-icon.svg"
            alt="mtn-log"
            class="w-[80px] h-[80px]"
          />
          <div class="my-[34px] text-gray-400">
            Your device is registered successfully
          </div>
        </div>
      {:else}
        {#if errorMsg}
          <div
            class="border-peach-400 mb-[34px] bg-peach-100 w-full sm:w-4/5 lg:w-3/5 rounded-[4px] p-4 border flex items-center"
          >
            <img src="/info-red.svg" class=" col-span-1 mr-4" alt="" />
            <p class="text-gray-400 col-span-4">{errorMsg}</p>
          </div>
        {/if}
        <form on:submit={registerDevice} class="w-full max-w-[450px]">
          <!-- Email  -->
          <div class="flex items-center mb-[20px]">
            <label for="ssid" class="text-gray-400 w-[141px] flex-none"
              >Email:</label
            >
            <input
              type="text"
              id="email"
              name="email"
              required
              placeholder="judasdoe@example.com"
              class="flex-1 font-mono text-gray-400 h-[35px] border rounded-sm border-gray-100 focus:border-primary focus:outline-none hover:border-primary px-[19px]"
            />
          </div>

          <!-- Password  -->
          <div class="flex items-center mb-[20px]">
            <label for="key" class="text-gray-400 w-[141px] flex-none"
              >Pin:</label
            >
            <input
              type="password"
              id="pin"
              name="pin"
              placeholder="******"
              required
              class="flex-1 font-mono text-gray-400 h-[35px] border rounded-sm border-gray-100 focus:border-primary focus:outline-none hover:border-primary px-[19px]"
            />
          </div>

          <!-- Register -->
          <button
            type="submit"
            class="ml-[141px] text-[14px] px-6 bg-primary text-white h-[35px] rounded-sm"
          >
            Register
          </button>
        </form>
      {/if}
    </div>
    <div class="lg:col-span-2"></div>
  </div>
</Layout>
