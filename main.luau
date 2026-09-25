local _ENV = getgenv()

if _ENV.Ox then return nil end
_ENV.Ox = true

local Library = {} do
    Library.GameIds = {
        [ 10563114921 ] = "a33b12c1f51cf2b427e1294dcadc19ef73499eb7e39579b4c9d3426f2a9ebe71"
    }
end

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local ContentProvider = game:GetService('ContentProvider')
local TweenService = game:GetService('TweenService')
local CoreGui = game:GetService('CoreGui')

local CurrentCamera = workspace.CurrentCamera

local Link = "https://api.jnkie.com/api/v1/luascripts/public/%s/download"
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))() do
    Junkie.service = "Novel"
    Junkie.identifier = "1001485"
    Junkie.provider = "Novel Provider"
end

if License then
    local Validation = Junkie.check_key(License)
    
    if Validation and Validation.valid then
        _ENV.SCRIPT_KEY = License
        
        loadstring(
            game:HttpGet(
                Link:format(Library.GameIds[game.GameId])
            )
        )()
        
        return
    end
end

local Mobile = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then true else false

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

function Library:Parent()
    if not RunService:IsStudio() then
        return (gethui and gethui()) or CoreGui
    end

    return PlayerGui
end

function Library:Create(Class, Properties)
    local Creations = Instance.new(Class)

    for Property, Value in Properties do
        Creations[Property] = Value
    end

    return Creations
end

function Library:Draggable(Frame, UIScale)
    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(Input)
        if not Dragging then
            return
        end

        local Delta = Input.Position - DragStart
        local Scale = UIScale and UIScale.Scale or 1

        if Scale <= 0 then
            Scale = 1
        end

        Delta /= Scale

        local Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,

            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )

        Frame.Position = Position
    end

    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1
            and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        Dragging = true
        DragStart = Input.Position
        StartPosition = Frame.Position

        Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end)

    Frame.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            Update(Input)
        end
    end)
end

local AutoScale = {
    Margin = 30,
    Max = 1.65,
    Min = 0.55,
}

function Library:SetAutoScale(Background, UIScale)
    CurrentCamera = workspace.CurrentCamera

    if not CurrentCamera then
        return
    end

    local Viewport = CurrentCamera.ViewportSize

    local WindowSize = Vector2.new(
        Background.Size.X.Offset,
        Background.Size.Y.Offset
    )

    if WindowSize.X <= 0 or WindowSize.Y <= 0 then
        return
    end

    local UsableWidth = math.max(Viewport.X - AutoScale.Margin * 2, 1)
    local UsableHeight = math.max(Viewport.Y - AutoScale.Margin * 2, 1)

    local ScaleX = UsableWidth / WindowSize.X
    local ScaleY = UsableHeight / WindowSize.Y

    local TargetScale = math.min(ScaleX, ScaleY)

    UIScale.Scale = math.clamp(
        TargetScale,
        AutoScale.Min,
        AutoScale.Max
    )
end

function Library:Button(Parent)
    local Click = Instance.new("TextButton")

    Click.Name = "Click"
    Click.Parent = Parent
    Click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Click.BackgroundTransparency = 1
    Click.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Click.BorderSizePixel = 0
    Click.Size = UDim2.new(1, 0, 1, 0)
    Click.Font = Enum.Font.SourceSans
    Click.Text = ""
    Click.TextColor3 = Color3.fromRGB(0, 0, 0)
    Click.TextSize = 14
    Click.ZIndex = Parent.ZIndex + 3

    return Click
end

function Library:Tween(Info)
    return TweenService:Create(
        Info.v,
        TweenInfo.new(
            Info.t,
            Enum.EasingStyle[Info.s],
            Enum.EasingDirection[Info.d]
        ),
        Info.g
    )
end

