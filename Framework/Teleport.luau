local Utils = ...

local Connections = Utils.Connections
local Connect = Connections.Connect

local _ENV = (getgenv or getrenv or getfenv)()

local Framework, Cached = {}, {}

local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local RenderStepped = RunService.RenderStepped
local Stepped = RunService.Stepped

local Player = Players.LocalPlayer
local Backpack = Player.Backpack

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character and Character:WaitForChild('Humanoid', math.huge)
local PrimaryPart = Character and Character:WaitForChild('HumanoidRootPart', math.huge)

function Framework:IsAlive()
    if not Character then return end
    if not Humanoid then return end
    if not PrimaryPart then return end
    if not Backpack then return end

    return (Humanoid and Humanoid.Health > 0) or PrimaryPart ~= nil
end

Framework.TweenManager = function()
    local TweenManager = {}
    TweenManager.__index = TweenManager

    local Tweens = {}
    local EasingStyle = Enum.EasingStyle.Linear

    function TweenManager.new(Object, Time, Property, Value)
        local self = setmetatable({}, TweenManager)

        self.Value = Value
        self.Object = Object

        self.Info = TweenInfo.new(Time, EasingStyle)
        self.Tween = TweenService:Create(Object, self.Info, {
            [ Property ] = Value
        })

        self.Tween:Play()

        if Tweens[ Object ] then
            Tweens[ Object ]:Destroy()
        end

        Tweens[ Object ] = self

        return self
    end

    function TweenManager:Destroy()
        self.Tween:Pause()
        self.Tween:Destroy()

        Tweens[ self.Object ] = nil
        setmetatable(self, nil)
    end

    function TweenManager:StopTween(Object)
        if Object and Tweens[ Object ] then
            Tweens[ Object ]:Destroy()
        end
    end

    return TweenManager
end

Framework.BodyVelocity = function()
    local BodyVelocity = Instance.new("BodyVelocity") do
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVelocity.P = 1000
    end

    local Highlight = Instance.new("Highlight") do
        Highlight.FillColor = Color3.fromRGB(255, 255, 255)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = 0.3
    end

    if _ENV.tween_bodyvelocity then
        _ENV.tween_bodyvelocity:Destroy()
    end

    if _ENV.highlight then
        _ENV.highlight:Destroy()
    end

    _ENV.highlight = Highlight
    _ENV.tween_bodyvelocity = BodyVelocity

    local CanCollideObjects = {} do
        local function AddObjectToBaseParts(Object)
            if Object:IsA("BasePart") and Object.CanCollide then
                table.insert(CanCollideObjects, Object)
            end
        end

        local function RemoveObjectsFromBaseParts(BasePart)
            local index = table.find(CanCollideObjects, BasePart)

            if index then
                table.remove(CanCollideObjects, index)
            end
        end

        local function NewCharacter(Character)
            table.clear(CanCollideObjects)

            for _, Object in Character:GetDescendants() do AddObjectToBaseParts(Object) end
            Character.DescendantAdded:Connect(AddObjectToBaseParts)
            Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
        end

        Connect(Player.CharacterAdded, NewCharacter)
        task.spawn(NewCharacter, Character)
    end

    local function NoClipOnStepped(Character)
        if _ENV.OnFarm then
            for i = 1, #CanCollideObjects do
                CanCollideObjects[i].CanCollide = false
            end
        elseif Character.PrimaryPart and not Character.PrimaryPart.CanCollide then
            for i = 1, #CanCollideObjects do
                CanCollideObjects[i].CanCollide = true
            end
        end
    end

    local function UpdateVelocityOnStepped(Character)
        local BasePart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")

        local BodyVelocity = _ENV.tween_bodyvelocity
        local Highlight = _ENV.highlight

        if _ENV.OnFarm and BasePart and Humanoid and Humanoid.Health > 0 then
            if BodyVelocity.Parent ~= BasePart then
                BodyVelocity.Parent = BasePart
            end

            if Highlight.Parent ~= Character then
                Highlight.Parent = Character
            end
        elseif BodyVelocity.Parent then
            BodyVelocity.Parent = nil
            Highlight.Parent = nil
        end

        if BodyVelocity.Velocity ~= Vector3.zero and (not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm) then
            BodyVelocity.Velocity = Vector3.zero
            Highlight.Parent = nil
        end
    end

    Connect(RenderStepped, function()
        if Framework:IsAlive() then
            UpdateVelocityOnStepped(Character)
            NoClipOnStepped(Character)
        end
    end)

    Connect(Player.CharacterAdded, function(v)
        Character = v
        Humanoid = v:WaitForChild("Humanoid", math.huge)
        Backpack = Player:FindFirstChildOfClass('Backpack')
        PrimaryPart = v:WaitForChild("HumanoidRootPart", math.huge)
    end)

    return BodyVelocity
