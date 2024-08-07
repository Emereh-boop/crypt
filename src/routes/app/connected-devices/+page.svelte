<script lang="ts">
  import { onMount } from "svelte";
  import Layout from "../+layout.svelte";
  import { link } from "svelte-spa-router";
  import uploadSpeed from "../../../../public/uploadSpeedRed.svg";
  import downloadSpeed from "../../../../public/downloadSpeedGreen.svg";

  let refreshInterval: NodeJS.Timeout;

  let dhcpLeases: Array<any> = [];

  let whitelisted: Array<any> = [];
  let modalOpen = false;
  let mac = "";
  let transferSpeed: {};
  let errorMsg: string | null = null;
  let successMsg: string | null = null;
  let firmwareEnabled: boolean | null = null;

  const fetchDhcpLeases = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "dhcplease",
        }),
      });
      const resp = await response.json();
      if (resp.success === true) {
        dhcpLeases = resp.data;
        dhcpLeases = dhcpLeases.map((lease) => {
          const isWhitelisted = whitelisted.some(
            (wl) => wl.macAddress.toUpperCase() === lease.mac.toUpperCase()
          );
          if (isWhitelisted) {
            let clientName = whitelisted.find(
              (wl) => wl.macAddress.toUpperCase() === lease.mac.toUpperCase()
            ).name;
            return {
              ...lease,
              whitelisted: isWhitelisted,
              clientName: clientName,
            };
          }
          return { ...lease, whitelisted: false };
        });
      }
    } catch {}
  };
  const fetchTransferSpeed = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "transfer_speed",
        }),
      });
      transferSpeed = await response.json();
      if (transferSpeed.success === true) {
        transferSpeed = transferSpeed.data;
      }
    } catch {}
  };
  const fetchWhitelisted = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "whitelisted",
        }),
      });
      const resp = await response.json();
      if (resp.success === true) {
        whitelisted = resp.data;
      }
    } catch {}
  };
  const whitelist = async (event: any) => {
    event.preventDefault();
    errorMsg = null;
    successMsg = null;
    modalOpen = false;
    let devName = event.target.devName.value;
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "whitelist",
          mac: mac,
          name: devName,
        }),
      });
      const res = await response.json();
      console.log(res);
      if (res.isSuccessful === true) {
        successMsg = res.message;
        whitelisted = [...whitelisted, { macAddress: mac, name: devName }];
        fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
          method: "POST",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            cmd: "download_whitelisted",
          }),
        });
      } else {
        errorMsg = res.message;
      }
    } catch {
      errorMsg = "An error occurred";
    }
  };

  const delist = async (mac: string, name: string) => {
    errorMsg = null;
    successMsg = null;
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "delist",
          mac: mac,
          name: name,
        }),
      });
      const res = await response.json();
      if (res.isSuccessful === true) {
        console.log(res.message);
        successMsg = res.message;
        whitelisted = whitelisted.filter((wl) => wl.macAddress !== mac);
        fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
          method: "POST",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            cmd: "download_whitelisted",
          }),
        });
      } else {
        errorMsg = res.message;
      }
    } catch {
      errorMsg = "An error occurred";
    }
  };

  const fetchDataUsage = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "data_usg",
        }),
      });
      const resp = await response.json();
      console.log(resp);
      if (resp.success === true) {
        let dataUsage = resp.data;
        dhcpLeases.forEach((lease) => {
          if (dataUsage.ip_list.includes(lease.ip)) {
            let indx = dataUsage.ip_list.indexOf(lease.ip);
            lease.data = (
              (Number(dataUsage.incoming_data_list[indx]) +
                Number(dataUsage.outgoing_data_list[indx])) /
              1024 /
              1024
            ).toFixed(2);
          }
        });
        dhcpLeases = dhcpLeases;
      }
    } catch {}
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

  onMount(() => {
    fetchFirmwareStatus();
    fetchWhitelisted().then(() => {
      fetchDhcpLeases().then(() => {
        fetchDataUsage();
      });
    });
    refreshInterval = setInterval(() => {
      fetchTransferSpeed();
      fetchWhitelisted().then(() => {
        fetchDhcpLeases().then(() => {
          fetchDataUsage();
        });
      });
    }, 6000);
    return () => {
      clearInterval(refreshInterval);
    };
  });
</script>

