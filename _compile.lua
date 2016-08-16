-- prelozeni souboru dalas a mozna casem dalsich
local name

name = "baro"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "battery"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "dalas"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "dht22"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "distance"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "ds18b20"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "network"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "send"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "setup"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "restart"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

name = "reload"
file.remove(name..".lc")
if file.open(name..".lua", "r") ~= nil then
    file.close()
    node.compile(name..".lua")
    if file.open(name..".lc", "r") == nil then print(name..".lua failed") end
    file.close()
end

-- "sleep" - se nepreklada, pred deepsleepem me uz na nejake pametove narocnosti nesejde
-- "init" - se preklada ale pak se prejmenuje na lua, to delam rucne

name = nil