function Library.Effect(c, p)
    p.ClipsDescendants = true

    local Mouse = LocalPlayer:GetMouse()

    local RelativeX = Mouse.X - c.AbsolutePosition.X
    local RelativeY = Mouse.Y - c.AbsolutePosition.Y

    if RelativeX < 0
        or RelativeY < 0
        or RelativeX > c.AbsoluteSize.X
        or RelativeY > c.AbsoluteSize.Y then
        return
    end

    local ClickButtonCircle = Instance.new("Frame")

    ClickButtonCircle.Parent = p
    ClickButtonCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClickButtonCircle.BackgroundTransparency = 0.95
    ClickButtonCircle.BorderSizePixel = 0
    ClickButtonCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    ClickButtonCircle.Position = UDim2.new(0, RelativeX, 0, RelativeY)
    ClickButtonCircle.Size = UDim2.new(0, 0, 0, 0)
    ClickButtonCircle.ZIndex = p.ZIndex

    local UICorner = Instance.new("UICorner")

    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = ClickButtonCircle

    local TweenInfo = TweenInfo.new(
        2.5,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )

    local ExpandTween = TweenService:Create(
        ClickButtonCircle,
        TweenInfo,
        {
            Size = UDim2.new(
                0,
                c.AbsoluteSize.X * 1.5,
                0,
                c.AbsoluteSize.X * 1.5
            ),

            BackgroundTransparency = 1
        }
    )

    ExpandTween.Completed:Connect(function()
        ClickButtonCircle:Destroy()
    end)

    ExpandTween:Play()
end

function Library:Asset(rbx)
    if typeof(rbx) == "number" then
        return "rbxassetid://" .. rbx
    end

    if typeof(rbx) == "string" and rbx:find("rbxassetid://") then
        return rbx
    end

    return rbx
end

if not RunService:IsStudio() then
    Library.SaveKey = (function()
        local Save = {}

        local FolderName = "Xova shield"
        local FileName = FolderName .. "/key.txt"

        if not isfolder(FolderName) then
            makefolder(FolderName)
        end

        function Save:Save(Key)
            if type(Key) ~= "string" then
                return false
            end

            writefile(FileName, Key)

            return true
        end

        function Save:Load()
            if not isfile(FileName) then
                return nil
            end

            return readfile(FileName)
        end

        function Save:Clear()
            if isfile(FileName) then
                delfile(FileName)
            end
        end

        return Save
    end)()
end

