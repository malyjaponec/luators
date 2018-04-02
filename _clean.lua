-- prelozeni souboru dalas a mozna casem dalsich
local name

name = "analog"
file.remove(name..".lc")

name = "baro"
file.remove(name..".lc")

name = "battery"
file.remove(name..".lc")

name = "dalas"
file.remove(name..".lc")

name = "dht22"
file.remove(name..".lc")

name = "distance"
file.remove(name..".lc")

name = "digital"
file.remove(name..".lc")

name = "ds18b20"
file.remove(name..".lc")

name = "luxmeter"
file.remove(name..".lc")

name = "measure"
file.remove(name..".lc")

name = "measure_elektro"
file.remove(name..".lc")

name = "measure_plyn"
file.remove(name..".lc")

name = "network"
file.remove(name..".lc")

name = "send"
file.remove(name..".lc")

name = "setup"
file.remove(name..".lc")

name = "restart"
file.remove(name..".lc")

name = "receive"
file.remove(name..".lc")

name = "reload"
file.remove(name..".lc")

name = "rgb"
file.remove(name..".lc")

name = "reset"
file.remove(name..".lc")

name = "triple"
file.remove(name..".lc")

name = "weight"
file.remove(name..".lc")

-- "sleep" - se nepreklada, pred deepsleepem me uz na nejake pametove narocnosti nesejde
-- "init" - se preklada ale pak se prejmenuje na lua, to delam rucne

name = nil