end

Framework.Init = function()
    local TeleportModule = {} do
        TeleportModule.Type = 'Teleport'
        TeleportModule.Velocity = 300
        TeleportModule.AlwayLinear = false
    end

    local TweenManager = Framework.TweenManager()
    local BodyVelocity = Framework.BodyVelocity()

    local Handlers = {} do
        Handlers.Teleport = function(Target)
            _ENV.OnFarm = true
            Character:PivotTo(Target)
        end

        Handlers.Tween = function(Target, Siting)
            if typeof(Target) == "Vector3" then
                Target = CFrame.new(Target)
            end

            if not Siting and Humanoid.Sit then
                Humanoid.Sit = false
            end

            local Position = PrimaryPart.Position
            local TargetY = Target.Position.Y

            local Velocity = TeleportModule.Velocity
            local Distance = (Position - Target.Position).Magnitude
            local IsLinear = math.abs(Position.Y - Target.Position.Y) <= 5

            _ENV.OnFarm = true

            if TeleportModule.AlwayLinear and not IsLinear then
                TweenManager:StopTween(PrimaryPart)
                PrimaryPart.CFrame = CFrame.new(Position.X, TargetY, Position.Z)
                task.wait(0.1)
            end

            return TweenManager.new(PrimaryPart, Distance / Velocity, "CFrame", Target)
        end

        Handlers.Lerp = function(Function, Break, Siting)
            local Target = Function and Function()
            if not Target then return end

            if typeof(Target) == "Vector3" then
                Target = CFrame.new(Target)
            end

            if typeof(Target) ~= "CFrame" then
                return
            end

            while _ENV.OnFarm and Framework:IsAlive() do
                local DeltaTime = RunService.Heartbeat:Wait()

                if not Siting and Humanoid.Sit then
                    Humanoid.Sit = false
                end

                Target = Function and Function()
                if not Target then break end

                if typeof(Target) == "Vector3" then
                    Target = CFrame.new(Target)
                end

                if typeof(Target) ~= "CFrame" then
                    break
                end

                local StartCFrame = Character:GetPivot()
                local Position = StartCFrame.Position
                local TargetY = Target.Position.Y
                local Distance = (Position - Target.Position).Magnitude
                local IsLinear = math.abs(Position.Y - TargetY) <= 5

                if TeleportModule.AlwayLinear and not IsLinear then
                    Character:PivotTo(CFrame.new(Position.X, TargetY, Position.Z))
                    StartCFrame = Character:GetPivot()
                    Position = StartCFrame.Position
                    Distance = (Position - Target.Position).Magnitude
                end

                if Distance <= 0.1 then
                    Character:PivotTo(Target)
                else
                    local Alpha = math.clamp((TeleportModule.Velocity * DeltaTime) / Distance, 0, 1)
                    Character:PivotTo(StartCFrame:Lerp(Target, Alpha))
                end

                if Break and Break() then
                    break
                end
            end
        end
    end

    function TeleportModule:To( ... )
        if not Framework:IsAlive() then return end

        if Handlers[ TeleportModule.Type ] then
            Handlers[ TeleportModule.Type ]( ... )
        end 
    end

    Connect(BodyVelocity:GetPropertyChangedSignal("Parent"), function()
        if not BodyVelocity.Parent and Framework:IsAlive() then
            TweenManager:StopTween(PrimaryPart)
        end
    end)

    return TeleportModule
end

return Framework.Init()
