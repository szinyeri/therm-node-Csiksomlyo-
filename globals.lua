-- init globals
nxt_temp = 210 -- ez lesz a következő elérendő hőmérséklet
prev_temp = 0 -- időzítésben az aktuális időhöz képest előzőleg megadott hőmérséklet érték
lastenv = {0,0}
napok ={"Sun", "Mon", "Tue", "Thu", "Wed", "Fri", "Sat"}
automode = true -- ha automatikus üzemmódban van, azaz az előre beállítottak alapján kapcsol
hist = 3 -- histerezis 
slog_ip = "192.168.4.254"
-- timerek
-- 0 fő fűtésprogram időzítő
-- 
