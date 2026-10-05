local Utils = ...

local Connections = Utils.Connections
local Connect = Connections.Connect

local ENV = (getgenv or getrenv or getfenv)()

local Framework, Cached = {}, {}

local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local RenderStepped = RunService.RenderStepped
local Stepped = RunService.Stepped
local Heartbeat = RunService.Heartbeat

local Player = Players.LocalPlayer
local Backpack = Player.Backpack

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character and Character:WaitForChild('Humanoid', math.huge)
local PrimaryPart = Character and Character:WaitForChild('HumanoidRootPart', math.huge)

local V3Zero = Vector3.zero
local V3Inf = Vector3.new(math.huge, math.huge, math.huge)
local TypeOf = typeof
local MathAbs = math.abs
local MathClamp = math.clamp

function Framework:IsAlive()
    return Character ~= nil
        and Humanoid ~= nil
        and PrimaryPart ~= nil
        and Backpack ~= nil
        and Humanoid.Health > 0
end

Framework.TweenManager = function()
    local TweenManager = {}
    TweenManager.__index = TweenManager

    local Tweens = {}
    local EasingStyle = Enum.EasingStyle.Linear

    function TweenManager.New(Object, Time, Property, Value)
        local Self = setmetatable({}, TweenManager)

        Self.Value = Value
        Self.Object = Object
        Self.Info = TweenInfo.new(Time, EasingStyle)
        Self.Tween = TweenService:Create(Object, Self.Info, { [Property] = Value })

        local Existing = Tweens[Object]
        if Existing then
            Existing:Destroy()
        end

        Tweens[Object] = Self
        Self.Tween:Play()

        return Self
    end

    function TweenManager:Destroy()
        if self.Tween then
            self.Tween:Pause()
            self.Tween:Destroy()
            self.Tween = nil
        end

        Tweens[self.Object] = nil
        setmetatable(self, nil)
    end

    function TweenManager:StopTween(Object)
        local T = Object and Tweens[Object]
        if T then
            T:Destroy()
        end
    end

    return TweenManager
end

