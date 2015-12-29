--setup.lua
-- konstanty pro GPIO operace
    GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
-- konstanty pro rozdelni casovaci    
    TM = {["ip"]=0,["m"]=1,["r"]=2,["s"]=3,["s2"]=4} 

-- prevede ID luatoru do 36-kove soustavy
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end
-- nastavi prefix vsech odesilanych dat    
    --Rpref = IDIn36(node.chipid()).."_" nepouziva se, samostatne na nodu
    Rpref = "h_"

-- vice vypisu
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then 
        --Debug_IP = 1
        --Debug_S = 1
        Debug_M = 1
        Debug = 1 
    end

-- konstanty pro reportovani
    Rcnt = 0
    Rint = 5 -- sekund
    Rnod = "1" -- vsechny elektromery jsou 4
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        Rapik = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Rdat = {}

-- Spustim procesy nastavujici sit a merici data

    Completed_Network = 0
    tmr.alarm(TM["ip"], 100, 0, function() dofile("network.lc") end)
    Completed_Measure = 0
    tmr.alarm(TM["m"], 100, 0,  function() dofile("measure.lc") end)

-- Spustim odesilac, ktery ceka az je k dispozici sit a zmerena data a provede odeslani
    tmr.alarm(TM["s"], 100, 0,  function() dofile("send.lc") end)

    print("system started")
