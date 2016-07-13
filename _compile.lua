-- prelozeni souboru dalas a mozna casem dalsich

file.remove("dalas.lc")
file.remove("dalas1.lc")
node.compile("dalas.lua")
file.rename("dalas.lc","dalas1.lc")
node.compile("dalas.lua")



