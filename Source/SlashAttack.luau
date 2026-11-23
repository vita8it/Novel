-- [[ Novel LLC Softwork, @8itcode ]]

pcall(run_on_actor, getactors()[1], (function()
    return [=[
local _ENV = (getgenv or getrenv or getfenv)()

local Module, Settings = {}, {}

local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')

local Player = Players.LocalPlayer

local GameContext = filtergc('table', {
    Keys = { 'Prefix', 'Invoked', 'Loadout', 'Cache', 'Modules' }
}, true)

local Cache = GameContext.Cache
local Variables = Cache.Variables
local Slash = Variables.Slash

Module.Utilities = (function()
    local Sources = {
        NVL_ODMG = { Name = 'M1', Source = 'Core.ODMG' },
        NVL_RELOAD = { Name = 'Reload', Source = 'Core.ODMG' },
        NVL_BLADE_CHECK = { Name = 'Blade_Check', Source = 'Core.ODMG' },
        NVL_SHIFT = { Name = 'M2', Source = 'Core.Shift' },
        NVL_SLASH = { Name = 'Slash', Source = 'Core.Input' },
    }

    local function Validate(Function)
        if type(Function) ~= 'function' then return end

        local Source = debug.info(Function, 's')
        local Name = debug.info(Function, 'n')

        for Key, Entry in Sources do
            if _ENV[Key] then continue end
            if Name == Entry.Name and Source:find(Entry.Source, 1, true) then
                _ENV[Key] = Function
            end
        end
    end

    task.defer(function()
        for _, Function in getgc(true) do
            Validate(Function)
        end
    end)
end)()

_ENV.GAME_CONTEXT = GameContext
_ENV.SLASH_ATTACK = function()
    if _ENV.USE_THUNDER_SPEAR then return end
    if not _ENV.NVL_BLADE_CHECK then return end
    if not _ENV.NVL_RELOAD then return end
    if not _ENV.NVL_SHIFT then return end
    if not _ENV.NVL_SLASH then return end
    if not _ENV.NVL_ODMG then return end

    local Character = Player.Character
    if not Character then return end

    local RootPart = Character.PrimaryPart
    if not RootPart then return end

    local Hitbox = Character:FindFirstChild('Hitbox')
    if not Hitbox then return end

    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
    if not Humanoid then return end

    local Stats = GameContext.Loadout and GameContext.Loadout.Stats
    local BladesOk = _ENV.NVL_BLADE_CHECK(GameContext)
    local BladeDurability = Stats and (Stats.Blade_Durability or 0) or 0

    if not Variables.Reload and not Variables.Full_Reload and (not BladesOk or BladeDurability <= 0) then
        _ENV.NVL_RELOAD(GameContext)
        return task.wait(0.2)
    end

    local Heavy = Variables.Heavy
    if Heavy and not Heavy.Hitting and Heavy.Transition == nil and not Variables.Full_Reload then
        _ENV.NVL_SHIFT(GameContext)
        task.wait(0.05)
    end

    if Heavy then
        Heavy.Hitting = false
        Heavy.Transition = nil
    end

    local Titans = workspace:FindFirstChild('Titans')
    if not Titans then return end
    
    local Targets = {} do
    for _, Titan in Titans:GetChildren() do
        local Nape = Titan.Hitboxes and Titan.Hitboxes.Hit and Titan.Hitboxes.Hit.Nape
        local TitanHum = Titan:FindFirstChildOfClass('Humanoid')
        if not (Nape and TitanHum and TitanHum.Health > 0) then continue end

        Targets[#Targets + 1] = {
            Nape = Nape,
            Distance = (Nape.Position - RootPart.Position).Magnitude
        }
    end

    table.sort(Targets, function(A, B)
        return A.Distance < B.Distance
    end)

    for Index, Entry in Targets do
        Targets[Index] = Entry.Nape
    end
end

    if #Targets ~= 0 then
        Settings.Guard = 0

        while (Slash.Slashing or Variables.Reload or Variables.Full_Reload) and Settings.Guard < 200 do
            Settings.Guard += 1;task.wait(0.02)
        end

        if Slash.Slashing then Slash.Slashing = false end

        Slash.Released = false
        Slash.Holding = false

        _ENV.NVL_ODMG(GameContext, false);task.wait(0.02)
        _ENV.NVL_SLASH(GameContext, RootPart, Humanoid);task.wait(0.02)

        local TimeDiff = Variables.Time_Difference or 0.05 do
            GameContext:Send('Attacks', 'Slash', true) 
        end

        for _, Nape in Targets do
            task.spawn(function()
                GameContext:Send('Hitboxes', 'Register', Nape, TimeDiff)
                pcall(firesignal, Hitbox.Touched, Nape)
            end)
        end

        task.wait(0.03) do
            GameContext:Send('Attacks', 'Slash', false) 
        end 
    end
end

      while task.wait() do pcall(_ENV.SLASH_ATTACK) end
    ]=]
end)())
