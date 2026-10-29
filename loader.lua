-- เพิ่มเกมใหม่ในตารางนี้:
-- [GameId] = "Raw URL",

local Scripts = {
    [10762636904] = "https://raw.githubusercontent.com/MomoHub007/ZeroX-Best-Script/refs/heads/main/Games/Camera%20Tower%20Defends.lua",
    
}

local gameId = game.GameId
local url = Scripts[gameId]

if not url then
    warn(("[ZERO X] ยังไม่รองรับ GameId: %s"):format(tostring(gameId)))
    return
end

local environment = if type(getgenv) == "function" then getgenv() else _G
local guardKey = "__ZEROX_MULTI_GAME_LOADER"

if environment[guardKey] then
    warn("[ZERO X] Loader กำลังโหลด หรือรันสคริปต์ไปแล้ว")
    return
end

if type(loadstring) ~= "function" then
    warn("[ZERO X] สภาพแวดล้อมนี้ไม่รองรับ loadstring")
    return
end

environment[guardKey] = true

local downloaded, source = pcall(function()
    return game:HttpGet(url)
end)

if not downloaded or type(source) ~= "string" or source == "" then
    environment[guardKey] = nil
    warn("[ZERO X] ดาวน์โหลดสคริปต์ไม่สำเร็จ:", source)
    return
end

local scriptFunction, compileError = loadstring(source)

if not scriptFunction then
    environment[guardKey] = nil
    warn("[ZERO X] Compile ไม่สำเร็จ:", compileError)
    return
end

-- ExecuteScript: เรียกสคริปต์และแสดง Error หากทำงานไม่สำเร็จ
local executed, runtimeError = pcall(scriptFunction)

if not executed then
    environment[guardKey] = nil
    warn("[ZERO X] สคริปต์เกิด Runtime Error:", runtimeError)
end
