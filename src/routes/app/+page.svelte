<script lang="ts">
  import { onMount } from "svelte";
  import Layout from "./+layout.svelte";
  import uploadSpeed from "../../../public/uploadSpeedRed.svg";
  import downloadSpeed from "../../../public/downloadSpeedGreen.svg";
  import SignalStrenght from "../../../public/signalStrenghtYellow.svg";

  let dhcpLeases: Array<any> = [];
  let refreshInterval: NodeJS.Timeout;
  let wifiData: [];
  let transferSpeed: {};
  let signalStrenght: {};
  let systemInfo: {};
  let memoryInfo: {};

  const fetchWifiData = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "wireless",
        }),
      });
      wifiData = await response.json();
      if (wifiData.success === true) {
        wifiData = wifiData.data;
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
  const fetchSignalStrenght = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "signal_strenght",
        }),
      });
      signalStrenght = await response.json();
      if (signalStrenght.success === true) {
        console.log(signalStrenght.data);
        let ess = signalStrenght.data.slice(
          signalStrenght.data.indexOf(":") + 1
        );

        let linkQuality = ess;
        const linkQualityToDbm = (quality) => (quality * 100) / 70 - 100;
        let signalStrengthDbm = Math.round(linkQualityToDbm(linkQuality));
        signalStrenght = signalStrengthDbm;
      }
    } catch {}
  };

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
      dhcpLeases = await response.json();
      if (dhcpLeases.success === true) {
        dhcpLeases = dhcpLeases.data;
      }
    } catch {
      dhcpLeases = [];
    }
  };

  const fetchSystemInfo = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "board_info",
        }),
      });
      systemInfo = await response.json();
      if (systemInfo.success === true) {
        systemInfo = systemInfo.data;
      }
    } catch {}
  };
  const fetchMemoryInfo = async () => {
    try {
      const response = await fetch("http://192.168.0.1:8080/cgi-bin/api.cgi", {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cmd: "memory_info",
        }),
      });
      memoryInfo = await response.json();
      if (memoryInfo.success === true) {
        memoryInfo = memoryInfo.data;
      }
    } catch {}
  };

  onMount(() => {
    fetchSignalStrenght();
    fetchWifiData();
    fetchDhcpLeases();
    fetchMemoryInfo();
    fetchSystemInfo();
    refreshInterval = setInterval(() => {
      fetchSignalStrenght();
      fetchTransferSpeed();
      fetchDhcpLeases();
    }, 6000);
    return () => {
      clearInterval(refreshInterval);
    };
  });

  const circumference = ((2 * 22) / 7) * 50;
</script>