Framework.BodyVelocity = function()
    local BodyVelocity = Instance.new("BodyVelocity") do
        BodyVelocity.Velocity = V3Zero
        BodyVelocity.MaxForce = V3Inf
        BodyVelocity.P = 1000
    end

    local Highlight = Instance.new("Highlight") do
        Highlight.FillColor = Color3.fromRGB(255, 255, 255)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = 0.3
    end

    local PrevBodyVelocity = ENV.TweenBodyVelocity
    local PrevHighlight = ENV.Highlight

    if PrevBodyVelocity then PrevBodyVelocity:Destroy() end
    if PrevHighlight then PrevHighlight:Destroy() end

    ENV.Highlight = Highlight
    ENV.TweenBodyVelocity = BodyVelocity

    local CanCollideObjects = {} do
        local function AddObjectToBaseParts(Object)
            if Object:IsA("BasePart") and Object.CanCollide then
                CanCollideObjects[#CanCollideObjects + 1] = Object
            end
        end

        local function RemoveObjectsFromBaseParts(BasePart)
            local Index = table.find(CanCollideObjects, BasePart)
            if Index then
                table.remove(CanCollideObjects, Index)
            end
        end

        local function NewCharacter(Char)
            table.clear(CanCollideObjects)

            for _, Object in Char:GetDescendants() do
                AddObjectToBaseParts(Object)
            end

            Char.DescendantAdded:Connect(AddObjectToBaseParts)
            Char.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
        end

        Connect(Player.CharacterAdded, NewCharacter)
        task.spawn(NewCharacter, Character)
    end

    local function NoClipOnStepped(Char)
        local OnFarm = ENV.OnFarm
        local Count = #CanCollideObjects

        if OnFarm then
            for I = 1, Count do
                CanCollideObjects[I].CanCollide = false
            end
        elseif Char.PrimaryPart and not Char.PrimaryPart.CanCollide then
            for I = 1, Count do
                CanCollideObjects[I].CanCollide = true
            end
        end
    end

    local function UpdateVelocityOnStepped(Char)
        local BasePart = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")

        local BV = ENV.TweenBodyVelocity
        local HL = ENV.Highlight

        if not BV or not HL then return end

        local OnFarm = ENV.OnFarm
        local IsAlive = BasePart and Hum and Hum.Health > 0

        if OnFarm and IsAlive then
            if BV.Parent ~= BasePart then
                BV.Parent = BasePart
            end

            if HL.Parent ~= Char then
                HL.Parent = Char
            end
        elseif BV.Parent then
            BV.Parent = nil
            HL.Parent = nil
        end

        if BV.Velocity ~= V3Zero and (not Hum or not Hum.SeatPart or not OnFarm) then
            BV.Velocity = V3Zero
            HL.Parent = nil
        end
    end

    Connect(RenderStepped, function()
        if Framework:IsAlive() then
            local Char = Player.Character
            if Char then
                UpdateVelocityOnStepped(Char)
                NoClipOnStepped(Char)
            end
        end
    end)

    Connect(Player.CharacterAdded, function(V)
        Character = V
        Humanoid = V:WaitForChild("Humanoid", math.huge)
        Backpack = Player:FindFirstChildOfClass('Backpack')
        PrimaryPart = V:WaitForChild("HumanoidRootPart", math.huge)
    end)

    return BodyVelocity
end

Framework.Init = function()
    local TeleportModule = {} do
        TeleportModule.Type = 'Teleport'
        TeleportModule.Velocity = 300
        TeleportModule.AlwayLinear = false
        TeleportModule.OnStoped = function() end
    end

    TeleportModule.Untouch = (function()
        local Untouch = {
            UnTouches = {},
            Connection = nil,
        }

        function Untouch:Enabled()
            if self.Connection then return end

            self.Connection = Connect(Stepped, function()
                if not Character then return end

                for _, BasePart in Character:GetDescendants() do
                    if BasePart:IsA("BasePart") and BasePart.CanTouch then
                        BasePart.CanTouch = false
                        self.UnTouches[BasePart] = true
                    end
                end
            end)
        end

        function Untouch:Disabled()
            if self.Connection then
                self.Connection:Disconnect()
                self.Connection = nil
            end

            for BasePart in self.UnTouches do
                if TypeOf(BasePart) == "Instance"
                    and BasePart:IsA("BasePart")
                    and BasePart.Parent
                then
                    BasePart.CanTouch = true
                end
            end

            table.clear(self.UnTouches)
        end

        function Untouch:SetValue(Value)
            if Value then
                self:Enabled()
            else
                self:Disabled()
            end
        end

        return Untouch
    end)()

    local TweenManager = Framework.TweenManager()
    local BodyVelocity = Framework.BodyVelocity()

    local Handlers = {} do
        Handlers.Teleport = function(Target)
            Character:PivotTo(Target)
        end

        Handlers.Tween = function(Target, Siting)
            if TypeOf(Target) == "Vector3" then
                Target = CFrame.new(Target)
            end

            if not Siting and Humanoid.Sit then
                Humanoid.Sit = false
            end

            local Position = PrimaryPart.Position
            local Distance = (Position - Target.Position).Magnitude

            if TeleportModule.AlwayLinear and MathAbs(Position.Y - Target.Position.Y) > 5 then
                TweenManager:StopTween(PrimaryPart)
                PrimaryPart.CFrame = CFrame.new(Position.X, Target.Position.Y, Position.Z)
                task.wait(0.1)
            end

            return TweenManager.New(PrimaryPart, Distance / TeleportModule.Velocity, "CFrame", Target)
        end

        Handlers.Lerp = function(Function, Break, Siting)
            local Target = Function and Function()
            if not Target then return end

            if TypeOf(Target) == "Vector3" then
                Target = CFrame.new(Target)
            end

            if TypeOf(Target) ~= "CFrame" then return end

            while ENV.OnFarm and Framework:IsAlive() do
                local DeltaTime = Heartbeat:Wait()

                if not Siting and Humanoid.Sit then
                    Humanoid.Sit = false
                end

                Target = Function and Function()
                if not Target then break end

                if TypeOf(Target) == "Vector3" then
                    Target = CFrame.new(Target)
                end

                if TypeOf(Target) ~= "CFrame" then break end

                local StartCFrame = Character:GetPivot()
                local Position = StartCFrame.Position
                local Distance = (Position - Target.Position).Magnitude

                if TeleportModule.AlwayLinear and MathAbs(Position.Y - Target.Position.Y) > 5 then
                    Character:PivotTo(CFrame.new(Position.X, Target.Position.Y, Position.Z))
                    StartCFrame = Character:GetPivot()
                    Distance = (StartCFrame.Position - Target.Position).Magnitude
                end

                if Distance <= 0.1 then
                    Character:PivotTo(Target)
                else
                    local Alpha = MathClamp((TeleportModule.Velocity * DeltaTime) / Distance, 0, 1)
                    Character:PivotTo(StartCFrame:Lerp(Target, Alpha))
                end

                if Break and Break() then break end
            end
        end
    end

    function TeleportModule:To( ... )
        if not Framework:IsAlive() then return end

        local Handler = Handlers[TeleportModule.Type]
        if Handler then
            Handler( ... )
        end
    end

    function TeleportModule:Stop()
        if not BodyVelocity.Parent and Framework:IsAlive() then
            TweenManager:StopTween(PrimaryPart)
            TeleportModule.Untouch:SetValue(false)
            TeleportModule.OnStoped()
        else
            TeleportModule.Untouch:SetValue(true)
        end
    end

    Connect(BodyVelocity:GetPropertyChangedSignal("Parent"), function()
        TeleportModule:Stop()
    end)

    return TeleportModule
end

return Framework.Init()
