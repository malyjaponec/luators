-- prelozeni souboru dalas a mozna casem dalsich

file.remove("dalas.lc")
file.remove("dalas1.lc")
node.compile("dalas.lua")
file.rename("dalas.lc","dalas1.lc")
node.compile("dalas.lua")


file.remove("ds18b20.lc")
file.remove("ds18b201.lc")
node.compile("ds18b20.lua")
file.rename("ds18b20.lc","ds18b201.lc")
node.compile("ds18b20.lua")
