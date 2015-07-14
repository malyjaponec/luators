t = require("ds18b20")

-- ESP-01 GPIO Mapping
gpio0 = 3
gpio2 = 4
pin_bus = 7

t.setup(pin_bus)
addrs = t.addrs()
if (addrs ~= nil) then
  print("Total DS18B20 sensors: "..table.getn(addrs))
  
-- Just read temperature
    for a,b in pairs(addrs) do
        print("Temperature "..a.." = "..t.read(b).."'C")
    end

end

-- Don't forget to release it after use
t = nil
ds18b20 = nil
package.loaded["ds18b20"]=nil
