local _ENV = (getgenv or getrenv or getfenv)()

local Owner = "vita8it"
local Respoitory = "Novel"

local HIDDEN_SETTINGS = {} do
    HIDDEN_SETTINGS.SPECIES = {}
    HIDDEN_SETTINGS.LASSOS = {}
end

local Module, Cached = {}, {}

function Module:Import(Path)
    local Github = 'https://raw.githubusercontent.com/%s'
    local Direct = `{Owner}/{Respoitory}/main/{Path}.luau`
    local Formater = Github:format(Direct)
    local Success, Result = pcall(function()
        return game:HttpGet(Formater)
    end)
    return loadstring(Result)
end 

local Utils, Settings = Module:Import('Modules/Utils')()

local VirtualInputManager = game:GetService('VirtualInputManager')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local GuiService = game:GetService("GuiService")
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local Interactions = workspace:WaitForChild('Interactions')
local MobFolder = workspace:WaitForChild('MobFolder')

local Sonar = require(ReplicatedStorage:WaitForChild("Sonar"))
local Storage = ReplicatedStorage:WaitForChild('Storage')
local Remotes = ReplicatedStorage:WaitForChild('Remotes')

local Animals = Storage:WaitForChild('Animals')
local PlayerWrapper = Sonar("PlayerWrapper")
local RemoteUtils = Sonar("RemoteUtils")
local MobAnimator = Sonar("MobAnimator")
local ShopService = Sonar("ShopService")

local Client = PlayerWrapper.GetClient()
local Camera = workspace.CurrentCamera

local Connections = Utils.Connections
local EachOthers = Utils.EachOthers
local GoodQueue = Utils.GoodQueue
local Plugins = Utils.Plugins

local Render = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Connect = Connections.Connect
local Stepped = RunService.Stepped

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Backpack = Player.Backpack

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character and Character:WaitForChild('Humanoid', math.huge)
local PrimaryPart = Character and Character:WaitForChild('HumanoidRootPart', math.huge)

Module.HorseModule = (function()
    local HorseModule = {}
    local Species = Animals:WaitForChild("Species")
    
    function HorseModule:GetClosest()
        local Closest, Distance = nil, math.huge

        for _, Horse in MobFolder:GetChildren() do
            if not Horse.Parent then continue end
            local Magnitude = Player:DistanceFromCharacter(Horse.Position)

            if Magnitude < Distance then
                Closest, Distance = Horse, Magnitude
            end
        end

        return Closest
    end

    for _, Specie in Species:GetChildren() do
        table.insert(HIDDEN_SETTINGS.SPECIES, Species.Name)
    end

    return HorseModule
end)()

Module.LassoManager = (function()
    local LassoManager = {}

    local ItemDataService = Sonar("ItemDataService")
    local HotbarService = Sonar("HotbarService")
    
    local SetHotbarRemote = Remotes:WaitForChild('SetHotbarRemote')

    local function GetItemName(Value)
        if Value:IsA("StringValue") then
            return Value.Value
        end

        return Value.Name
    end

    local function IsValidData(Data)
        return Data ~= nil and type(Data.Distance) == "number" and type(Data.Hit) == "number"
    end

    local function IsBetter(Data, BestData)
        if not BestData then return true end

        if Data.Distance ~= BestData.Distance then
            return Data.Distance > BestData.Distance
        end

        if Data.Hit ~= BestData.Hit then
            return Data.Hit > BestData.Hit
        end

        return (Data.Cooldown or 2) < (BestData.Cooldown or 2)
    end

    local function PickBest(Candidates)
        local BestKey = nil
        local BestData = nil

        for Key, Name in pairs(Candidates) do
            local Data = ItemDataService.GetByName(Name)

            if IsValidData(Data) and IsBetter(Data, BestData) then
                BestKey = Key
                BestData = Data
            end
        end

        return BestKey, BestData
    end

    function LassoManager:GetOwnedLassos()
        local Owned = {}
        
        local Folder = Client:GetItemFolder("Tools")
        if not Folder then return Owned end

        for _, Value in ipairs(Folder:GetChildren()) do
            local Name = GetItemName(Value)
            local Data = ItemDataService.GetByName(Name)

            if Data and Data.ToolType == "Lasso" then
                local Amount = Value:IsA("IntValue") and Value.Value or 1

                if Amount > 0 then
                    Owned[Name] = (Owned[Name] or 0) + Amount
                end
            end
        end

        return Owned
    end

    function LassoManager:GetBestLasso()
        local Tools = {}

        for _, Container in ipairs({ Character, Backpack }) do
            for _, Tool in ipairs(Container:GetChildren()) do
                if Tool:IsA("Tool") then
                    Tools[Tool] = Tool.Name
                end
            end
        end

        return PickBest(Tools)
    end

    function LassoManager:HotbarRefresh()
        local Owned = self:GetOwnedLassos()
        local Names = {}

        for Name in pairs(Owned) do
            Names[Name] = Name
        end

        local BestName = PickBest(Names)

        if BestName then
            SetHotbarRemote:InvokeServer("1", BestName)
        end

        return Owned
    end

    function LassoManager:EquipBestLasso()
        local BestLasso = self:GetBestLasso()

        if not BestLasso then
            self:HotbarRefresh()
            task.wait(0.25)
            BestLasso = self:GetBestLasso()
        end

        if not BestLasso then return end
        if BestLasso.Parent ~= Character then
            Humanoid:EquipTool(BestLasso)
        end

        return BestLasso
    end

    return LassoManager
end)()

