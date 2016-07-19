-- prelozeni souboru dalas a mozna casem dalsich
local name

name = "baro"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "battery"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "dalas"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "dht22"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "ds18b20"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "network"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "send"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

name = "setup"
file.remove(name..".lc")
node.compile(name..".lua")
if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
file.close()

-- "sleep" - se nepreklada, pred deepsleepem me uz na nejake pametove narocnosti nesejde
-- "init" - se preklada ale pak se prejmenuje na lua, to delam rucne

name = nil