function Library:Window(Callback)
    local Secret = Library:Create("ScreenGui", {
        Name = "Secret",
        Parent = Library:Parent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
    })

    local UIScale = Library:Create("UIScale", {
        Parent = Secret,
        Scale = 1,
    })

    local Background_1 = Library:Create("Frame", {
        Name = "Background",
        Parent = Secret,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(11, 11, 11),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 350, 0, 110),
    })

    Library:Create("UICorner", {
        Parent = Background_1,
    })

    Library:Create("ImageLabel", {
        Name = "Shadow",
        Parent = Background_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 120, 1, 120),
        ZIndex = 0,
        Image = "rbxassetid://8992230677",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(99, 99, 99, 99),
    })

    local Page_1 = Library:Create("Frame", {
        Name = "Page",
        Parent = Background_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })

    Library:Create("UIListLayout", {
        Parent = Page_1,
        Padding = UDim.new(0, 7),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    Library:Create("UIPadding", {
        Parent = Page_1,
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 10),
    })

    local Banner_1 = Library:Create("ImageLabel", {
        Name = "Banner",
        Parent = Page_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 90),
        ClipsDescendants = true,
        Image = "rbxassetid://125411502674016",
        ImageColor3 = Color3.fromRGB(255, 0, 127),
    })

    Library:Create("UICorner", {
        Parent = Banner_1,
        CornerRadius = UDim.new(0, 5),
    })

    Library:Create("UIStroke", {
        Parent = Banner_1,
        Color = Color3.fromRGB(75, 0, 38),
        Thickness = 1,
    })

    local Compo_1 = Library:Create("Frame", {
        Name = "Compo",
        Parent = Banner_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })

    Library:Create("UIListLayout", {
        Parent = Compo_1,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    Library:Create("UIPadding", {
        Parent = Compo_1,
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 75),
    })

    Library:Create("TextLabel", {
        Name = "Title",
        Parent = Compo_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.314893156, 0, 0.333333343, 0),
        Size = UDim2.new(0.629787087, 0, 0, 30),
        FontFace = Font.new(
            "rbxassetid://12187374537",
            Enum.FontWeight.Medium,
            Enum.FontStyle.Normal
        ),
        RichText = true,
        Text = "Novel's official",
        TextColor3 = Color3.fromRGB(255, 0, 127),
        TextSize = 28,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local MainText = Library:Create("TextLabel", {
        Name = "Desc",
        Parent = Compo_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.314893454, 0, 0.666666687, 0),
        Size = UDim2.new(0.629999995, 0, 0, 13),
        FontFace = Font.new(
            "rbxassetid://12187374537",
            Enum.FontWeight.Regular,
            Enum.FontStyle.Normal
        ),
        RichText = true,
        Text = "Built for faster, stable, and ease of use.",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local Input_1 = Library:Create("Frame", {
        Name = "Input",
        Parent = Page_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Visible = false,
    })

    Library:Create("UIListLayout", {
        Parent = Input_1,
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    local Front_1 = Library:Create("Frame", {
        Name = "Front",
        Parent = Input_1,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -40, 1, 0),
    })

    Library:Create("UICorner", {
        Parent = Front_1,
        CornerRadius = UDim.new(0, 2),
    })

    Library:Create("UIStroke", {
        Parent = Front_1,
        Color = Color3.fromRGB(35, 35, 35),
        Thickness = 0.5,
    })

    local TextBox: TextBox = Library:Create("TextBox", {
        Parent = Front_1,
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -20, 1, 0),
        FontFace = Font.new(
            "rbxassetid://12187374537",
            Enum.FontWeight.Regular,
            Enum.FontStyle.Normal
        ),
        PlaceholderColor3 = Color3.fromRGB(55, 55, 55),
        PlaceholderText = "Paste your license key here.",
        Text = "",
        TextColor3 = Color3.fromRGB(140, 140, 140),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
    })

    local Enter_1 = Library:Create("Frame", {
        Name = "Enter",
        Parent = Input_1,
        BackgroundColor3 = Color3.fromRGB(255, 0, 127),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 30, 0, 30),
    })

    Library:Create("UICorner", {
        Parent = Enter_1,
        CornerRadius = UDim.new(0, 3),
    })

    Library:Create("UIGradient", {
        Parent = Enter_1,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 56, 56)),
        },
        Rotation = 90,
    })

    Library:Create("ImageLabel", {
        Parent = Enter_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        Image = "rbxassetid://115960025411300",
    })

    local Link_1 = Library:Create("Frame", {
        Name = "Link",
        Parent = Page_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        Visible = false,
    })

    Library:Create("UIListLayout", {
        Parent = Link_1,
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    local AddLink_1 = Library:Create("Frame", {
        Name = "AddLink",
        Parent = Link_1,
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
    })

    Library:Create("UICorner", {
        Parent = AddLink_1,
        CornerRadius = UDim.new(0, 5),
    })

    Library:Create("UIStroke", {
        Parent = AddLink_1,
        Color = Color3.fromRGB(75, 0, 38),
        Thickness = 1,
    })

    local Banner_2 = Library:Create("ImageLabel", {
        Name = "Banner",
        Parent = AddLink_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://125411502674016",
        ImageColor3 = Color3.fromRGB(255, 0, 128),
        ScaleType = Enum.ScaleType.Crop,
    })

    Library:Create("UICorner", {
        Parent = Banner_2,
        CornerRadius = UDim.new(0, 2),
    })

    local Info_1 = Library:Create("Frame", {
        Name = "Info",
        Parent = AddLink_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })

    Library:Create("UIListLayout", {
        Parent = Info_1,
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    Library:Create("UIPadding", {
        Parent = Info_1,
        PaddingLeft = UDim.new(0, 15),
    })

    Library:Create("ImageLabel", {
        Name = "Icon",
        Parent = Info_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = -1,
        Size = UDim2.new(0, 25, 0, 25),
        Image = "rbxassetid://96551286443180",
        ImageColor3 = Color3.fromRGB(255, 0, 127),
    })

    local Text_1 = Library:Create("Frame", {
        Name = "Text",
        Parent = Info_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.111111209, 0, 0.144444451, 0),
        Size = UDim2.new(0, 185, 0, 32),
    })

    Library:Create("UIListLayout", {
        Parent = Text_1,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    Library:Create("TextLabel", {
        Name = "Title",
        Parent = Text_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 150, 0, 14),
        FontFace = Font.new(
            "rbxassetid://12187374537",
            Enum.FontWeight.Medium,
            Enum.FontStyle.Normal
        ),
        RichText = true,
        Text = "24 Hours",
        TextColor3 = Color3.fromRGB(255, 0, 127),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    Library:Create("TextLabel", {
        Name = "Desc",
        Parent = Text_1,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0.9, 0, 0, 10),
        FontFace = Font.new(
            "rbxassetid://12187374537",
            Enum.FontWeight.Regular,
            Enum.FontStyle.Normal
        ),
        RichText = true,
        Text = "3 checkpoint or buy our license",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        TextTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local Getkey_1 = Library:Create("Frame", {
        Name = "Getkey",
        Parent = Info_1,
        BackgroundColor3 = Color3.fromRGB(255, 0, 127),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.730158806, 0, 0.166666672, 0),
        Size = UDim2.new(0, 75, 0, 25),
    })

    Library:Create("UICorner", {
        Parent = Getkey_1,
        CornerRadius = UDim.new(0, 3),
    })

    Library:Create("UIGradient", {
        Parent = Getkey_1,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 56, 56)),
        },
        Rotation = 90,
    })

    Library:Create("TextLabel", {
        Name = "Title",
        Parent = Getkey_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        FontFace = Font.new(
            "rbxassetid://12187374537",
            Enum.FontWeight.Medium,
            Enum.FontStyle.Normal
        ),
        RichText = true,
        Text = "Access",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
    })

    task.defer(function()
        Library:SetAutoScale(Background_1, UIScale)
    end)

    CurrentCamera = workspace.CurrentCamera

    if CurrentCamera then
        CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Library:SetAutoScale(Background_1, UIScale)
        end)
    end

    task.delay(2.5, function()
        TextBox.TextTruncate = Enum.TextTruncate.AtEnd

        local ExpandSize = Library:Tween({
            v = Background_1,
            t = 0.5,
            s = "Exponential",
            d = "Out",
            g = {
                Size = UDim2.new(0, 350, 0, 200),
            },
        })

        ExpandSize.Completed:Connect(function()
            task.wait(0.1)

            Input_1.Visible = true

            task.wait(0.1)

            Link_1.Visible = true

            Library:SetAutoScale(Background_1, UIScale)
            Library:Draggable(Background_1, UIScale)

            local ClickGetkey: TextButton = Library:Button(Getkey_1)
            local Click: TextButton = Library:Button(Enter_1)

            local function Colors(Text, Color)
                if type(Text) == "string" and typeof(Color) == "Color3" then
                    local R = math.floor(Color.R * 255)
                    local G = math.floor(Color.G * 255)
                    local B = math.floor(Color.B * 255)

                    return string.format(
                        '<font color="rgb(%d, %d, %d)">%s</font>',
                        R,
                        G,
                        B,
                        Text
                    )
                end

                return Text
            end

            local function ValidateAndLaunch(Key)
                if not Key or Key == "" then
                    return
                end

                local Validation = Junkie.check_key(Key)

                if Validation and Validation.valid then
                    Library.SaveKey:Save(Key)

                    Link_1.Visible = false
                    Input_1.Visible = false

                    MainText.Text = "Welcome"

                    local ExpandSize_VALID = Library:Tween({
                        v = Background_1,
                        t = 0.5,
                        s = "Exponential",
                        d = "Out",
                        g = {
                            Size = UDim2.new(0, 350, 0, 110),
                        },
                    })
                    
                    local Link = "https://api.jnkie.com/api/v1/luascripts/public/%s/download"

                    ExpandSize_VALID.Completed:Connect(function()
                        task.delay(2.5, function()
                            Secret:Destroy()
                            
                            if not Library.GameIds[game.GameId] then
                                return LocalPlayer:Kick('Game is not supported.')
                            end

                            loadstring(
                                game:HttpGet(
                                    Link:format(Library.GameIds[game.GameId])
                                )
                            )()
                        end)
                    end)

                    ExpandSize_VALID:Play()
                else
                    Library.SaveKey:Clear()

                    TextBox.Text = Colors(
                        "Invalid license key.",
                        Color3.fromRGB(255, 69, 69)
                    )
                end
            end

            do
                local Key = Library.SaveKey:Load()

                TextBox.Text = Key or ""

                _ENV.SCRIPT_KEY = Key or ""

                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    _ENV.SCRIPT_KEY = TextBox.Text
                end)

                if Key then
                    ValidateAndLaunch(Key)
                end

                Click.MouseButton1Click:Connect(function()
                    task.spawn(
                        Library.Effect,
                        Click,
                        Enter_1
                    )

                    ValidateAndLaunch(_ENV.SCRIPT_KEY)
                end)

                ClickGetkey.MouseButton1Click:Connect(function()
                    task.spawn(
                        Library.Effect,
                        ClickGetkey,
                        Getkey_1
                    )
                    
                    local Old = TextBox.Text
                    
                    TextBox.Text = Colors('Link is copied.', Color3.fromRGB(255, 170, 0))

                    task.delay(1, function()
                        TextBox.Text = Old
                    end)

                    local Link = Junkie.get_key_link()

                    if Link then
                        setclipboard(Link)
                    end
                end)
            end
        end)

        ExpandSize:Play()
    end)
end

Library:Window()

return nil