Module.HorseManager = (function()
    local HorseManager = {}

    local HorsePersonalitiesRemote = RemoteUtils.GetRemoteEvent("HorsePersonalitiesRemote")    
    local EquipAnimalRemote = RemoteUtils.GetRemoteEvent("EquipAnimalRemote")    
    local WorkspaceGui = PlayerGui:WaitForChild('WorkspaceGui', math.huge)

    function HorseManager:EquipHorse()
        return EquipAnimalRemote:InvokeServer("1")
    end

    function HorseManager:IsEquipped()
        return Client.GetTotalEquippedAnimals() ~= 0
    end

    function HorseManager:GetHorse()
        if not Character then return end
        
        local Animals = Character:FindFirstChild('Animals')
        if not Animals then return end
        
        return Animals:FindFirstChildOfClass('Model')
    end

    function HorseManager:GetRideButton(Folder)
        for _, Button in Folder.ContainerFrame.OptionsFrame:GetDescendants() do
            if Button.Name == "ActionHintLabel" and Button:IsA("TextLabel") and Button.Text == "Ride" then
                return Button.Parent
            end
        end
    end

    function HorseManager:RideHorse()
        local Horse = self:GetHorse()
        if not Horse then return end

        Cached.LastHorse = Horse
        
        if Character then
            Character:PivotTo(Horse:GetPivot())
        end

        local PromptName = `Workspace.Characters.{Player.Name}.Animals.{Horse.Name}.RootPart.MiddleBody.UpperBody`
        local MyFolder = WorkspaceGui:FindFirstChild(PromptName, true)
        if not MyFolder then return end

        local RideButton: TextButton = self:GetRideButton(MyFolder)
        if not RideButton then return end

        GuiService.SelectedObject = RideButton
        task.wait()

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end

    return HorseManager
end)()

Module.SellerModule = (function()
    local SellerModule = {}

    local DisplayAnimalClient = require(ReplicatedStorage._replicationFolder.DisplayAnimalClient)
    local Lassos = ShopService.GetItems("Lasso")
    local HorseModule = Module.HorseModule

    function SellerModule:NextInteger()
        local Display = DisplayAnimalClient.GetDisplay()
        if not Display or not Display.Slot then return end

        local Species = Display.Slot.Species.Value

        if not table.find(Settings['Keep Species'], Species) then
            return DisplayAnimalClient.SellSlotOrClose()
        end

        return DisplayAnimalClient.KeepSlotOrClose()
    end

    for Name, Price in Lassos do
        if type(Price) == "number" and Name:find("Lasso") then
            table.insert(HIDDEN_SETTINGS.LASSOS, Name)
        end
    end

    return SellerModule
end)()

