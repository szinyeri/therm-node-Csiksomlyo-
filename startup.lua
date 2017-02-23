-- main
print("loading : futes.lua")
require("environment")

-- kezdeti inicializálás global funkciók
function OntInit()
   -- slog_ip = '192.168.44.254' ha a syslog server nem a default gateway
  --  print ("env init: "..environment.init()) -- inicializálja a hőmérőt a default potokon scl=5 sda=6
    local msg = "futes.lua - OntInit() -"
    local res = environment.init()
    syslog( msg..string.format("Inicializálás... boot reason(%d, %d)",node.bootreason()))
    print(type(res), #res, res[1], res[2])
    if res[1] == nil then -- homero inicializalas sikertelen
        syslog(msg.." environment.init() failed "..res[2])
    end
    dofile("webserv.lc")
    syslog(msg.." WiFi connected: "..wifi.sta.getip())
    -- periódikus hőmérséklet mérés elindítása 2 sec múlva
    sntp.sync("pool.ntp.org",
        function(sec,usec,server)
            local sec,usec = rtctime.get()
            rtctime.set(sec+3600,usec) -- időzóna miatti állítás
            local tm = rtctime.epoch2cal(rtctime.get())
            syslog(msg.." sntp.sync() - success - server: "..server.." date: "..
                string.format("%04d/%02d/%02d %01d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["wday"], tm["hour"], tm["min"], tm["sec"]))
        end,
        function(errcode)
            if errcode == 1 then errmsg = "1: DNS lookup failed"
            elseif errcode == 2 then errmsg = "2: Memory allocation failure"
            elseif errcode == 3 then errmsg = "3: UDP send failed"
            elseif errcode == 4 then errmsg = "4: Timeout, no NTP response received"
            else errmsg = tostring(errcode).." : Other failure"
            end
            syslog(msg.." sntp.sync() - error: "..errmsg)
        end)
     tmr.alarm(3, 2*1000, tmr.ALARM_SINGLE, function() 
        get_env()
        tmr.alarm(3, 60*1000, tmr.ALARM_AUTO,get_env)
        end)
end


-- 1 percenként történik timer3 callback segítségével,
function get_env()
    if package.loaded["environment"] == nil then
        require("environment")
        environment.init()
        tmr.delay(100)
    end
    lastenv = environment.read()
end

-- várakozik WiFi kapcsolatra
function WiFiOKWt()
    print("func: WiFiOKWt()")
    local ssid, password, bssid_set, bssid=wifi.sta.getconfig()
  --  print("\nCurrent Station configuration:\nSSID : "..ssid
  --      .."\nPassword  : "..password
  --      .."\nBSSID_set  : "..bssid_set
  --      .."\nBSSID: "..bssid)
    if ssid == "" then -- nincs WiFi konfigurálva
        print ("WiFi config üres, setting default.")
        wifi.setmode(wifi.STATION)
        print ("Current WiFi Mode: "..wifi.getmode())
        wifi.sta.config("nabukodonozor", "KawaiES3DigitalisZongora2012")
    end
    if wt_time_ctr == nil then
        wt_time_ctr = 1
    else
        wt_time_ctr = wt_time_ctr*2
    end
    if wt_time_ctr > 22 then
        print("WiFI AP not connected: restarting node") node.restart()
    end
    if wifi.sta.status() == 5 then -- WiFi connected
        tmr.alarm(0, 100, tmr.ALARM_SINGLE, WTFunc)
    else
        print("WiFi not connected ", wifi.sta.getconfig(), "wait_time_ctr:", wt_time_ctr)
        tmr.alarm(0, wt_time_ctr*1000, tmr.ALARM_SINGLE,  WiFiOKWt)
    end

end

function syslog(msg)
   -- local _,_,slog_ip = wifi.sta.getip() -- default gateway a syslog server
    if slog_ip ~= nil and msg ~=nil then
        msg = "<12> UpTime="..uptime().."; Node ID="..node.chipid().." Heap="..node.heap().."; msg: "..msg
        local slog_sck = net.createConnection(net.UDP, 0)
        slog_sck:connect(514, slog_ip)
        slog_sck:send(msg, function(sck)
                            print("UDP Sent")
                            sck:close()
                            sck=nil
                    end )
        print(msg)
    else
        print("Cannot send syslog, IP: "..tostring(slog_ip).." msg="..tostring(msg))
    end
end

function uptime()
    local upt =tmr.time()
    local ora = math.floor(upt/3600)
    local perc = math.floor((upt-ora*3600)/60)
    local mperc = upt-ora*3600-perc*60
    return string.format("%dh %dmin %dsec", ora, perc, mperc)
end

-- hőmétő i2c kiolvasásakor transmission error kezelésére
function  try(f, catch_f)
       local status, exception = pcall(f)
       if not status then catch_f(exception) end
end

WTFunc = OntInit -- OntInit után GetGWTime jön
WiFiOKWt() -- WiFi check
