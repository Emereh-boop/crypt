#!/usr/bin/lua

local util    = require("luci.util")
local sys     = require("luci.sys")
local jsonc   = require("luci.jsonc")
-- local mtkwifi = require("mtkwifi")
local uci     = require("luci.model.uci").cursor()
-- local devices = mtkwifi.get_all_devs()

local SERVER  = "https://device-api-stg.wicrypt.com"

--function to get devive infomation
function IfDevicesInfo()
    local result = {}

    -- Run iwinfo command to get wireless interface information
    local handle = io.popen("iwinfo wlan0 info")
    local iwinfo_output = handle:read("*a")
    handle:close()

    -- Obtain devname using ip link show
    local handle = io.popen("ip link show wlan0")
    local link_output = handle:read("*a")
    handle:close()
    local devname = link_output:match("^%d+: (%S+):")

    -- Obtain WPA-PSK from configuration file (if available)
    local wpapsk = "UNKNOWN"
    handle = io.popen("sudo cat /etc/wpa_supplicant/wpa_supplicant.conf 2>/dev/null")
    local wpa_output = handle:read("*a")
    handle:close()
    if wpa_output then
        wpapsk = wpa_output:match('psk="(.-)"') or "UNKNOWN"
    end

    -- VIF prefix and index
    local vifs_prefix = "vif_prefix"  -- Placeholder, replace if your system has a method to retrieve it
    local vifidx = 0  -- Set to 0 by default

    -- Extract information from iwinfo output
    local ssid = iwinfo_output:match('ESSID: "([^"]+)"')
    local bssid = iwinfo_output:match('Access Point: ([%x:]+)')
    local encrypttype = iwinfo_output:match('Encryption: (%w+)')
    local authmode = iwinfo_output:match('Mode: (%w+)')
    local hidessid = iwinfo_output:match('Hidden: (%w+)')
    local vifname = "wlan0"  -- Since we're specifically querying wlan0

    -- Insert the extracted and placeholder data into the result table
    table.insert(result, {
        devname = devname or "UNKNOWN",
        vifs_prefix = vifs_prefix,
        ssid = ssid or "UNKNOWN",
        encrypttype = encrypttype or "UNKNOWN",
        authmode = authmode or "UNKNOWN",
        vifname = vifname,
        hidessid = hidessid or "no",
        vifidx = vifidx,
        wpapsk = wpapsk,
        bssid = bssid or "UNKNOWN"
    })

    return result
end


function SessionRetrieve(session_id)
    local session = util.ubus("session", "get", { ubus_rpc_session = session_id })
    if type(session) == "table" then
        return jsonc.stringify({ data = session, success = true, error = nil })
    else
        return jsonc.stringify({ error = "Invalid Session", success = false, data = nil })
    end
end

-- Function to run the parsing script and capture its output
function runParsingScript()
    local handle = io.popen("/script/parsing_script.sh")
    local result = handle:read("*a")
    handle:close()
    return result
end

function Login(user, pass)
    local lgin = util.ubus("session", "login", {
        username = "root",
        password = pass,
        timeout = 900
    })
    if type(lgin) == "table" and type(lgin.ubus_rpc_session) == "string" then
        util.ubus("session", "set", {
            ubus_rpc_session = lgin.ubus_rpc_session,
            values = { token = sys.uniqueid(16) }
        })
        print("Set-Cookie: sessionId=" .. lgin.ubus_rpc_session .. "; Path=/; HttpOnly")
        print("\r\n")
        return SessionRetrieve(lgin.ubus_rpc_session)
    else
        print("\r\n")
        return jsonc.stringify({ error = "Wrong credentials", success = false, data = nil })
    end
end

function BoardInfo()
    print("\r\n")
    local info = util.ubus("system", "board")
    return jsonc.stringify({ data = info, success = true, error = nil })
end

function FirmwEnable()
    print("\r\n")
    os.execute("/etc/init.d/spikeserviceprocd enable")
    local suc, exitCode, code = os.execute("/etc/init.d/spikeserviceprocd start")
    if suc then
        return jsonc.stringify({ message = "spikeserviceprocd started successfully", error = nil, success = true })
    else
        return jsonc.stringify({ error = "Failed to start spikeserviceprocd", message = nil, success = false })
    end
end

function FirmwDisable()
    print("\r\n")
    local suc, exitCode, code = os.execute("/etc/init.d/spikeserviceprocd disable")
    if suc then
        return jsonc.stringify({ message = "spikeserviceprocd disabled successfully", error = nil, success = true })
    else
        return jsonc.stringify({ error = "Failed to disable spikeserviceprocd", message = nil, success = false })
    end
end

