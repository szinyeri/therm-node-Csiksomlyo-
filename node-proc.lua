-- Find next time from config
print("loading : node-proc.lua")
-- hőmérséklet loggolása majd ide jön
function LogTemp()
--print("func: GetNxtTime()")
    local ido = rtctime.epoch2cal(rtctime.get())
    local tm
    local ido_perc = ido.hour*60+ido.min -- napon belül eltelt idő
    local nap = napok[ido.wday] -- a hét melyik napján vagyunk
  -- elteszi egy fájlba a mért értékeket  
end

