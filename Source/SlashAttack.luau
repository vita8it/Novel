--[[
    titan_farm.luau -- auto-farm: move to nearest Titan's Nape in small
    steps (to stay under server speed checks), slash every 1s, reload blades,
    and force every hit to register as Nape.
]]

local STEP = 400      -- studs per frame (instant warp)
local REACH = 10      -- start slashing within this distance
local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local char    = player.Character or player.CharacterAdded:Wait()

local actor
repeat task.wait() until char:FindFirstChildOfClass("Actor")
actor = char:FindFirstChildOfClass("Actor")

-- 1. Loadout
run_on_actor(actor, [[
    getgenv().Loadout = filtergc("table", {
        Keys = { "Prefix", "Invoked", "Loadout", "Cache", "Modules" }
    }, true)
]])
task.wait(1)

-- 2. Nape swap hook
run_on_actor(actor, [[
    local t = getgenv().Loadout
    if not t or getgenv().__NAPE_HOOKED then return end
    getgenv().__NAPE_HOOKED = true
    local old = t.Send
    t.Send = function(self, ch, op, ...)
        if ch == "Hitboxes" and op == "Register" then
            local part = select(1, ...)
            -- Already a Nape (all-titan burst): leave it alone.
            if typeof(part) == "Instance" and part.Name == "Nape" then
                return old(self, ch, op, ...)
            end
            local a = game.Workspace
            local root = game.Players.LocalPlayer.Character
                and game.Players.LocalPlayer.Character.PrimaryPart
            local best, bd = nil, math.huge
            for _, m in ipairs(a.Titans:GetChildren()) do
                local n = m.Hitboxes and m.Hitboxes.Hit and m.Hitboxes.Hit.Nape
                local h = m:FindFirstChildOfClass("Humanoid")
                if n and h and h.Health > 0 and root then
                    local d = (n.Position - root.Position).Magnitude
                    if d < bd then best, bd = n, d end
                end
            end
            if best then
                a:SetAttribute("__SWAP", "Nape")
                return old(self, ch, op, best, select(2, ...))
            end
        end
        return old(self, ch, op, ...)
    end
]])

-- 3. Farm loop
run_on_actor(actor, string.format([[

    local t = getgenv().Loadout
    if not t then return end
    getgenv().__FARM_ON = false
    task.wait(0.1)
    getgenv().__FARM_ON = true
    local step, reach = %s, %s

    local M1, Slash, Reload, M2, Blade_Check
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" then
            local n, s = "", ""
            pcall(function() n = debug.info(v, "n") or "" end)
            pcall(function() s = debug.info(v, "s") or "" end)
            if n == "M1" and s:find("Core.ODMG", 1, true) then M1 = v end
            if n == "Slash" and s:find("Core.Input", 1, true) then Slash = v end
            if n == "Reload" and s:find("Core.ODMG", 1, true) then Reload = v end
            -- MouseButton2 / Heavy attack lives in Core.Shift as M2.
            if n == "M2" and s:find("Core.Shift", 1, true) then M2 = v end
            -- Real blade availability check (LeftHand/RightHand Blade_1..7 Broken).
            if n == "Blade_Check" and s:find("Core.ODMG", 1, true) then Blade_Check = v end
        end
    end

    local a  = game.Workspace
    local rs = game:GetService("RunService")
    local ch = game.Players.LocalPlayer.Character
    local root = ch.PrimaryPart
    local hb = ch:FindFirstChild("Hitbox")

    local function nearest()
        local best, bd = nil, math.huge
        local chNow = game.Players.LocalPlayer.Character
        local rootNow = chNow and chNow.PrimaryPart
        if not rootNow then return nil, math.huge end
        for _, m in ipairs(a.Titans:GetChildren()) do
            local n = m.Hitboxes and m.Hitboxes.Hit and m.Hitboxes.Hit.Nape
            local h = m:FindFirstChildOfClass("Humanoid")
            if n and h and h.Health > 0 then
                local d = (n.Position - rootNow.Position).Magnitude
                if d < bd then best, bd = n, d end
            end
        end
        return best, bd
    end

    -- The attack loop below warps to each target itself, so no separate pin loop.
    task.spawn(function()
        while getgenv().__FARM_ON do
            task.wait(0.5)
        end
    end)

    task.spawn(function()
        while getgenv().__FARM_ON do
            local chNow = game.Players.LocalPlayer.Character
            local rootNow = chNow and chNow.PrimaryPart
            local hbNow = chNow and chNow:FindFirstChild("Hitbox")
            if rootNow and hbNow and M1 and Slash then
                local stats = t.Loadout and t.Loadout.Stats
                local sv = t.Cache.Variables.Slash
                local vars = t.Cache.Variables

                -- One reload per cycle when blades are gone.
                local bladesOk = true
                if Blade_Check then
                    local okCheck = pcall(function() bladesOk = Blade_Check(t) end)
                    if not okCheck then bladesOk = true end
                end
                if Reload and not vars.Reload and not vars.Full_Reload
                    and (not bladesOk or (stats and (stats.Blade_Durability or 0) <= 0)) then
                    pcall(function() Reload(t) end)
                    task.wait(0.2)
                end

                -- Heavy attack once per cycle, then clear so slash can register.
                local heavy = vars.Heavy
                if M2 and heavy and not heavy.Hitting and heavy.Transition == nil
                    and not vars.Full_Reload then
                    pcall(function() M2(t) end)
                    task.wait(0.05)
                end
                if heavy then
                    heavy.Hitting = false
                    heavy.Transition = nil
                end

                -- Hit EVERY living Titan this cycle.
                local targets = {}
                for _, m in ipairs(a.Titans:GetChildren()) do
                    local n = m.Hitboxes and m.Hitboxes.Hit and m.Hitboxes.Hit.Nape
                    local h = m:FindFirstChildOfClass("Humanoid")
                    if n and h and h.Health > 0 then targets[#targets + 1] = n end
                end

                -- One slash state, then hit ALL living Titans in a single burst.
                local guard = 0
                while (sv.Slashing or vars.Reload or vars.Full_Reload)
                    and guard < 200 do
                    task.wait(0.02)
                    guard += 1
                end
                if sv.Slashing then sv.Slashing = false end

                if not sv.Slashing then
                    pcall(function()
                        sv.Released = false
                        sv.Holding = false
                        M1(t, false)
                        task.wait(0.02)
                        Slash(t, rootNow, chNow:FindFirstChildOfClass("Humanoid"))
                        task.wait(0.02)
                        -- Exact network sequence for every target in one burst.
                        local td = vars.Time_Difference or 0.05
                        t:Send("Attacks", "Slash", true)
                        for _, n in ipairs(targets) do
                            task.spawn(function()
                                -- Hook passes Nape parts through unchanged.
                                pcall(function()
                                    t:Send("Hitboxes", "Register", n, td)
                                end)
                                pcall(function() firesignal(hbNow.Touched, n) end)
                            end)
                        end
                        task.wait(0.03)
                        t:Send("Attacks", "Slash", false)
                    end)
                    a:SetAttribute("__BURST", #targets)
                end
                task.wait(0.1)
            else
                task.wait(0.2)
            end
        end
    end)

    a:SetAttribute("__FARM", "running")
]], tostring(STEP), tostring(REACH)))

function stopFarm()
    run_on_actor(actor, [[
        getgenv().__FARM_ON = false
        game.Workspace:SetAttribute("__FARM", "stopped")
    ]])
end

print("[farm] running -- step=" .. STEP .. " reach=" .. REACH)