function RegisterDevice(email, pin)
    print("\r\n")
    local mac = util.ubus("luci-rpc", "getNetworkDevices", {}).br0.mac
    local wireless = util.ubus("iwinfo", "info", { device = "wlan0" })

    local brd_info = util.ubus("system", "board")

    local license = uci:get("wicrypt", "licence", "key")


    local body = jsonc.stringify({
        architecture = brd_info.system,
        bssid = wireless.bssid,
        deviceModel = brd_info.model,
        email = email,
        macAddress = mac,
        pin = pin,
        releaseVersion = "1.0.0",
        ssid = wireless.ssid
    })

    local curlCommand = string.format(
        'curl -s -X POST -H "Content-Type: application/json" -H "x-license-key: %s"  -d \'%s\' %s/api/v1/device',
        license,
        body, SERVER)
    local result = util.exec(curlCommand)
    return result
end

function RegStatus()
    print("\r\n")
    local ifInfo = IfDevicesInfo()
    local bssid = ifInfo[1].bssid
    local curlCommand = string.format(
        'curl -s -X GET -H encType="multipart/form-data" -d "" "%s/api/v1/device/status/%s"', SERVER, bssid)
    local result = util.exec(curlCommand)
    return result
end

function FirmwServiceStatus()
    print("\r\n")
    local spikeserviceprocd = util.ubus("luci", "getInitList", { name = "spikeserviceprocd" })
    if type(spikeserviceprocd) ~= "table" then
        return jsonc.stringify({ error = "Failed to get spikeserviceprocd status", success = false })
    end
    return jsonc.stringify(spikeserviceprocd)
end

function MemoryInfo()
    print("\r\n")
    local memory_info = util.ubus("system", "info")
    if type(memory_info) ~= "table" then
        return jsonc.stringify({ success = false, error = "Failed to get system info" })
    end
    return jsonc.stringify({ data = memory_info, success = true, error = nil })
end

-- function Wireless()
--     print("\r\n")
--     local wifis = IfDevicesInfo()
--     return jsonc.stringify({ data = wifis, success = true, error = nil })
-- end

function Wireless()
    print("\r\n")
   -- local wifis = IfDevicesInfo()
    local iwinfoattributes = util.ubus("luci-rpc", "getWirelessDevices")
    local Ssid = iwinfoattributes.radio0.interfaces[1].iwinfo.ssid
    local Bssid = iwinfoattributes.radio0.interfaces[1].iwinfo.bssid
    local Key = iwinfoattributes.radio0.interfaces[1].config.key
    local Encryption = iwinfoattributes.radio0.interfaces[1].config.encryption

    -- local result = {}
    local result = {
                    ssid = Ssid,
                    bssid = Bssid,
                    key = Key,
                    encryption = Encryption
                }
    return jsonc.stringify({ data = result, success = true, error = nil })
end

function transferSpeed()
    print("\r\n")
    local res = util.exec('vnstat -tr -i wlan0 --json')
    return jsonc.stringify({ data = jsonc.parse(res) , success = true, error = nil })
end
function signalStrenght()
    print("\r\n") 
    local res = util.exec('ifconfig wlan0 | awk \'/Link Quality/ { print $2}\'    ')
    return jsonc.stringify({ data = res , success = true, error = nil }) 
end

function DhcpLease()
    print("\r\n")
    local cusor = io.open("/tmp/dhcp.leases", "r")
    if cusor == nil then
        return jsonc.stringify({ data = {}, success = false, error = "Failed to open dhcp.leases" })
    end
    local content = cusor:read("*all")
    cusor:close()
    local result = {}
    -- format the dhcp data to json
    for line in content:gmatch("[^\r\n]+") do
        local parts = {}
        for part in line:gmatch("%S+") do
            table.insert(parts, part)
        end

        local entry = {
            timestamp = tonumber(parts[1]),
            mac = parts[2],
            ip = parts[3],
            clientName = parts[4] == "*" and nil or parts[4],
            additionalMac = parts[5]
        }

        table.insert(result, entry)
    end
    return jsonc.stringify({ data = result, success = true, error = nil })
end

function WifiDevices()
    print("\r\n")
    local result = IfDevicesInfo()    
    return jsonc.stringify({ data = result, success = true, error = nil })
end


function ChangeSsid(devname, newssid)
    print("\r\n")
    if devname == "5G" then
        util.exec("wc_wifi_config ssid5 " .. newssid)
    elseif devname == "2.4G" then
        util.exec("uci set wireless.@wifi-iface[0].ssid='"..newssid.."'")
        util.exec("uci commit wireless")
        util.exec("/etc/init.d/network restart")
    end
    return jsonc.stringify({ success = true, error = nil })
end


