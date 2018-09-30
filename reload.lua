-- reload.lua    
--
-- mechanizmus znovuspusteni mereni a odeslani, tak aby to vse pracovalo
-- s danou periodou
    
-- zastavim veskere casovane cinnosti
    tmr.stop(0)
    tmr.stop(1)
    tmr.stop(2)
    tmr.stop(3)
    tmr.stop(4)
    tmr.stop(5)
    tmr.stop(6)

-- vypocet casu na cekani
    
    local time = (ReportInterval * 1000) - ((tmr.now() / 1000) - (TimeStartLast or 0))
    if time < 100 then time = 100 end -- urcite pockam 100ms
    if time > (ReportInterval * 1000) then time = (ReportInterval * 1000) end -- pokud se pretoci hodiny pockam periodu
    print("Waiting for "..(time/1000).." s") -- tiskne se vzdy i kdyz je vypnuty debug
    
-- usnuti nebo jen konec    
    if file.open("init.lua", "r") == nil then -- soubor neexistuje, rucni start, nespime, ladime kod
        print("REND ("..(time/1000000).."s)")
    else
	-- spusteni mereni
		tmr.alarm(0, time, 0, function() 
			TimeStartLast = tmr.now() / 1000
			
			MeasureInit()
			dofile("send.lc")
		end) 
	end
	
