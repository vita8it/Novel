local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage.Packages.Networking

for _, Table in getgc(true) do
    if typeof(Table) ~= "table" then continue end
    if getrawmetatable(Table) then continue end

    local IsCircular = false
    for _, V in Table do
        if typeof(V) == "table" and Table == V then
            IsCircular = true
            break
        end
    end
    if not IsCircular then continue end

    local BanIndex
    for _, V in Table do
        if typeof(V) ~= "number" then continue end
        for I = 1, 3 do
            if V == I then BanIndex = I break end
        end
        if BanIndex then break end
    end

    if BanIndex and Table[BanIndex] == nil then
        setrawmetatable(Table, { __newindex = function() end })
    end
end

for _, Fn in filtergc("function", { Constants = {"X-16"} }) do
    for I, Upval in debug.getupvalues(Fn) do
        pcall(setmetatable, Upval, { __newindex = function() end })
    end
end

local Info = filtergc("table", { Keys = { "Character", "MonitorPending" } }, true)
local SamplerFn = filtergc("function", { Constants = { "Character integrity sampling was intercepted" } }, true)
local Upvalues = debug.getupvalues(SamplerFn)

local LPHVars = {}
for _, Table in Upvalues do
    if typeof(Table) ~= "table" then continue end

    local BanIdx
    for _, V in Table do
        if typeof(V) ~= "number" then continue end
        for I = 1, 3 do
            if V == I then BanIdx = I break end
        end
        if BanIdx then break end
    end

    LPHVars[#LPHVars + 1] = Table[BanIdx]
end

local Interval = 4
local Tick = .05
local Seed = LPHVars[4]
local T = LPHVars[5]

local ProbeSatchel = Net["RE/RigSync/ProbeSatchel"]

task.spawn(function()
    task.wait(math.max(0, Interval - (os.clock() - T)))
    while true do
        Seed += Interval / Tick
        ProbeSatchel:FireServer(Info.Character, Seed)
        task.wait(Interval)
    end
end)

for _, Thread in getreg() do
    if typeof(Thread) ~= "thread" then continue end
    local Src = debug.info(Thread, 1, "s")
    if Src and Src:find("ContentCatalog") then
        coroutine.close(Thread)
    end
end

for _, Fn in getgc(false) do
    if typeof(Fn) ~= "function" then continue end
    local Src = debug.info(Fn, "s")
    if Src and Src:find("ContentCatalog") then
        hookfunction(Fn, function() end)
    end
end