function ChangeWirelessAuthConfig(devname, encryption, key)
    print("\r\n")
    if devname == "5G" and key ~= nil then
        util.exec("wc_wifi_config pwd5 " .. key)
    end
    if devname == "2.4G" and key ~= nil and encryption == "psk2" then
        util.exec("uci set wireless.@wifi-iface[0].encryption="..encryption)
        util.exec("uci set wireless.@wifi-iface[0].key='"..key.."'")
        util.exec("uci commit wireless")
        util.exec("/etc/init.d/network restart")
    elseif devname == "2.4G" and encryption == "none" then
        util.exec("uci set wireless.@wifi-iface[0].encryption="..encryption)
        util.exec("uci commit wireless")
        util.exec("/etc/init.d/network restart")
    end
    
    -- if devname == "5G" and authmode ~= nil then
    --     util.exec("wc_wifi_config enc5 " .. authmode)
    -- elseif devname == "2.4G" and encryption ~= nil then
    --     util.exec("uci set wireless.@wifi-iface[0].encryption="..encryption)
    --     util.exec("uci commit wireless")
    --     util.exec("/etc/init.d/network restart")
    -- end
    return jsonc.stringify({ success = true, error = nil })
end


function WhitelistedDevices()
    print("\r\n")
    local cursor = io.open("/etc/wicrypt/database/whitelisted_devices.json", "r")
    if cursor == nil then
        return jsonc.stringify({ data = {}, success = false, error = "Failed to open whitelisted_devices.json" })
    end
    local content = cursor:read("*all")
    cursor:close()
    return jsonc.stringify({ data = jsonc.parse(content).data.records, success = true, error = nil })
end

function WhitelistDev(mac, name)
    print("\r\n")
    local resp = util.exec("sh /etc/wicrypt/shellscripts/splash_page.sh whitelistDevice " .. mac .. " " .. name)
    return jsonc.stringify(jsonc.parse(resp))
end

function DelistDev(mac, name)
    print("\r\n")
    local resp = util.exec("sh /etc/wicrypt/shellscripts/splash_page.sh unwhitelist " .. mac .. " " .. name)
    return jsonc.stringify(jsonc.parse(resp))
end

function DownloadWhitelisted()
    print("\r\n")
    util.exec("sh /etc/wicrypt/shellscripts/splash_page.sh whitelistedDevices")
    return jsonc.stringify({ success = true, error = nil })
end

function DownloadFirmwFile()
    print("\r\n")
    local suc, exitCode, code = os.execute("sh /etc/wicrypt/shellscripts/splash_page.sh staticFiles")
    if suc then
        return jsonc.stringify({ message = "required files downloaded successfully", error = nil, success = true })
    else
        return jsonc.stringify({ error = "Failed to download required files", message = nil, success = false })
    end
end

function FirmwareUpgrade()
    print("\r\n")
    local result = util.exec("sh /etc/wicrypt/shellscripts/systemupgrade.sh")
    return jsonc.stringify({ data = result, success = true, error = nil })
end


function DataUsage()
    print("\r\n")
    local res = util.exec(
        "sed -i 's/\"\"/\"/g' /etc/wicrypt/database/data_usage.json && cat /etc/wicrypt/database/data_usage.json")
    return jsonc.stringify({ data = jsonc.parse(res), success = true, error = nil })
end

function LinkHub(code)
    print("\r\n")
    local ifInfo = IfDevicesInfo()
    local mac = util.ubus("luci-rpc", "getNetworkDevices", {}).wlan0.mac
    local brd_info = util.ubus("system", "board")
    local license = uci:get("wicrypt", "licence", "key")
    local imei = util.exec("cat /tmp/.devinfo_module_data | grep \"module_imei\" | cut -d':' -f2")

    local body = jsonc.stringify({
        linkCode = code,
        imei = imei,
        bssid = ifInfo[1].bssid,
        ssid = ifInfo[1].ssid,
        architecture = brd_info.system,
        deviceModel = brd_info.model,
        macAddress = mac,
        releaseVersion = "1.0.0",
    })

    local curlCommand = string.format(
    'curl -s -X POST -H "Content-Type: application/json" -H "x-license-key: %s" -d \'%s\' %s/api/v1/device/link-hub',
    license,
    body,
    SERVER
)
local result = util.exec(curlCommand)
local res = jsonc.parse(result)

if res.isSuccessful == true then
    local devHash = res.data.devicePinHash
    local devPhrase = res.data.deviceSecurityPhrase

    -- Set the values
    uci:set("wicrypt", "login", "hash", devHash)
    uci:set("wicrypt", "login", "phrase", devPhrase)

    -- Commit the changes
    uci:commit("wicrypt")

    -- Get the values after setting them
    local hash = uci:get("wicrypt", "login", "hash")
    local phrase = uci:get("wicrypt", "login", "phrase")