<Layout>
  <section
    class="min-h-[600px] grid lg:grid-cols-12 text-[14px] font-normal text-gray-400"
  >
    <div
      class="md:block grid grid-rows-4 col-start-2 col-span-10 p-[30px] border shadow-xl"
    >
      <div class="grid grid-cols-2 col-span-1 h-[60px] gap-[16px]">
        <a
          href="#/overview"
          use:link
          class="flex items-start md:col-span-1 col-span-2"
        >
          <img src="/back-icon.svg" alt="logout-icon" class="w-[24px]" />
          <span class="text-[16.95px] font-bold ml-2 text-black">Back</span>
        </a>
        <div class="md:col-span-1 col-span-2 grid grid-cols-2 gap-[16px]">
          <div
            class="flex justify-evenly items-center rounded-[12px] ring-[1px] ring-[#E5B910]/20 h-[52px]"
          >
            <img
              class="h-[24px] w-[24px]"
              src={downloadSpeed}
              alt="Download Speed"
            />
            <div class="flex flex-col justify-evenly">
              <span class="text-[12px] font-[400]">Download Speed</span>
              <span class="text-[12px] font-[700] text-[#1D1D1D]"
                >{transferSpeed
                  ? transferSpeed.tx.ratestring
                  : "0 kbit/s"}</span
              >
            </div>
          </div>
          <div
            class="flex justify-evenly items-center rounded-[12px] ring-[1px] ring-[#E5B910]/20 h-[52px]"
          >
            <img
              class="h-[24px] w-[24px]"
              src={uploadSpeed}
              alt="Upload Speed"
            />
            <div class="flex flex-col justify-evenly">
              <span class="text-[12px] font-[400]">Upload Speed</span>
              <span class="text-[12px] font-[700] text-[#1D1D1D]"
                >{transferSpeed ? transferSpeed.rx.ratestring : "0 bit/s"}</span
              >
            </div>
          </div>
        </div>
      </div>
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
      <!-- Connected Devices -->
      <div class="grid grid-cols-4 text-[14px]">
        <span class="col-span-full text-[16.95px] font-bold mt-5 text-black"
          >Connected Devices <span class=" font-semibold leading-6"
            >[ {dhcpLeases?.length ?? 0} ]</span
          ></span
        >
        <div class="col-span-4 mt-7 flex">
          <div class="flex-1">Host Name</div>
          <div class="flex-1">MAC</div>
          {#if firmwareEnabled}
            <div class="flex-1">Byte Used</div>
            <div class=" w-36"></div>
          {:else}
            <div class="flex-1"></div>
            <div class="flex-1"></div>
          {/if}
        </div>
        <hr
          class="col-span-4 my-4 -mx-3 h-[0.5px] border-none bg-[#E5B910]/20"
        />
        {#each dhcpLeases ?? [] as lease, i}
          <!-- dhcplease row-->
          <div class="col-span-4 flex">
            <div class="flex-1">
              <span class=" font-bold text-[14px] text-[#6b6b6b] font-mono"
                >[ {i + 1} ]
              </span>{lease.clientName}
            </div>
            <div class="flex-1">{lease.mac}</div>
            {#if firmwareEnabled}
              <div class="flex-1">{lease.data ?? 0} MB</div>
              <div class="w-36">
                {#if lease.whitelisted}
                  <button
                    type="button"
                    class="text-[14px] px-6 border-primary border text-primary h-[35px] rounded-sm"
                    on:click={() => delist(lease.mac, lease.clientName)}
                  >
                    Delist
                  </button>
                {:else}
                  <button
                    type="button"
                    class="text-[14px] px-6 bg-primary text-white h-[35px] rounded-sm"
                    on:click={() => {
                      modalOpen = true;
                      mac = lease.mac;
                    }}
                  >
                    Whitelist
                  </button>
                {/if}
              </div>
            {:else}
              <div class="flex-1"></div>
              <div class="flex-1"></div>
            {/if}
          </div>
          <hr
            class="col-span-4 my-4 -mx-3 h-[0.5px] border-none bg-[#E5B910]/20"
          />
        {/each}
      </div>
    </div>
  </section>
  {#if modalOpen}
    <div
      class="modal z-50 fixed w-full h-full top-0 left-0 flex items-center justify-center p-8 lg:p-0"
    >
      <div
        class="modal-overlay fixed w-full h-full bg-gray-900 opacity-50"
      ></div>
      <div
        class="bg-white w-full lg:h-max lg:w-2/5 mx-auto rounded-lg shadow-xl z-50 overflow-y-auto"
      >
        <!-- Modal content goes here -->
        <div class="head bg-primary py-5 px-8 text-2xl font-extrabold">
          <!-- Modal header -->
          Whitelist
        </div>
        <div class="content p-8">
          <!-- Modal body -->
          <form method="POST" on:submit={whitelist}>
            <div class="flex items-center mb-4">
              <label for="mac" class="w-1/4">MAC Address:</label>
              <input
                type="text"
                id="mac"
                name="mac"
                value={mac}
                disabled
                required
                class="w-3/4 border border-gray-300 rounded-sm h-10 px-3"
              />
            </div>
            <div
              class="flex items
          -center mb-4"
            >
              <label for="name" class="w-1/4">Name:</label>
              <input
                type="text"
                id="devName"
                name="devName"
                required
                class="w-3/4 border border-gray-300 rounded-sm h-10 px-3"
              />
            </div>
            <div class="flex">
              <div class="w-1/4"></div>
              <button
                type="submit"
                class="text-[14px] px-6 bg-primary text-white h-[35px] rounded-sm"
              >
                submit
              </button>
              <button
                type="button"
                class="text-[14px] px-6 border-primary border text-primary h-[35px] rounded-sm ml-4"
                on:click={() => {
                  modalOpen = false;
                }}
              >
                cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  {/if}
</Layout>
