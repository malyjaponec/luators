--setup.lua

-- konstanty pro reportovani
    local ReportInterval = 5 -- minut
    local SecurityOffInterval = 30 -- sekund
    ReportNode = "3"
    ReportFieldPrefix = "venku_"
    ReportApiKey = "3e6176fb0367dfc59d914940f95c1007" -- jiffaco/emon

-- nastaveni hodin
function ClockInit()
    i2c.setup(0,gpionum[12],gpionum[14],i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
    i2c.write(0, 00) -- zapis adresy 
    i2c.write(0, 0x80) -- zapis sekundy + start oscilatoru
    i2c.write(0, 0x00) -- zapis minuty
    i2c.write(0, 0x00) -- zapis hodiny
    i2c.write(0, 0x08) -- den v tydnu, zapisuji abych zrustil power fail bit a zapnul Vbat 
    i2c.stop(0)
end

function ClockAlarm(Doba)
    i2c.start(0)
    i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
    i2c.write(0, 0x0A) -- zapis adresy registr casu buzeni sekundy
    i2c.write(0, 0x00) -- zapis sekundy 0
    i2c.write(0, Doba) -- zapis minuty, pozor je to BCD
    i2c.stop(0)
    
    i2c.start(0)
    i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
    i2c.write(0, 0x07) -- zapis adresy ovladani alarmu
    i2c.write(0, 0x10) -- zapis aktivace alarmu 0
    i2c.stop(0)
    
    i2c.start(0)
    i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
    i2c.write(0, 0x0D) -- zapis adresy registr nastaveni alarmu (registr dne)
    i2c.write(0, 0x10) -- alarm minutova shoda, vymazani
    i2c.stop(0)
end    

function ClockReadAll()
    i2c.start(0)
    i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
    i2c.write(0, 00) -- zapis adresy 
    i2c.start(0)
    i2c.address(0, 0x6F ,i2c.RECEIVER) -- zapis ridiciho slova / write
    local data = i2c.read(0, 16) -- vyctu 16 dat
    i2c.stop(0)

    print("RegisterDebugRead:")
    local q
    for q=1,16,1 do
        print ((q-1)..":"..string.byte(data,q))
    end
    print(" ")
end
    

ClockInit() -- init
ClockReadAll() -- debug
ClockAlarm(ReportInterval) -- vypnout na 3 minuty

-- na odeslani dat mam 30s pak se stejne vypnu
tmr.alarm(1, (SecurityOffInterval*1000), 0, function() gpio.write(gpionum[13],gpio.LOW) end) 
-- a ted spustim bezne odesilani
tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
