-- cekam ze je AP nastavene a ono se to pripoji
counter = 0
while ((nil == wifi.sta.getip()) and (counter < 5)) do
    print("Cekam na IP ("..counter..")")
    tmr.delay(2*1000*1000)
    counter = counter + 1
end
-- zkontroluji IP a pokud ji nema zkusim nastavit AP
if (nil == wifi.sta.getip()) then
    print("Nastavuji JIFFACO")
    wifi.setmode(wifi.STATION)
    wifi.sta.config("JIFFACO","***REMOVED***855") 
    print("Pripojuji se na AP...")
    wifi.sta.connect()
    -- znova cekam zda nedostanu IP
    counter = 0
    while ((nil == wifi.sta.getip()) and (counter < 15)) do
    print("Cekam na IP ("..counter..")")
    tmr.delay(2*1000*1000)
    counter = counter + 1
    end
end
-- pro pripade ze bych nedostal IP udelam restart
if (nil == wifi.sta.getip()) then
    print("DHCP chyba, restart za 60 sekund")
    tmr.alarm(0, 60000, 0, function() node.restart() end)
else
    print("IP je "..wifi.sta.getip())
    dofile("send2cloud.lc")
end
