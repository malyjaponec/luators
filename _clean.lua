-- prelozeni souboru dalas a mozna casem dalsich
local name

name = "baro"
file.remove(name..".lc")

name = "battery"
file.remove(name..".lc")

name = "dalas"
file.remove(name..".lc")

name = "dht22"
file.remove(name..".lc")

name = "ds18b20"
file.remove(name..".lc")

name = "network"
file.remove(name..".lc")

name = "send"
file.remove(name..".lc")

name = "setup"
file.remove(name..".lc")

-- "sleep" - se nepreklada, pred deepsleepem me uz na nejake pametove narocnosti nesejde
-- "init" - se preklada ale pak se prejmenuje na lua, to delam rucne

name = nil