<Layout>
  <section
    class="min-h-[600px] lg:grid lg:grid-cols-12 lg:grid-flow-row text-[14px] font-normal text-gray-400"
  >
    <div
      class="flex col-span-full md:hidden items-start justify-center p-[35.5px]"
    >
      <a href="#/myhub" class=" my-[4px] ml-3 flex"
        >Next <img
          src="/foward-icon.svg"
          class="w-[12.41px] ml-[7px]"
          alt="view-all-connected-devices-icon"
        /></a
      >
    </div>
    <div class=" col-start-2 col-span-10 p-[30px] border shadow-xl">
      <!-- Connected Devices -->
      <div>
        <div class="grid grid-cols-2 gap-[16px]">
          <div
            class="grid grid-5 col-span-2 md:col-span-1 px-[28px] py-[17px] gap-[16px] ring-[1px] ring-[#E5B910]/20 h-auto lg:h-[171px] rounded-[20px]"
          >
            <span class="col-span-full text-[16.95px] font-bold mt-5 text-black"
              >Connected Devices <span class=" font-semibold leading-6"
                >[ {dhcpLeases?.length ?? 0} ]</span
              ></span
            >
            {#each dhcpLeases ?? [] as lease, i}
              <div class="col-span-3 flex">
                <div class="flex-1">
                  <span class=" font-bold text-black font-mono"
                    >[ {i + 1} ]
                  </span>{lease.clientName}
                </div>
                <div class="flex-1">{lease.mac}</div>
              </div>
            {/each}
            <div class="flex items-center justify-center">
              <a
                href="#/connected-devices"
                class="col-span-full my-[4px] ml-3 flex"
                >View All Devices <img
                  src="/foward-icon.svg"
                  class="w-[12.41px] ml-[7px]"
                  alt="view-all-connected-devices-icon"
                /></a
              >
            </div>
          </div>
          <div
            class="grid grid-cols-2 col-span-2 md:col-span-1 h-[120px] gap-[16px]"
          >
            <div
              class="flex justify-evenly items-center w-4/5 rounded-[12px] ring-[1px] ring-[#E5B910]/20 h-[52px]"
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
              class="flex justify-evenly items-center w-4/5 rounded-[12px] ring-[1px] ring-[#E5B910]/20 h-[52px]"
            >
              <img
                class="h-[24px] w-[24px]"
                src={uploadSpeed}
                alt="Upload Speed"
              />
              <div class="flex flex-col justify-evenly">
                <span class="text-[12px] font-[400]">Upload Speed</span>
                <span class="text-[12px] font-[700] text-[#1D1D1D]"
                  >{transferSpeed
                    ? transferSpeed.rx.ratestring
                    : "0 bit/s"}</span
                >
              </div>
            </div>
            <div
              class="flex justify-evenly items-center w-4/5 rounded-[12px] ring-[1px] ring-[#E5B910]/20 h-[52px]"
            >
              <img
                class="h-[24px] w-[24px]"
                src={SignalStrenght}
                alt="Signal Strenght"
              />
              <div class="flex flex-col">
                <span class="text-[12px] font-[400]">Signal Strenght</span>
                <span class="text-[12px] font-[700] text-[#1D1D1D]"
                  >{signalStrenght ? `${signalStrenght} dbm` : "0 dbm"}</span
                >
              </div>
            </div>
          </div>
        </div>

        <div
          class="mt-4 gap-[16px] h-[236] grid grid-cols-1 md:grid-cols-2 gap-y-4"
        >
          <!-- System Info -->
          <div
            class="px-[28px] py-[17px] gap-[16px] ring-[1px] ring-[#E5B910]/20 h-[236px] rounded-[20px]"
          >
            <!-- <img
            src="/info-icon.svg"
            class="w-[33.6px] col-span-full mb-[9px]"
            alt="info-icon"
          /> -->
            <span class="col-span-full text-[16.95px] font-bold text-black"
              >System Info</span
            >
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">Host Name</span>
              <span class=" col-span-2">MTN-WICRYPT</span>
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">Model</span>
              <span class=" col-span-2">{systemInfo?.model}</span>
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">Architecture</span>
              <span class=" col-span-2">{systemInfo?.board_name}</span>
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">Kernel Version</span>
              <span class=" col-span-2">{systemInfo?.kernel}</span>
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">Up Time</span>
              <span class=" col-span-2"
                >{Math.round(memoryInfo?.uptime / 3600)} Hrs: {Math.round(
                  memoryInfo?.uptime / 60
                ) % 60} Mins</span
              >
            </div>
          </div>
          <!-- WiFi Info -->

          <div
            class="px-[28px] py-[17px] ring-[1px] ring-[#E5B910]/20 rounded-[20px]"
          >
            <span class="col-span-full text-[16.95px] font-bold text-black"
              >wireless Info</span
            >
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">SSID 2.4G</span>
              <span class=" col-span-2"
                >{wifiData ? wifiData[0].ssid : "--"}</span
              >
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">BSSID 2.4G</span>
              <span class=" col-span-2"
                >{wifiData ? wifiData[0].bssid : "--"}</span
              >
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">SSID 5G</span>
              <span class=" col-span-2"
                >{wifiData ? wifiData[1].ssid : "--"}</span
              >
            </div>
            <div class="grid grid-cols-3 mt-2">
              <span class=" col-span-1">BSSID 5G</span>
              <span class=" col-span-2"
                >{wifiData ? wifiData[1].bssid : "--"}</span
              >
            </div>
          </div>
        </div>

        <!-- Memory Info -->
        <div
          class="mt-4 px-[28px] gap-3 ring-[1px] ring-[#E5B910]/20 justify-evenly rounded-[20px] flex-col flex"
        >
          <!-- <img src="/info-icon.svg" class="w-[33.6px] mb-[9px]" alt="info-icon" /> -->
          <span class="text-[16.95px] font-bold text-black">Memory Info</span>

          <div
            class="grid lg:grid-cols-4 grid-cols-2 grid-flow-dense items-center justify-evenly gap-[80px] h[150]"
          >
            <!-- Available Memory -->
            <div class="flex items-center justify-evenly gap-[80px] h[150]">
              <div
                class="text-center col-span-1 items-center justify-center text-lg grid gap-[14px]"
              >
                <div
                  class="flex items-center justify-center ring-[2pt] ring-amber-400 rounded-full"
                >
                  <svg class="transform -rotate-90 w-[120px] h-[120px]">
                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      class="text-[#E5B910]/10"
                    />

                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      stroke-dasharray={circumference}
                      stroke-dashoffset={(memoryInfo?.memory?.available /
                        memoryInfo?.memory?.total) *
                        circumference +
                        circumference}
                      class="text-[#E5B910]"
                    />
                  </svg>
                  <span class="absolute font-bold text-black text-[20px]">
                    {Math.round(
                      (memoryInfo?.memory?.available /
                        memoryInfo?.memory?.total) *
                        100
                    )}%
                  </span>
                </div>
                <p class="font-normal text-gray-400 text-[14px]">
                  Available Memory
                </p>
              </div>
            </div>
            <!-- Used Memory -->
            <div
              class="flex flex-wrap md:flex-row items-center justify-evenly gap-[80px] h[150]"
            >
              <div
                class="text-center col-span-1 items-center justify-center text-lg grid gap-[14px] flex-col"
              >
                <div
                  class="flex items-center justify-center ring-[2pt] ring-amber-400 rounded-full"
                >
                  <svg class="transform -rotate-90 w-[120px] h-[120px]">
                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      class="text-[#E5B910]/10"
                    />
                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      stroke-dasharray={circumference}
                      stroke-dashoffset={((memoryInfo?.memory?.total -
                        memoryInfo?.memory?.available) /
                        memoryInfo?.memory?.total) *
                        circumference +
                        circumference}
                      class="text-[#E5B910]"
                    />
                  </svg>
                  <span class="absolute font-bold text-black text-[20px]">
                    {Math.round(
                      ((memoryInfo?.memory?.total -
                        memoryInfo?.memory?.available) /
                        memoryInfo?.memory?.total) *
                        100
                    )}%
                  </span>
                </div>
                <p class="font-normal text-gray-400 text-[14px]">Used Memory</p>
              </div>
            </div>
            <!-- Buffered Memory -->
            <div
              class="flex flex-wrap md:flex-row items-center justify-evenly gap-[80px] h[150]"
            >
              <div
                class="text-center col-span-1 items-center justify-center text-lg grid gap-[14px] flex-col"
              >
                <div
                  class="flex items-center justify-center ring-[2pt] ring-amber-400 rounded-full"
                >
                  <svg class="transform -rotate-90 w-[120px] h-[120px]">
                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      class="text-[#E5B910]/10"
                    />

                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      stroke-dasharray={circumference}
                      stroke-dashoffset={(memoryInfo?.memory?.buffered /
                        memoryInfo?.memory?.total) *
                        circumference +
                        circumference}
                      class="text-[#E5B910]"
                    />
                  </svg>
                  <span class="absolute font-bold text-black text-[20px]">
                    {Math.round(
                      (memoryInfo?.memory?.buffered /
                        memoryInfo?.memory?.total) *
                        100
                    )}%
                  </span>
                </div>
                <p class="font-normal text-gray-400 text-[14px]">
                  Buffered Memory
                </p>
              </div>
            </div>
            <!-- Cached Memory -->
            <div
              class="flex flex-wrap md:flex-row items-center justify-evenly gap-[80px] h[150]"
            >
              <div
                class="text-center col-span-1 items-center justify-center text-lg grid gap-[14px] flex-col"
              >
                <div
                  class="flex items-center justify-center ring-[2pt] ring-amber-400 rounded-full"
                >
                  <svg class="transform -rotate-90 w-[120px] h-[120px]">
                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      class="text-[#E5B910]/10"
                    />

                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      stroke="currentColor"
                      stroke-width="13"
                      fill="transparent"
                      stroke-dasharray={circumference}
                      stroke-dashoffset={(memoryInfo?.memory?.cached /
                        memoryInfo?.memory?.total) *
                        circumference +
                        circumference}
                      class="text-[#E5B910]"
                    />
                  </svg>
                  <span class="absolute font-bold text-black text-[20px]">
                    {Math.round(
                      (memoryInfo?.memory?.cached / memoryInfo?.memory?.total) *
                        100
                    )}%
                  </span>
                </div>
                <p class="font-normal text-gray-400 text-[14px]">
                  Cached Memory
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div
      class="hidden col-start-12 md:flex justify-center items-start col-span-2 p-[35.5px]"
    >
      <a href="#/myhub" class=" my-[4px] ml-3 flex"
        >Next <img
          src="/foward-icon.svg"
          class="w-[12.41px] ml-[7px]"
          alt="view-all-connected-devices-icon"
        /></a
      >
    </div>
  </section>
</Layout>
