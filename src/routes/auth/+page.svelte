<script lang="ts">
  import { replace } from "svelte-spa-router";
  import AuthLayout from "./+layout.svelte";
  let loginError: string | null = null;
  async function handleLogin(event: any) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const password = formData.get("password");
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "login",
          password: password,
          username: "",
        }),
      });

      let res = await response.json();
      if (res.success === true) {
        replace("/overview");
      } else {
        loginError = res.error;
      }
    } catch (err) {
      loginError = "An error occurred";
    }
  }
</script>

<AuthLayout>
  <div class="container mx-auto">
    <div class="mt-[10px] mb-[43px] text-gray-400 text-[13px] text-center">
      Log In To Configure Your Hub
    </div>
    {#if loginError}
      <div
        class="border-peach-400 mb-[43px] bg-peach-100 w-full sm:w-4/5 lg:w-3/5 mx-auto rounded-[4px] p-4 border flex items-center"
      >
        <img src="/info-red.svg" class=" col-span-1 mr-4" alt="" />
        <p class="text-gray-400 col-span-4">{loginError}</p>
      </div>
    {/if}
    <form
      method="POST"
      on:submit={handleLogin}
      class="w-full sm:w-96 py-[31px] border shadow-lg rounded-[4.8px] px-[48px] mx-auto"
    >
      <label for="password" class="text-black">Hub PIN</label>
      <input
        type="password"
        id="password"
        name="password"
        placeholder="........"
        required
        class="w-full font-mono text-gray-100 h-[35px] border rounded-[16px] border-gray-100 focus:border-primary focus:outline-none hover:border-primary px-[19px] my-4 font-bold text-[16px]"
      />
      <button
        type="submit"
        class="w-full bg-primary text-white h-[35px] rounded-[20px]"
      >
        Log In
      </button>
    </form>
  </div>
</AuthLayout>
