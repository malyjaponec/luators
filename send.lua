-- send.lua
local x

function Konec()
    local res = x.get_state()
    print(res)
    if res == 4 then
            print("Done.")
            x = nil
            cloud = nil
            package.loaded["cloud"]=nil
            dofile("wait.lc") 
    else
        tmr.alarm(0, 100, 0, function() Konec() end)
    end
end

function Start()
    print("Connecting...")

    x = require("cloud")
    x.setup('77.104.219.2',Rapik,Rnod,'emon.jiffaco.cz')

    x.send(Rdat)
    tmr.alarm(0, 100, 0, function() Konec() end)
end    


-- pridam velikost counter
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Start()