Module.PlayerManager = (function()
    local PlayerManager = {}
    
    local LassoManager = Module.LassoManager
    local SellerModule = Module.SellerModule
    
    local NextClick = 0

    function PlayerManager:IsAlive()
        if not Character then return end
        if not Humanoid then return end
        if not PrimaryPart then return end
        if not Backpack then return end
        return (Humanoid and Humanoid.Health > 0) or PrimaryPart ~= nil
    end

    function PlayerManager:Tamer(Horse: Instance)
        local MobData = MobAnimator.getMobFromModel(Horse)
        if not MobData then return end

        local Attribute = Horse:GetAttribute("TamingId")
        if not Attribute then
            MobData:RunAction("BeginAggro")
        else
            MobData:RunAction("SuccessfulFeed")
        end
    end

    function PlayerManager:Taming(Horse: BasePart, Break)
        if not Horse.Parent or not self:IsAlive() then return end

        repeat Heartbeat:Wait()
            Module.SellerModule:NextInteger()
            Character:PivotTo(Horse.CFrame + Vector3.new(0, 5, 0))
            LassoManager:EquipBestLasso()

            if tick() >= NextClick then
                self:Tamer(Horse)
                NextClick = tick() + 0.5
            end
        until (Break and Break()) or not Horse.Parent or not self:IsAlive() or not table.find(Settings['Keep Species'], Horse.Name)
        
        Module.SellerModule:NextInteger()
    end

    Connect(Player.CharacterAdded, function(v)
        Character = v
        Humanoid = v:WaitForChild("Humanoid", math.huge)
        Backpack = Player:FindFirstChildOfClass('Backpack')
        PrimaryPart = v:WaitForChild("HumanoidRootPart", math.huge)
    end)

    return PlayerManager
end)()

local Options = GoodQueue.Build() do
    local PlayerManager = Module.PlayerManager
    local HorseManager = Module.HorseManager
    local HorseModule = Module.HorseModule

    Options:NewOption("Auto Tame", function()
        if not PlayerManager:IsAlive() then return end

        local Closest = HorseModule:GetClosest()
        if not Closest then return end

        if not HorseManager:IsEquipped() then
            return HorseManager:EquipHorse()
        end

        if Humanoid.Sit then
            PlayerManager:Taming(Closest, function()
                return not HorseManager:IsEquipped() or not Settings['Auto Tame'] or not Humanoid.Sit
            end)
            
            return true
        end

        HorseManager:RideHorse()
        return true
    end)
    
    Options:NewOption("Buy Select", function()
        for _, Name in Settings["Select Lasso"] do
            Remotes.PurchaseItemRemote:InvokeServer(Name, 1) 
        end
    end, 1)
    
    Options:NewOption("Buy All", function()
        for _, Name in HIDDEN_SETTINGS.LASSOS do
            Remotes.PurchaseItemRemote:InvokeServer(Name, 1) 
        end
    end, 1)
end

task.spawn(function()
    local Window = Plugins:Window(Options) do
        Plugins:Community()

        local Standard = Plugins:MakeTab({
            Plugins.Add("Standard", "มาตรฐาน"),
            Plugins.Add("Standard farming functions", "ฟังชั่นมาตฐานในการฟาร์ม"),
            127866486547434
        }) do
            Standard:Section("Tamings") do
                Plugins:Default("Keep Species", { "Common" })

                Plugins:Dropdown(Standard, {
                    Plugins.Add("Keep Species", "ยกเว้นสายพันธ์"),
                }, HIDDEN_SETTINGS.SPECIES, "Keep Species")

                Plugins:Toggle(Standard, {
                    Plugins.Add("Auto Tame Horse", "ออโต้จับม้า"),
                    Plugins.Add("Taming the horse automatically, selling when it not in keep species.", "จับม้าโดยอัตโนมัติและขายหากม้าไม่ได้อยู่ในสายพันธ์ที่กำหนด"),
                }, "Auto Tame") 
            end
            
            Standard:Section("Shopings") do
                Plugins:Default("Select Lasso", { HIDDEN_SETTINGS.LASSOS [ 1 ] })

                Plugins:Dropdown(Standard, {
                    Plugins.Add("Select Lasso", "เลือกเชือก"),
                }, HIDDEN_SETTINGS.LASSOS, "Select Lasso")

                Plugins:Toggle(Standard, {
                    Plugins.Add("Buy Select", "ออโต้ซื้อที่เลือก"),
                    Plugins.Add("Automatically buy the selected lassos.", "ซื้อเชือกที่เลือกโดยอัตโนมัติ"),
                }, "Buy Select") 

                Plugins:Toggle(Standard, {
                    Plugins.Add("Buy All", "ออโต้ซื้อทั้งหมด"),
                    Plugins.Add("Automatically buy all lassos in the list.", "ซื้อเชือกทุกชนิดโดยอัตโนมัติ"),
                }, "Buy All") 
            end
        end

        Plugins:Managers()
        Options:RunQueue()
    end
end)