end

return result

end

function FirmwVersion()
    print("\r\n")
    -- local res = util.exec("uci get wicrypt.firmwareAssetRelease.releaseVersion")
    local res = util.exec("uci get wicrypt.firmware.version")
    return jsonc.stringify({ data = { firmware_version = res }, success = true, error = nil })
end


local function fetch_post_data()
    local content_length = tonumber(os.getenv("CONTENT_LENGTH"))
    if content_length then
        local post_data = ""
        local chunk
        repeat
            chunk = io.read(1024) -- Read 1 KB at a time
            if chunk then
                post_data = post_data .. chunk
            end
        until not chunk
        return post_data
    else
        return nil
    end
end

local function validate_session()
    print("\r\n")
    return jsonc.stringify({ success = true, error = nil })
end

local function api()
    local http_method = os.getenv("REQUEST_METHOD")
    if http_method == "POST" then
        local post_data = fetch_post_data()
        local json_data = jsonc.parse(post_data)
        local cookies = os.getenv("HTTP_COOKIE") or ""
        local session_id = cookies:match("sessionId=([^;]+)")
        if session_id == "00000000000000000000000000000000" then
            print("\r\n")
            return jsonc.stringify({ error = "Invalid Session", success = false })
        end
        local cmd = json_data.cmd or ""

        if cmd == "login" then
            return Login(json_data.username or "root", json_data.password)
        else
            local session = util.ubus("session", "get", { ubus_rpc_session = session_id })
            if type(session) ~= "table" then
                print("\r\n")
                return jsonc.stringify({ error = "Invalid Session", success = false })
            end
        end
        if cmd == "board_info" then
            return BoardInfo()
        elseif cmd == "firmw_enable" then
            return FirmwEnable()
        elseif cmd == "firmw_disable" then
            return FirmwDisable()
        elseif cmd == "reg_status" then
            return RegStatus()
        elseif cmd == "firmw_status" then
            return FirmwServiceStatus()
        elseif cmd == "memory_info" then
            return MemoryInfo()
        elseif cmd == "wireless" then
            return Wireless()
        elseif cmd == "transfer_speed" then
            return transferSpeed()
        elseif cmd == "signal_strenght" then
            return signalStrenght()
        elseif cmd == "log_history" then 
            return runParsingScript()
        elseif cmd == "dhcplease" then
            return DhcpLease()
        elseif cmd == "register_device" then
            return RegisterDevice(json_data.email, json_data.pin)
        elseif cmd == "wifis" then
            return WifiDevices()
        elseif cmd == "change_ssid" then
            return ChangeSsid(json_data.devname, json_data.newssid)
        elseif cmd == "change_wireless_key" then
            return ChangeWirelessAuthConfig(json_data.devname, json_data.newEncryption, json_data.newkey)
        elseif cmd == "setup_firmw" then
            return DownloadFirmwFile()
        elseif cmd == "upgrade_firmw" then
            return FirmwareUpgrade()
        elseif cmd == "whitelisted" then
            return WhitelistedDevices()
        elseif cmd == "whitelist" then
            return WhitelistDev(json_data.mac, json_data.name)
        elseif cmd == "delist" then
            return DelistDev(json_data.mac, json_data.name)
        elseif cmd == "download_whitelisted" then
            return DownloadWhitelisted()
        elseif cmd == "data_usg" then
            return DataUsage()
        elseif cmd == "firmw_version" then
            return FirmwVersion()       
        elseif cmd == "link_hub" then
            return LinkHub(json_data.code)
        elseif cmd == "validate_session" then
            return validate_session()
        else
            return jsonc.stringify({ error = "Method not found", success = false })
        end
    else
        return jsonc.stringify({ error = "Method not allowed", success = false })
    end
end

local function test()
    local encryption = "psk2"
    util.exec("uci set wireless.@wifi-iface[0].encryption="..encryption)
    util.exec("uci commit wireless")
    util.exec("/etc/init.d/network restart")
end 

local http_method = os.getenv("REQUEST_METHOD")
if http_method == "OPTIONS" then
    print("Access-Control-Allow-Origin: *")
    print("Access-Control-Allow-Methods: POST, GET, OPTIONS")
    print("Access-Control-Allow-Headers: Content-Type")
    print("Access-Control-Max-Age: 86400")
    print("Content-Type: application/json")
    print("\r\n")
    return
end
print("Access-Control-Allow-Origin: *")
print("Access-Control-Allow-Methods: POST, OPTIONS")
print("Access-Control-Allow-Headers: Content-Type")
print("Access-Control-Max-Age: 86400")
print("Content-Type: application/json")
print(api())
