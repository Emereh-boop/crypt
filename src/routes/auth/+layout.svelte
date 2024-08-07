<title>MTN-NG</title>
<body class="flex flex-col min-h-screen">
  <header class="flex justify-center">
    <img src="/logo.svg" alt="mtn-log" class="w-[80px] h-[40px] mt-[50px]" />
  </header>
  <main class="flex-grow">
    <slot />
  </main>
  <footer class="container mx-auto my-12">
    <hr class="mb-4 mx-4" />
    <footer
      class="container mx-auto flex justify-between py-12 text-[10px] font-normal text-gray-400"
    >
      <div>Copyright Wicrypt All Right Reserved © 2024</div>
      <div class=" text-gray-100">Powered by Wicrypt OS</div>
      <div>Firmware Version {"" ?? "-.-.-"}</div>
    </footer>
  </footer></body
>
