local _ENV = (getgenv or getrenv or getfenv)()

local Framework = {}
local Types = {}

local clonefunction = clonefunction or function( ... ) return ... end
local cloneref = cloneref or function( ... ) return ... end

--local Types = require('./Typing')

local Module, Cached = {}, {} do
    Module.Game = cloneref(game)
    Module.Cloner = clonefunction(Module.Game.GetService)

    Module.Service = setmetatable({
        Reference = {}, Inference = {}
    }, {
        __index = function(self, Service)
            local Inference = self.Inference
            local Reference = self.Reference

            if Reference[Service] then
                return Reference[Service]
            elseif Inference[Service] then
                return Inference[Service]
            end

            Inference[Service] = Module.Cloner(Module.Game, Service)
            Reference[Service] = cloneref(Inference[Service])

            return Reference[Service]
        end,
    }):: Types.Service
    
    if _ENV.__NOVEL then _ENV.__NOVEL:Destroy() end
end

local Service = Module.Service

local UserInputService = Service.UserInputService
local TweenService = Service.TweenService
local HttpService = Service.HttpService
local RunService = Service.RunService
local GuiService = Service.GuiService
local Players = Service.Players
local CoreGui = Service.CoreGui

local CurrentCamera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local UserInputState = Enum.UserInputState
local UserInputType = Enum.UserInputType

local EasingDirection = Enum.EasingDirection
local EasingStyle = Enum.EasingStyle

local HorizontalAlignment = Enum.HorizontalAlignment
local VerticalAlignment = Enum.VerticalAlignment
local TextXAlignment = Enum.TextXAlignment
local TextTruncate = Enum.TextTruncate

local UIFlexAlignment = Enum.UIFlexAlignment
local FillDirection = Enum.FillDirection

local ZIndexBehavior = Enum.ZIndexBehavior
local AutomaticSize = Enum.AutomaticSize
local ScreenInsets = Enum.ScreenInsets

local ScaleType = Enum.ScaleType
local SortOrder= Enum.SortOrder

local FontWeight = Enum.FontWeight
local FontStyle = Enum.FontStyle

Module.Theme = Color3.fromRGB(255, 0, 127)

Module.Parent = (function()
    if not RunService:IsStudio() then
        return (gethui and gethui()) or CoreGui
    end

    return PlayerGui
end)()

Module.IsMobile = (function()
    local TouchEnabled = UserInputService.TouchEnabled
    local KeyboardEnabled = UserInputService.KeyboardEnabled

    return TouchEnabled and not KeyboardEnabled and true
end)()

Module.New = function(Class: Types.GuiClass, Properties: { [ string ]: any }): GuiObject
    local Creations = Instance.new(Class)

    for Property, Value in Properties do
        Creations[Property] = Value
    end

    if Class == "Frame" then
        Creations.BorderSizePixel = 0
    end

    return Creations
end

Module.Button = function(Parent: GuiObject): TextButton
    return Module.New('TextButton', {
        Name = "Click",
        Parent = Parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = Parent.ZIndex + 3
    })
end

Module.Tween = function(Object: Instance, Info: Types.TweenInfoData)
    return TweenService:Create(
        Object,
        TweenInfo.new(
            Info.Time,
            EasingStyle[Info.Style],
            EasingDirection[Info.Direction]
        ),
        Info.Goal
    )
end

Module.MultiTweens = function(Object, Tweens)
    for Property, Data in Tweens do
        Module.Tween(Object, {
            Time = Data.Time,
            Style = "Linear",
            Direction = "Out",
            Goal = {
                [ Property ] = Data.Goal,
            },
        }):Play()
    end
end

Module.Asset = function(Id: number | string)
    if type(Id) == 'number' then
        return `rbxassetid://{Id}`
    elseif type(Id) == 'string' and Id:find('rbxassetid://') then
        return Id
    end

    return Id
end

Module.Draggable = setmetatable({
    Enumeration = {
        Began = {
            [UserInputType.MouseButton1] = true,
            [UserInputType.Touch] = true,
        },

        Changed = {
            [UserInputType.MouseMovement] = true,
            [UserInputType.Touch] = true,
        },

        State = {
            [UserInputState.End] = true,
        },
    },

    Acceleration = 0.1,
    States = {},

    Update = function(self, Frame, Input, Scale)
        Scale = Scale or 1

        local State = self.States[Frame]

        if not State then
            return
        end

        local Delta = Input.Position - State.Start

        Delta /= Scale

        local NewPosition = UDim2.new(
            State.Position.X.Scale,
            State.Position.X.Offset + Delta.X,

            State.Position.Y.Scale,
            State.Position.Y.Offset + Delta.Y
        )

        Module.Tween(Frame, {
            Time = self.Acceleration,
            Style = "Linear",
            Direction = "Out",
            Goal = {
                Position = NewPosition,
            },
        }):Play()
    end,
}, {
    __call = function(self, Frame, UIScale)
        local State = self.States[Frame]

        if not State then
            State = {
                IsDragging = false,
                Start = nil,
                Input = nil,
                Position = nil,
            }

            self.States[Frame] = State
        end

        Frame.InputBegan:Connect(function(Input)
            if self.Enumeration.Began[Input.UserInputType] then
                State.IsDragging = true
                State.Start = Input.Position
                State.Position = Frame.Position

                Input.Changed:Connect(function()
                    if self.Enumeration.State[Input.UserInputState] then
                        State.IsDragging = false
                    end
                end)
            end
        end)

        Frame.InputChanged:Connect(function(Input)
            if self.Enumeration.Changed[Input.UserInputType] then
                State.Input = Input
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if Input == State.Input and State.IsDragging then
                self:Update(Frame, Input, UIScale.Scale)
            end
        end)
    end,
})

Module.SetAutoScale = setmetatable({
    Threshold = 0.05,
    Margin = 30,
    Max = 1.65,
    Min = 0.3,
}, {
    __call = function(self, Background, UIScale)
        local Viewport = CurrentCamera.ViewportSize
        local WindowSize = Vector2.new(
            Background.Size.X.Offset,
            Background.Size.Y.Offset
        )

        local UsableWidth  = Viewport.X - (self.Margin * 2)
        local UsableHeight = Viewport.Y - (self.Margin * 2)

        local ScaleX = UsableWidth  / WindowSize.X
        local ScaleY = UsableHeight / WindowSize.Y

        local TargetScale   = math.min(ScaleX, ScaleY)
        local ClampedScale  = math.clamp(TargetScale, self.Min, self.Max)

        local CurrentScale  = UIScale.Scale

        if math.abs(ClampedScale - CurrentScale) > self.Threshold then
            UIScale.Scale = ClampedScale
        end
    end,
})

Module.GoodSignal = (function()
    local Signal = {}
    local Connection = {}

    Connection.__index = Connection
    Signal.__index = Signal

    function Connection:Disconnect()
        if not self.Connected then
            return
        end

        local find = table.find(self.Signal._connections, self)
        if find then
            table.remove(self.Signal._connections, find)
        end

        self.Function = nil
        self.Connected = false
    end

    function Connection:Fire(...)
        if self.Function then
            task.spawn(self.Function, ...)
        end
    end

    function Signal.new()
        return setmetatable({
            _connections = {}
        }, Signal)
    end

    function Signal:Connect(fn)
        local connection = setmetatable({
            Signal = self,
            Function = fn,
            Connected = true
        }, Connection)

        table.insert(self._connections, connection)
        return connection
    end

    function Signal:Fire(...)
        for _, connection in self._connections do
            connection:Fire(...)
        end
    end

    return Signal
end)()

Module.UpdateCanvas = function(Scrolling, UIList, UIScale, Y)
    Y = Y or 10

    Scrolling.CanvasSize = UDim2.fromOffset(0, (UIList.AbsoluteContentSize.Y / UIScale.Scale) + Y)

    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scrolling.CanvasSize = UDim2.fromOffset(0, (UIList.AbsoluteContentSize.Y / UIScale.Scale) + Y)
    end)
end

Module.FontMedium = (function()
    return Font.new(
        "rbxassetid://12187374537",
        FontWeight.Medium,
        FontStyle.Normal
    )
end)()

Module.FontRegular = (function()
    return Font.new(
        "rbxassetid://12187374537",
        FontWeight.Regular,
        FontStyle.Normal
    )
end)()

Module.NewRows = function(Parent, Args)
    local RowModule = {}

    local Title = Args.Title or "N/A"
    local Footer = Args.Footer
    local Icon = Args.Icon
    local IsTab = Args.IsTab

    local Rows = Module.New("Frame", {
        Name = "Rows",
        Parent = Parent,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Size = UDim2.new(1, 0, 0, IsTab and 50 or 40),
        Selectable = false,
    }) do
        Module.New("UICorner", {
            Parent = Rows,
            CornerRadius = UDim.new(0, 3),
        })

        Module.New("UIStroke", {
            Parent = Rows,
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 0.3,
            Transparency = 0.9,
        })

        Module.New("UIShadow", {
            Parent = Rows,
            BlurRadius = UDim.new(0, 7),
            Transparency = 0.7
        }) 
    end

    local Left = Module.New("Frame", {
        Name = "Left",
        Parent = Rows,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Selectable = false,
    }) do
        Module.New("UIListLayout", {
            Parent = Left,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })

        Module.New("UIPadding", {
            Parent = Left,
            PaddingLeft = UDim.new(0, 2),
        })

        if Icon then
            Module.New("Frame", {
                Name = "Divider",
                Parent = Left,
                BackgroundTransparency = 0.9,
                LayoutOrder = -2,
                Size = UDim2.new(0, 1, 1, -14),
                Selectable = false,
            })
        end
    end

    local TextHandler = Module.New("Frame", {
        Name = "TextHandler",
        Parent = Left,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Selectable = false,
    }) do
        Module.New("UIListLayout", {
            Parent = TextHandler,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })

        Module.New("UIPadding", {
            Parent = TextHandler,
            PaddingLeft = UDim.new(0, 10),
        })

        RowModule.Title = Module.New("TextLabel", {
            Name = "Title",
            Parent = TextHandler,
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            Selectable = false,
            FontFace = Module.FontMedium,
            Text = Title,
            TextColor3 = Color3.fromRGB(234, 234, 234),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }) do
            Module.New("UIGradient", {
                Parent = RowModule.Title,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 129, 129)),
                }),
                Offset = Vector2.new(0, 0.4),
                Rotation = 90,
            })
        end

        if Footer then
            RowModule.Footer = Module.New("TextLabel", {
                Name = "Footer",
                Parent = TextHandler,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0),
                Selectable = false,
                FontFace = Module.FontRegular,
                Text = tostring(Footer),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 10,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
        end
    end

    if Icon then
        local IconHandler = Module.New("Frame", {
            Name = "IconHandler",
            Parent = Left,
            BackgroundTransparency = 1,
            LayoutOrder = -3,
            Size = IsTab and UDim2.fromOffset(50, 50) or UDim2.fromOffset(40, 40),
            Selectable = false,
        }) do
            RowModule.Icon = Module.New("ImageLabel", {
                Name = "IconAsset",
                Parent = IconHandler,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = IsTab and UDim2.fromOffset(25, 25) or UDim2.fromOffset(20, 20),
                Image = Module.Asset(Icon),
                ImageColor3 = Module.Theme,
            }) do
                Module.New("UIGradient", {
                    Parent = RowModule.Icon,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 129, 129)),
                    }),
                    Rotation = 90,
                })
            end
        end
    end

    local Right = Module.New("Frame", {
        Name = "Right",
        Parent = Rows,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Selectable = false,
    }) do
        Module.New("UIListLayout", {
            Parent = Right,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })

        Module.New("UIPadding", {
            Parent = Right,
        })
    end

    RowModule.Row = Rows
    RowModule.Left = Left
    RowModule.Right = Right

    function RowModule:Padding(Side, Paddings)
        local Padding = Rows[Side]:FindFirstChildOfClass("UIPadding")
        if not Padding then return end

        for Index, Value in Paddings do
            Padding[Index] = UDim.new(0, Value)
        end
    end

    function RowModule:Layout(Side, Value)
        local Layout = Rows[Side]:FindFirstChildOfClass("UIListLayout")
        if not Layout then return end

        Layout.Padding = UDim.new(0, Value)
    end

    return RowModule
end

function Module:Window(Args)
    local Window = {} do
        Window.IsOpen = true
        Window.OpenSize = UDim2.fromOffset(500, 360)
        Window.CloseSize = UDim2.fromOffset(200, 50)
    end

    local Signal = Module.GoodSignal.new()

    local Title = Args.Title or "Novel's official"
    local Footer = Args.Footer or "Made by vita8it"

    function Window:IsDropdownOpen()
        if not Window.Background then return end

        local Dropdowns = {
            "NewDropdown", "NewDialog", "WindowTools"
        }

        for _, v in Window.Background:GetChildren() do
            if table.find(Dropdowns, v.Name) and v.Visible then
                return true
            end
        end
    end

    function Window:NewModule(Name, Function)
        return Function and Function(Name)
    end

    Window:NewModule("@Window", function()
        local Novel = Module.New("ScreenGui", {
            Name = "Novel",
            Parent = Module.Parent,
            IgnoreGuiInset = true
        })
        
        _ENV.__NOVEL = Novel

        local UIScale = Module.New("UIScale", {
            Parent = Novel,
        }) do
            Window.UIScale = UIScale
        end

        local Background = Module.New("Frame", {
            Name = "Background",
            Parent = Novel,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = Window.OpenSize,
            Selectable = false,
        }) do
            Module.New("UICorner", {
                CornerRadius = UDim.new(0, 10),
                Parent = Background,
            })

            Module.New("UIShadow", {
                Parent = Background,
                BlurRadius = UDim.new(0, 20),
                Transparency = 0.5
            }) 

            Background:GetPropertyChangedSignal('Position'):Connect(function()
                if not Window.IsOpen then
                    Cached.TogglePosition = Background.Position
                end
            end)

            CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                Module.SetAutoScale(Background, UIScale)
            end)

            Module.SetAutoScale(Background, UIScale)
        end

        local Header = Module.New("Frame", {
            Name = "Header",
            Parent = Background,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 50),
            Selectable = false,
        })

        local Left = Module.New("Frame", {
            Name = "Left",
            Parent = Header,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
        }) do
            Module.New("UIListLayout", {
                Parent = Left,
                FillDirection = FillDirection.Horizontal,
                SortOrder = SortOrder.LayoutOrder,
                VerticalAlignment = VerticalAlignment.Center,
            }) 
        end

        local TextHandler = Module.New("Frame", {
            Name = "TextHandler",
            Parent = Left,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
        }) do
            Module.New("UIListLayout", {
                Parent = TextHandler,
                SortOrder = SortOrder.LayoutOrder,
                VerticalAlignment = VerticalAlignment.Center,
            })

            Module.New("UIPadding", {
                Parent = TextHandler,
                PaddingLeft = UDim.new(0, 20),
            }) 
        end

        local Title = Module.New("TextLabel", {
            Name = "Title",
            Parent = TextHandler,
            AutomaticSize = AutomaticSize.XY,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            Selectable = false,
            FontFace = Module.FontMedium,
            Text = Title,
            TextColor3 = Module.Theme,
            TextSize = 14,
            TextXAlignment = TextXAlignment.Left,
        }) do
            Module.New("UIGradient", {
                Parent = Title,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 129, 129)),
                }),
                Offset = Vector2.new(0, 0.4),
                Rotation = 90,
            })

            Module.New("TextLabel", {
                Name = "Footer",
                Parent = TextHandler,
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0),
                Selectable = false,
                FontFace = Module.FontRegular,
                Text = Footer,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 11,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
            }) 
        end

        local Right = Module.New("Frame", {
            Name = "Right",
            Parent = Header,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
        }) do
            Module.New("UIListLayout", {
                Parent = Right,
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            })
        end

        local Return = Module.New("Frame", {
            Name = "Return",
            Parent = Right,
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            LayoutOrder = -5,
            Size = UDim2.fromOffset(50, 50),
            Selectable = false,
            Visible = false,
        }) do
            Module.New("ImageLabel", {
                Name = "Icon",
                Parent = Return,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                Image = "rbxassetid://130391877219356",
                ImageColor3 = Color3.fromRGB(234, 234, 234),
                ImageContent = Content.fromUri("rbxassetid://130391877219356"),
            }) 
        end

        local Close = Module.New("Frame", {
            Name = "Close",
            Parent = Right,
            BackgroundColor3 = Module.Theme,
            Size = UDim2.fromOffset(50, 50),
            Selectable = false,
        }) do
            Module.New("UICorner", {
                Parent = Close,
                TopRightRadius = UDim.new(0, 10),
                BottomRightRadius = UDim.new(0, 0),
                TopLeftRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
            })

            Module.New("UIGradient", {
                Parent = Close,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
                }),
                Rotation = 145,
            })

            Module.New("ImageLabel", {
                Name = "Icon",
                Parent = Close,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                Image = "rbxassetid://115960025411300",
                ImageColor3 = Color3.fromRGB(18, 18, 18),
                ImageContent = Content.fromUri("rbxassetid://115960025411300"),
            }) 
        end

        function Window:SetScale(Number)
            UIScale.Scale = Number
        end

        Window.Background = Background

        Module.Button(Return).MouseButton1Click:Connect(function()
            if Window:IsDropdownOpen() then return end

            if Window.PageLayout and Window.Homes then
                Window.PageLayout:JumpTo(Window.Homes)

                Return.Visible = false
            end
        end)

        Signal:Connect(function(Type, Value)
            if Type == 'SetReturnVisible' then
                Return.Visible = Value
            end
        end)

        Module.Button(Close).MouseButton1Click:Connect(function()
            Window.IsOpen = not Window.IsOpen

            if Window.IsOpen then
                local TargetPosition = UDim2.new(0.5, 0, 0.5, 0)

                local CurrentPosition = Background.Position

                local DeltaX = CurrentPosition.X.Scale - TargetPosition.X.Scale
                local DeltaXOffset = CurrentPosition.X.Offset - TargetPosition.X.Offset
                local DeltaY = CurrentPosition.Y.Scale - TargetPosition.Y.Scale
                local DeltaYOffset = CurrentPosition.Y.Offset - TargetPosition.Y.Offset

                local Distance = math.sqrt(
                    (DeltaX * Background.Parent.AbsoluteSize.X + DeltaXOffset) ^ 2
                        + (DeltaY * Background.Parent.AbsoluteSize.Y + DeltaYOffset) ^ 2
                )

                if Distance <= 2 then
                    Background.Position = TargetPosition
                else
                    local MiddleTime = math.clamp(Distance / 1000, 0.05, 0.3)

                    local MiddleTween = Module.Tween(Background, {
                        Style = "Exponential",
                        Direction = "Out",
                        Time = MiddleTime,
                        Goal = {
                            Position = TargetPosition,
                        },
                    })

                    MiddleTween:Play()
                    MiddleTween.Completed:Wait()
                end

                local XTween = Module.Tween(Background, {
                    Style = "Exponential",
                    Direction = "Out",
                    Time = 0.3,
                    Goal = {
                        Size = UDim2.fromOffset(500, 50),
                    },
                })

                XTween.Completed:Once(function()
                    if Window.PageLayout and Window.PageLayout.CurrentPage ~= Window.Homes then
                        Return.Visible = true
                    end

                    Close.UICorner.BottomRightRadius = UDim.new(0, 0)

                    local OpenTween = Module.Tween(Background, {
                        Style = "Exponential",
                        Direction = "Out",
                        Time = 0.15,
                        Goal = {
                            Size = Window.OpenSize,
                        },
                    })

                    OpenTween.Completed:Once(function()
                        if Window.Main then
                            Window.Main.Visible = true
                        end
                    end)

                    OpenTween:Play()
                end)

                XTween:Play()
            else
                if Window.Main then
                    Window.Main.Visible = false
                end

                local YTween = Module.Tween(Background, {
                    Style = "Exponential",
                    Direction = "Out",
                    Time = 0.3,
                    Goal = {
                        Size = UDim2.fromOffset(500, 50),
                    },
                })

                YTween.Completed:Once(function()
                    Return.Visible = false
                    Close.UICorner.BottomRightRadius = UDim.new(0, 10)

                    local X = Module.Tween(Background, {
                        Style = "Exponential",
                        Direction = "Out",
                        Time = 0.15,
                        Goal = {
                            Size = Window.CloseSize,
                        },
                    })

                    X.Completed:Connect(function()
                        task.delay(0.15, function()
                            Module.Tween(Background, {
                                Style = "Exponential",
                                Direction = "Out",
                                Time = 0.3,
                                Goal = {
                                    Position = Cached.TogglePosition
                                        or UDim2.new(0.5, 0, 0.5, 0),
                                },
                            }):Play()
                        end)
                    end)

                    X:Play()
                end)

                YTween:Play()
            end
        end)

        Module.Draggable(Background, UIScale)
    end)

    Window:NewModule("@Main", function()
        local Main = Module.New("Frame", {
            Name = "Main",
            Parent = Window.Background,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
        }) do
            Module.New("UIPadding", {
                Parent = Main,
                PaddingTop = UDim.new(0, 50),
            })

            Module.New("Frame", {
                Name = "Line",
                Parent = Main,
                BackgroundColor3 = Color3.fromRGB(22, 22, 22),
                Size = UDim2.new(1, 0, 0, 1),
                Selectable = false,
            })
        end

        local Inner = Module.New("Frame", {
            Name = "Inner",
            Parent = Main,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
            ClipsDescendants = true,
        })

        local PageLayout: UIPageLayout = Module.New("UIPageLayout", {
            Parent = Inner,
            EasingStyle = Enum.EasingStyle.Exponential,
            TweenTime = 0.45,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            GamepadInputEnabled = false,
            ScrollWheelInputEnabled = false,
            TouchInputEnabled = false,
        })

        local Homes = Module.New("Frame", {
            Name = "Homes",
            Parent = Inner,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
        })

        local Scrolling = Module.New("ScrollingFrame", {
            Name = "Scrolling",
            Parent = Homes,
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(1, 0, 1, -5),
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
        }) do
            Module.New("UIPadding", {
                Parent = Scrolling,
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
            })

            Module.New("UICorner", {
                Parent = Scrolling,
            })

            Module.New("UIListLayout", {
                Parent = Scrolling,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            })

        end

        Window.PageLayout = PageLayout
        Window.TabScrolling = Scrolling

        Module.UpdateCanvas(Scrolling, Scrolling.UIListLayout, Window.UIScale)

        Window.Main = Main
        Window.Homes = Homes
    end)

    function Window:MakeTab(Args)
        local TabModule = {}

        local Title = Args.Title or "Unknow"
        local Footer = Args.Footer or "Description"
        local Icon = Args.Icon or 80212074789397

        local Row = Module.NewRows(Window.TabScrolling, {
            Title = Title,
            Footer = Footer,
            Icon = Icon,
            IsTab = true
        })

        local NewPage = Module.New("Frame", {
            Name = "NewPage",
            Parent = Window.PageLayout.Parent,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Selectable = false,
        })

        local Scrolling = Module.New("ScrollingFrame", {
            Name = "Scrolling",
            Parent = NewPage,
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(1, 0, 1, -5),
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
        }) do
            Module.New("UIListLayout", {
                Parent = Scrolling,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            })

            Module.New("UIPadding", {
                Parent = Scrolling,
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 7),
            })

            Module.UpdateCanvas(Scrolling, Scrolling.UIListLayout, Window.UIScale)
        end

        local Tab = Module.New("Frame", {
            Name = "Return",
            Parent = Row.Right,
            BackgroundColor3 = Module.Theme,
            Size = UDim2.fromOffset(50, 50),
            Selectable = false,
        }) do
            Module.New("UICorner", {
                Parent = Tab,
                TopRightRadius = UDim.new(0, 3),
                BottomRightRadius = UDim.new(0, 3),
                TopLeftRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
            })

            Module.New("UIGradient", {
                Parent = Tab,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
                }),
                Rotation = 100,
            })

            Module.New("ImageLabel", {
                Name = "Icon",
                Parent = Tab,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(17, 17),
                Image = "rbxassetid://140511873578528",
                ImageColor3 = Color3.fromRGB(18, 18, 18),
                ImageContent = Content.fromUri("rbxassetid://140511873578528"),
            })

            Module.Button(Tab).MouseButton1Click:Connect(function()
                Signal:Fire('SetReturnVisible', true)
                Window.PageLayout:JumpTo(NewPage)
            end)
        end

        function TabModule:Space(Offset)
            return Module.New("Frame", {
                Name = "Space",
                Parent = Scrolling,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, Offset or 1),
                Selectable = false,
            })
        end

        function TabModule:Section(Text)
            local NewSection = Module.New("Frame", {
                Name = "NewSection",
                Parent = Scrolling,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 13),
                Selectable = false,
            }) do
                Module.New("UIPadding", {
                    Parent = NewSection,
                    PaddingLeft = UDim.new(0, 3),
                })
            end

            local Title = Module.New("TextLabel", {
                Name = "Title",
                Parent = NewSection,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0),
                Selectable = false,
                FontFace = Module.FontMedium,
                Text = Text,
                TextColor3 = Color3.fromRGB(234, 234, 234),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }) do
                Module.New("UIGradient", {
                    Parent = Title,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 129, 129)),
                    }),
                    Offset = Vector2.new(0, 0.4),
                    Rotation = 90,
                })
            end

            return Title
        end

        function TabModule:TextLabel(Args)
            local LabelModule = {}

            local Title = Args.Title or "Unknow"
            local Footer = Args.Footer or nil
            local Icon = Args.Icon or nil
            local Text = Args.Text or nil

            local Row = Module.NewRows(Scrolling, {
                Title = Title,
                Footer = Footer,
                Icon = Icon,
            })

            Row:Padding("Right", {
                PaddingRight = 15
            })

            local Texts = Module.New("TextLabel", {
                Name = "Text",
                Parent = Row.Right,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0),
                Selectable = false,
                FontFace = Module.FontRegular,
                RichText = true,
                Visible = Text and true or false,
                Text = tostring(Text),
                TextColor3 = Color3.fromRGB(125, 125, 125),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            function LabelModule:SetTitle(Texter)
                Row.Title = tostring(Texter)
            end

            function LabelModule:SetDesc(Texter)
                Row.Footer = tostring(Texter)
            end

            function LabelModule:SetText(Texter)
                Texts.Text = tostring(Texter)
            end

            return LabelModule
        end

        function TabModule:Button(Args)
            local ButtonModule = {}

            local Title = Args.Title or "Unknow"
            local Footer = Args.Footer or nil
            local Icon = Args.Icon or nil
            local ButtonIcon = Args.ButtonIcon or 90321109827651
            local Callback = Args.Callback or function() end

            local Row = Module.NewRows(Scrolling, {
                Title = Title,
                Footer = Footer,
                Icon = Icon,
            })

            local Button = Module.New("Frame", {
                Name = "Return",
                Parent = Row.Right,
                BackgroundColor3 = Module.Theme,
                Size = UDim2.fromOffset(40, 40),
                Selectable = false,
            }) do
                Module.New("UICorner", {
                    Parent = Button,
                    TopRightRadius = UDim.new(0, 3),
                    BottomRightRadius = UDim.new(0, 3),
                    TopLeftRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 0),
                })

                Module.New("UIGradient", {
                    Parent = Button,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
                    }),
                    Rotation = 100,
                })

                Module.New("ImageLabel", {
                    Name = "Icon",
                    Parent = Button,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(17, 17),
                    Image = Module.Asset(ButtonIcon),
                    ImageColor3 = Color3.fromRGB(18, 18, 18),
                })

                local ClickColor = Module.Theme:Lerp(Color3.new(1, 1, 1), 0.5)

                Module.Button(Button).MouseButton1Click:Connect(function()
                    if Window:IsDropdownOpen() then return end

                    Module.Tween(Button, {
                        Style = 'Exponential',
                        Time = 0.125,
                        Direction = 'Out',
                        Goal = {
                            BackgroundColor3 = ClickColor
                        }
                    }):Play()

                    task.delay(0.1, function()
                        Module.Tween(Button, {
                            Style = 'Exponential',
                            Time = 0.125,
                            Direction = 'Out',
                            Goal = {
                                BackgroundColor3 = Module.Theme
                            }
                        }):Play()
                    end)

                    task.spawn(Callback)
                end)
            end

            return ButtonModule
        end

        function TabModule:Toggle(Args)
            local ToggleModule = {}

            local Title = Args.Title or "Unknow"
            local Footer = Args.Footer or nil
            local Icon = Args.Icon or nil
            local Value = Args.Value or false
            local Callback = Args.Callback or function() end

            local Row = Module.NewRows(Scrolling, {
                Title = Title,
                Footer = Footer,
                Icon = Icon,
            })

            Row:Padding("Right", {
                PaddingRight = 15
            })

            local Background = Module.New("Frame", {
                Name = "Background",
                Parent = Row.Right,
                BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                Size = UDim2.fromOffset(20, 20),
                Selectable = false,
            }) do
                Module.New("UICorner", {
                    Parent = Background,
                    CornerRadius = UDim.new(0, 3),
                })

                Module.New("UIStroke", {
                    Parent = Background,
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 0.3,
                    Transparency = 0.9,
                    BorderStrokePosition = Enum.BorderStrokePosition.Inner
                })
            end


            local UIShadow = Module.New("UIShadow", {
                Parent = Background,
                BlurRadius = UDim.new(0, 5),
                Transparency = 0.75
            })

            local Enabled = Module.New("Frame", {
                Name = "Enabled",
                Parent = Background,
                BackgroundTransparency = Value and 0 or 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Module.Theme,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Selectable = false,
            }) do
                Module.New("UICorner", {
                    Parent = Enabled,
                    CornerRadius = UDim.new(0, 3),
                })
            end

            local IconAsset = Module.New("ImageLabel", {
                Name = "IconAsset",
                Parent = Enabled,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.45, 0.45),
                Image = "rbxassetid://99035215947422",
                ImageColor3 = Color3.fromRGB(18, 18, 18),
                ImageTransparency = Value and 0 or 1,
                ImageContent = Content.fromUri("rbxassetid://99035215947422"),
            })

            Module.New("UIGradient", {
                Parent = Enabled,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
                }),
                Offset = Vector2.new(0, 0.1),
                Rotation = 90,
            })

            local function OnChanged(Value)
                Module.Tween(Enabled, {
                    Time = 0.15,
                    Style = 'Linear',
                    Direction = 'Out',
                    Goal = {
                        BackgroundTransparency = Value and 0 or 1
                    }
                }):Play()

                Module.Tween(IconAsset, {
                    Time = 0.15,
                    Style = 'Linear',
                    Direction = 'Out',
                    Goal = {
                        ImageTransparency = Value and 0 or 1
                    }
                }):Play()

                task.spawn(pcall, Callback, Value)
            end

            function ToggleModule:SetValue(Value)
                Value = Value
                OnChanged(Value)
            end

            Module.Button(Row.Row).MouseButton1Click:Connect(function()
                if Window:IsDropdownOpen() then return end

                Value = not Value
                OnChanged(Value)
            end)

            OnChanged(Value)

            return ToggleModule
        end

        function TabModule:Slider(Args)
            local SliderModule = {}

            local Title = Args.Title or "Unknow"
            local Footer = Args.Footer or nil
            local Icon = Args.Icon or nil
            local Min = Args.Min or 1
            local Max = Args.Max or 10
            local Value = Args.Value or Min
            local Rounding = Args.Rounding or 0
            local Callback = Args.Callback or function() end

            local Row = Module.NewRows(Scrolling, {
                Title = Title,
                Footer = Footer,
                Icon = Icon,
            })

            Row:Padding("Right", {
                PaddingRight = 12
            })

            Row:Layout("Right", 5)

            local Slidable = Module.New("Frame", {
                Name = "Slidable",
                Parent = Row.Right,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(0, 120, 1, 0),
                Selectable = false,
            })

            local Background = Module.New("Frame", {
                Name = "Background",
                Parent = Slidable,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(45, 45, 45),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, -10, 0, 5),
                Selectable = false,
            }) do
                Module.New("UICorner", {
                    Parent = Background,
                    CornerRadius = UDim.new(1, 0),
                })

                Module.New("UIShadow", {
                    Parent = Background,
                    BlurRadius = UDim.new(0, 5),
                    Transparency = 0.75
                })
            end

            local Color = Module.New("Frame", {
                Name = "Color",
                Parent = Background,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Module.Theme,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(0.5, 0, 1, 0),
                Selectable = false,
            }) do
                Module.New("UICorner", {
                    Parent = Color,
                    CornerRadius = UDim.new(1, 0),
                })

                Module.New("UIGradient", {
                    Parent = Color,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
                    }),
                    Rotation = 90,
                })
            end

            local Circle = Module.New("Frame", {
                Name = "Circle",
                Parent = Color,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.fromOffset(10, 10),
                Selectable = false,
            }) do
                Module.New("UICorner", {
                    Parent = Circle,
                    CornerRadius = UDim.new(0, 3),
                })
            end

            local TextBox = Module.New("TextBox", {
                Name = "Value",
                Parent = Row.Right,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 30),
                FontFace = Module.FontMedium,
                PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
                Text = tostring(Value),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 10,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local Dragging = false
            local Slide = Module.Button(Slidable)

            local function Round(n, decimals)
                local factor = 10 ^ decimals
                return math.floor(n * factor + 0.5) / factor
            end

            local function Update(Value)
                Value = tonumber(Value) or Value

                Value = math.clamp(Value, Min, Max)
                Value = Round(Value, Rounding)

                Value = Value

                local Ratio = Max == Min and 0 or (Value - Min) / (Max - Min)

                Module.Tween(Color, {
                    Time = 0.1,
                    Style = "Linear",
                    Direction = "Out",
                    Goal = {
                        Size = UDim2.new(math.max(Ratio, 0.05), 0, 1, 0)
                    }
                }):Play()

                TextBox.Text = tostring(Value)
                task.spawn(pcall, Callback, Value)

                return Value
            end

            local function InputValue(Input)
                local AbsX = Background.AbsolutePosition.X
                local AbsW = Background.AbsoluteSize.X

                local Ratio = math.clamp(
                    (Input.Position.X - AbsX) / AbsW,
                    0, 1
                )

                return Ratio * (Max - Min) + Min
            end

            Slide.InputBegan:Connect(function(Input)
                if Window:IsDropdownOpen() then return end

                if Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch then

                    Dragging = true
                    Update(InputValue(Input))
                end
            end)

            Slide.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch then

                    Dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(Input)
                if not Dragging then return end
                if Window:IsDropdownOpen() then return end

                if Input.UserInputType == Enum.UserInputType.MouseMovement
                    or Input.UserInputType == Enum.UserInputType.Touch then

                    Update(InputValue(Input))
                end
            end)

            TextBox.FocusLost:Connect(function()
                local Value = tonumber(TextBox.Text)

                if Value then
                    Update(Value)
                else
                    TextBox.Text = tostring(Value)
                end
            end)

            function SliderModule:SetValue(Value)
                Update(Value)
            end

            Update(Value, false)

            return SliderModule
        end

        function TabModule:Textbox(Args)
            local TextboxModule = {}

            local Title = Args.Title or "Unknow"
            local Footer = Args.Footer
            local Icon = Args.Icon
            local Value = Args.Value or "None"
            local Callback = Args.Callback or function() end

            local Row = Module.NewRows(Scrolling, {
                Title = Title,
                Footer = Footer,
                Icon = Icon,
            })

            Row:Padding("Right", {
                PaddingRight = 12,
            })

            local Textbox = Module.New("Frame", {
                Name = "Value",
                Parent = Row.Right,
                BackgroundColor3 = Color3.fromRGB(17, 17, 17),
                Size = UDim2.fromOffset(100, 20),
                Selectable = false,
            }) do
                Module.New("UIShadow", {
                    Parent = Textbox,
                    BlurRadius = UDim.new(0, 5),
                    Transparency = 0.75,
                })

                Module.New("UICorner", {
                    Parent = Textbox,
                    CornerRadius = UDim.new(0, 3),
                })

                Module.New("UIStroke", {
                    Parent = Textbox,
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 0.3,
                    Transparency = 0.85,
                })

                Module.New("TextBox", {
                    Name = "TextBox",
                    Parent = Textbox,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.new(1, -20, 1, 0),
                    FontFace = Module.FontRegular,
                    PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
                    PlaceholderText = "Empty",
                    Text = tostring(Value),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 11,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
            end

            local Target = Textbox.TextBox

            Target.FocusLost:Connect(function()
                Value = Target.Text
                Callback(Value)
            end)
            
            task.spawn(pcall, Callback, Value)

            TextboxModule.Row = Row.Row
            TextboxModule.Textbox = Textbox
            TextboxModule.TextBox = Target

            return TextboxModule
        end

        function TabModule:Dropdown(Args)
            local DropdownModule = {}

            local Title = Args.Title or "Unknown"
            local Footer = Args.Footer
            local Icon = Args.Icon
            local List = Args.List or { "None" }
            local Value = Args.Value or List[1]
            local Multi = typeof(Value) == "table"
            local OnRefresh = Args.OnRefresh or nil
            local OnCleared = Args.OnCleared or nil
            local Callback = Args.Callback or function() end

            local IsShowing = false
            local SelectedValues = {}
            local SelectedOrder = 0

            local function IsValueInTable(Val, Table)
                if type(Table) ~= "table" then
                    return false
                end

                for _, v in ipairs(Table) do
                    if v == Val then
                        return true
                    end
                end

                return false
            end

            local function GetText()
                if Multi then
                    if type(Value) ~= "table" or #Value == 0 then
                        return "None"
                    end

                    return table.concat(Value, ", ")
                end

                if Value == nil or Value == "" then
                    return "None"
                end

                return tostring(Value)
            end

            local Row = Module.NewRows(Scrolling, {
                Title = Title,
                Footer = Footer or GetText(),
                Icon = Icon,
            })

            local Dropdown = Module.New("ImageLabel", {
                Name = "Dropdown",
                Parent = Row.Right,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(15, 15),
                Image = "rbxassetid://132291592681506",
                ImageContent = Content.fromUri("rbxassetid://132291592681506"),
                ImageTransparency = 0.5,
            })

            Row:Padding("Right", {
                PaddingRight = 12,
            })

            local NewDropdown = Module.New("Frame", {
                Name = "NewDropdown",
                Parent = Window.Background,
                AnchorPoint = Vector2.new(1, 1),
                BackgroundColor3 = Color3.fromRGB(22, 22, 22),
                Position = UDim2.fromScale(1, 1),
                Size = UDim2.new(0, 0, 1, 0),
                Visible = false,
                Selectable = false,
            }) do
                Module.New("UIShadow", {
                    Parent = NewDropdown,
                    BlurRadius = UDim.new(0, 20),
                    Offset = UDim2.new(0, -25, 0, 0),
                    Spread = UDim2.new(0, -55, 0, -13),
                    Transparency = 0.5
                }) 

                Module.New("UICorner", {
                    Parent = NewDropdown,
                    TopRightRadius = UDim.new(0, 10),
                    BottomRightRadius = UDim.new(0, 10),
                    TopLeftRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 0)
                })

                Module.New("Frame", {
                    Name = "LineOut",
                    Parent = NewDropdown,
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                    Size = UDim2.new(0, 1, 1, 0),
                    Selectable = false,
                })

                Module.New("Frame", {
                    Name = "LineIn",
                    Parent = NewDropdown,
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    Size = UDim2.new(0, 1, 1, 0),
                    Selectable = false,
                })

                local Inner = Module.New("Frame", {
                    Name = "Inner",
                    Parent = NewDropdown,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Selectable = false,
                }) do
                    Module.New("UIListLayout", {
                        Parent = Inner,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    })

                    local Header = Module.New("Frame", {
                        Name = "Header",
                        Parent = Inner,
                        BackgroundTransparency = 1,
                        LayoutOrder = -5,
                        Size = UDim2.new(1, 0, 0, 50),
                        Selectable = false,
                    }) do
                        local Left = Module.New("Frame", {
                            Name = "Left",
                            Parent = Header,
                            BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1),
                            Selectable = false,
                        }) do
                            Module.New("UIListLayout", {
                                Parent = Left,
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            })

                            Module.New("UIPadding", {
                                Parent = Left,
                                PaddingLeft = UDim.new(0, 5),
                            })

                            local TextHandler = Module.New("Frame", {
                                Name = "TextHandler",
                                Parent = Left,
                                BackgroundTransparency = 1,
                                Size = UDim2.fromScale(1, 1),
                                Selectable = false,
                            }) do
                                Module.New("UIListLayout", {
                                    Parent = TextHandler,
                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                    VerticalAlignment = Enum.VerticalAlignment.Center,
                                })

                                Module.New("UIPadding", {
                                    Parent = TextHandler,
                                    PaddingLeft = UDim.new(0, 10),
                                })

                                local TitleLabel = Module.New("TextLabel", {
                                    Name = "Title",
                                    Parent = TextHandler,
                                    AutomaticSize = Enum.AutomaticSize.XY,
                                    BackgroundTransparency = 1,
                                    Size = UDim2.fromOffset(0, 0),
                                    Selectable = false,
                                    FontFace = Module.FontMedium,
                                    Text = Title,
                                    TextColor3 = Color3.fromRGB(234, 234, 234),
                                    TextSize = 13,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                }) do
                                    Module.New("UIGradient", {
                                        Parent = TitleLabel,
                                        Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 129, 129)),
                                        }),
                                        Offset = Vector2.new(0, 0.4),
                                        Rotation = 90,
                                    })
                                end

                                local FooterLabel = Module.New("TextLabel", {
                                    Name = "Footer",
                                    Parent = TextHandler,
                                    AutomaticSize = Enum.AutomaticSize.Y,
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(0, 120, 0, 0),
                                    Selectable = false,
                                    FontFace = Module.FontRegular,
                                    Text = GetText(),
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = 10,
                                    TextTransparency = 0.5,
                                    TextTruncate = Enum.TextTruncate.AtEnd,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                })

                                function DropdownModule:UpdateFooter()
                                    local Text = GetText()

                                    FooterLabel.Text = Text

                                    if Row.Footer then
                                        Row.Footer.Text = Text
                                    end
                                end
                            end
                        end

                        local Right = Module.New("Frame", {
                            Name = "Right",
                            Parent = Header,
                            BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1),
                            Selectable = false,
                        }) do
                            Module.New("UIListLayout", {
                                Parent = Right,
                                Padding = UDim.new(0, 5),
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            })

                            Module.New("UIPadding", {
                                Parent = Right,
                                PaddingRight = UDim.new(0, 12),
                            })

                            local Clear = Module.New("Frame", {
                                Name = "Clear",
                                Parent = Right,
                                Visible = Multi and true or false,
                                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                                Size = UDim2.fromOffset(25, 25),
                                Selectable = false,
                            }) do
                                Module.New("UIShadow", {
                                    Parent = Clear,
                                    BlurRadius = UDim.new(0, 5),
                                    Transparency = 0.7
                                }) 

                                Module.New("UICorner", {
                                    Parent = Clear,
                                    CornerRadius = UDim.new(0, 3),
                                })

                                Module.New("ImageLabel", {
                                    Name = "Icon",
                                    Parent = Clear,
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundTransparency = 1,
                                    Position = UDim2.fromScale(0.5, 0.5),
                                    Size = UDim2.fromOffset(16, 16),
                                    Image = "rbxassetid://112098013941956",
                                    ImageColor3 = Color3.fromRGB(234, 234, 234),
                                })
                            end

                            local Refresh = Module.New("Frame", {
                                Name = "Refresh",
                                Parent = Right,
                                Visible = OnRefresh and true or false,
                                BackgroundColor3 = Module.Theme,
                                Size = UDim2.fromOffset(25, 25),
                                Selectable = false,
                            }) do
                                Module.New("UIShadow", {
                                    Parent = Refresh,
                                    BlurRadius = UDim.new(0, 5),
                                    Transparency = 0.7
                                }) 

                                Module.New("UICorner", {
                                    Parent = Refresh,
                                    CornerRadius = UDim.new(0, 3),
                                })

                                Module.New("ImageLabel", {
                                    Name = "Icon",
                                    Parent = Refresh,
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundTransparency = 1,
                                    Position = UDim2.fromScale(0.5, 0.5),
                                    Size = UDim2.fromOffset(10, 10),
                                    Image = "rbxassetid://97804057623763",
                                    ImageColor3 = Color3.fromRGB(18, 18, 18),
                                })

                                Module.New("UIGradient", {
                                    Parent = Refresh,
                                    Color = ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
                                    }),
                                    Rotation = 145,
                                })
                            end

                            Module.Button(Clear).MouseButton1Click:Connect(function()
                                DropdownModule:Clear()
                            end)

                            Module.Button(Refresh).MouseButton1Click:Connect(function()
                                DropdownModule:Refresh()
                            end)
                        end

                        Module.New("Frame", {
                            Name = "Line",
                            Parent = Header,
                            AnchorPoint = Vector2.new(0, 1),
                            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                            Position = UDim2.fromScale(0, 1),
                            Size = UDim2.new(1, 0, 0, 1),
                            Selectable = false,
                        })
                    end

                    local Search = Module.New("Frame", {
                        Name = "Search",
                        Parent = Inner,
                        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                        LayoutOrder = -4,
                        Size = UDim2.new(1, -1, 0, 25),
                        Selectable = false,
                    }) do
                        Module.New("Frame", {
                            Name = "Line",
                            Parent = Search,
                            AnchorPoint = Vector2.new(0, 1),
                            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                            Position = UDim2.fromScale(0, 1),
                            Size = UDim2.new(1, 0, 0, 1),
                            Selectable = false,
                        })

                        Module.New("ImageLabel", {
                            Name = "Icon",
                            Parent = Search,
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 10, 0.5, 0),
                            Size = UDim2.fromOffset(10, 10),
                            Image = "rbxassetid://125928820284709",
                            ImageTransparency = 0.5,
                        })
                    end

                    local SearchInput = Module.New("TextBox", {
                        Name = "TextBox",
                        Parent = Search,
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 28, 0.5, 0),
                        Size = UDim2.new(1, -40, 1, 0),
                        FontFace = Module.FontRegular,
                        PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
                        PlaceholderText = "Search",
                        Text = "",
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    local DropdownScrolling = Module.New("ScrollingFrame", {
                        Name = "Scrolling",
                        Parent = Inner,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, -80),
                        ScrollBarImageTransparency = 1,
                        ScrollBarThickness = 0,
                    }) do
                        Module.New("UIListLayout", {
                            Parent = DropdownScrolling,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        })
                    end

                    DropdownModule.Scrolling = DropdownScrolling

                    Module.UpdateCanvas(
                        DropdownScrolling,
                        DropdownScrolling.UIListLayout,
                        Window.UIScale
                    )

                    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
                        local SearchText = string.lower(SearchInput.Text)

                        for _, Item in ipairs(DropdownScrolling:GetChildren()) do
                            if Item:IsA("Frame") and Item.Name == "NewList" then
                                local ItemTitle = Item:FindFirstChild("Inner")
                                    and Item.Inner:FindFirstChild("Title")

                                if ItemTitle then
                                    Item.Visible =
                                        SearchText == ""
                                        or string.find(
                                            string.lower(ItemTitle.Text),
                                            SearchText,
                                            1,
                                            true
                                        ) ~= nil
                                end
                            end
                        end
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if not IsShowing then
                            return
                        end

                        if Input.UserInputType ~= Enum.UserInputType.MouseButton1
                            and Input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end

                        local Mouse = Players.LocalPlayer:GetMouse()
                        local Position = NewDropdown.AbsolutePosition
                        local Size = NewDropdown.AbsoluteSize

                        local IsInside =
                            Mouse.X >= Position.X
                            and Mouse.X <= Position.X + Size.X
                            and Mouse.Y >= Position.Y
                            and Mouse.Y <= Position.Y + Size.Y

                        if not IsInside then
                            DropdownModule:Close()
                        end
                    end)
                end
            end

            local function UpdateValue()
                if not Multi then
                    return
                end

                local SelectedList = {}

                for Name, Order in pairs(SelectedValues) do
                    table.insert(SelectedList, {
                        Name = Name,
                        Order = Order,
                    })
                end

                table.sort(SelectedList, function(a, b)
                    return a.Order < b.Order
                end)

                local Values = {}

                for _, Data in ipairs(SelectedList) do
                    table.insert(Values, Data.Name)
                end

                Value = Values
                DropdownModule:UpdateFooter()

                return Values
            end

            local function UpdateOrder()
                if not Multi then
                    return
                end

                for _, Item in ipairs(DropdownModule.Scrolling:GetChildren()) do
                    if Item:IsA("Frame") and Item.Name == "NewList" then
                        local ItemTitle = Item:FindFirstChild("Inner")
                            and Item.Inner:FindFirstChild("Title")

                        if ItemTitle then
                            local Order = SelectedValues[ItemTitle.Text]

                            Item.LayoutOrder =
                                Order
                                or table.find(List, ItemTitle.Text)
                                or 0
                        end
                    end
                end
            end

            function DropdownModule:Close()
                IsShowing = false
                NewDropdown.Visible = false
                NewDropdown.Size = UDim2.new(0, 0, 1, 0)
            end

            function DropdownModule:Clear(Val)
                if Val ~= nil then
                    if Multi then
                        if type(Val) == "table" then
                            for _, Name in ipairs(Val) do
                                SelectedValues[Name] = nil
                            end
                        else
                            SelectedValues[Val] = nil
                        end

                        UpdateValue()
                    else
                        if Val == Value then
                            Value = "None"
                        end
                    end
                else
                    SelectedValues = {}
                    SelectedOrder = 0
                    Value = Multi and {} or "None"
                end

                for _, Item in ipairs(DropdownModule.Scrolling:GetChildren()) do
                    if Item:IsA("Frame") and Item.Name == "NewList" then
                        local ItemInner = Item:FindFirstChild("Inner")
                        local ItemTitle = ItemInner and ItemInner:FindFirstChild("Title")
                        local Check = ItemInner and ItemInner:FindFirstChild("Check")
                        local CheckStroke = Check and Check:FindFirstChildOfClass("UIStroke")

                        if ItemTitle then
                            Module.Tween(Item, {
                                Time = 0.15,
                                Style = "Linear",
                                Direction = "Out",
                                Goal = {
                                    BackgroundTransparency = 1,
                                },
                            }):Play()

                            Module.Tween(ItemTitle, {
                                Time = 0.15,
                                Style = "Linear",
                                Direction = "Out",
                                Goal = {
                                    TextTransparency = 0.5,
                                },
                            }):Play()
                        end

                        if Check then
                            Module.Tween(Check, {
                                Time = 0.15,
                                Style = "Linear",
                                Direction = "Out",
                                Goal = {
                                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                                },
                            }):Play()
                        end

                        if CheckStroke then
                            Module.Tween(CheckStroke, {
                                Time = 0.15,
                                Style = "Linear",
                                Direction = "Out",
                                Goal = {
                                    Transparency = 1,
                                },
                            }):Play()
                        end
                    end
                end

                DropdownModule:UpdateFooter()
                UpdateOrder()

                pcall(Callback, Value)
            end

            function DropdownModule:AddList(Name)
                if type(Name) ~= "string" then
                    return
                end

                local NewList = Module.New("Frame", {
                    Name = "NewList",
                    Parent = DropdownModule.Scrolling,
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 25),
                    LayoutOrder = table.find(List, Name) or 0,
                    Selectable = false,
                })

                local ItemInner = Module.New("Frame", {
                    Name = "Inner",
                    Parent = NewList,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Selectable = false,
                }) do
                    Module.New("UIPadding", {
                        Parent = ItemInner,
                        PaddingLeft = UDim.new(0, 10),
                    })
                end

                local Check = Module.New("Frame", {
                    Name = "Check",
                    Parent = ItemInner,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    Position = UDim2.new(1, -15, 0.5, 0),
                    Size = UDim2.fromOffset(6, 6),
                    Selectable = false,
                }) do
                    Module.New("UICorner", {
                        Parent = Check,
                        CornerRadius = UDim.new(1, 0),
                    })

                    Module.New("UIShadow", {
                        Parent = Check,
                        BlurRadius = UDim.new(0, 5),
                        Transparency = 0.7
                    }) 
                end

                local CheckStroke = Module.New("UIStroke", {
                    Parent = Check,
                    Thickness = 0.3,
                    Transparency = 1,
                })

                local ItemTitle = Module.New("TextLabel", {
                    Name = "Title",
                    Parent = ItemInner,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Selectable = false,
                    FontFace = Module.FontMedium,
                    Text = Name,
                    TextColor3 = Color3.fromRGB(234, 234, 234),
                    TextTransparency = 0.5,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }) do
                    Module.New("UIGradient", {
                        Parent = ItemTitle,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 129, 129)),
                        }),
                        Offset = Vector2.new(0, 0.4),
                        Rotation = 90,
                    })
                end

                Module.New("Frame", {
                    Name = "Line",
                    Parent = NewList,
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                    Selectable = false,
                })

                local function OnValue(IsSelected)
                    Module.Tween(NewList, {
                        Time = 0.15,
                        Style = "Linear",
                        Direction = "Out",
                        Goal = {
                            BackgroundTransparency = IsSelected and 0.85 or 1,
                        },
                    }):Play()

                    Module.Tween(ItemTitle, {
                        Time = 0.15,
                        Style = "Linear",
                        Direction = "Out",
                        Goal = {
                            TextTransparency = IsSelected and 0 or 0.5,
                        },
                    }):Play()

                    Module.Tween(Check, {
                        Time = 0.15,
                        Style = "Linear",
                        Direction = "Out",
                        Goal = {
                            BackgroundColor3 = IsSelected
                                and Color3.fromRGB(0, 255, 127)
                                or Color3.fromRGB(50, 50, 50),
                        },
                    }):Play()

                    Module.Tween(CheckStroke, {
                        Time = 0.15,
                        Style = "Linear",
                        Direction = "Out",
                        Goal = {
                            Transparency = IsSelected and 0.5 or 1,
                        },
                    }):Play()
                end

                local function OnSelected()
                    if Multi then
                        if SelectedValues[Name] then
                            SelectedValues[Name] = nil
                            OnValue(false)
                        else
                            SelectedOrder += 1
                            SelectedValues[Name] = SelectedOrder
                            OnValue(true)
                        end

                        local Values = UpdateValue()
                        UpdateOrder()
                        pcall(Callback, Values)
                    else
                        for _, Item in ipairs(DropdownModule.Scrolling:GetChildren()) do
                            if Item:IsA("Frame") and Item.Name == "NewList" and Item ~= NewList then
                                local OtherInner = Item:FindFirstChild("Inner")
                                local OtherTitle = OtherInner and OtherInner:FindFirstChild("Title")
                                local OtherCheck = OtherInner and OtherInner:FindFirstChild("Check")
                                local OtherStroke = OtherCheck and OtherCheck:FindFirstChildOfClass("UIStroke")

                                if OtherTitle then
                                    Module.Tween(Item, {
                                        Time = 0.15,
                                        Style = "Linear",
                                        Direction = "Out",
                                        Goal = {
                                            BackgroundTransparency = 1,
                                        },
                                    }):Play()

                                    Module.Tween(OtherTitle, {
                                        Time = 0.15,
                                        Style = "Linear",
                                        Direction = "Out",
                                        Goal = {
                                            TextTransparency = 0.5,
                                        },
                                    }):Play()
                                end

                                if OtherCheck then
                                    Module.Tween(OtherCheck, {
                                        Time = 0.15,
                                        Style = "Linear",
                                        Direction = "Out",
                                        Goal = {
                                            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                                        },
                                    }):Play()
                                end

                                if OtherStroke then
                                    Module.Tween(OtherStroke, {
                                        Time = 0.15,
                                        Style = "Linear",
                                        Direction = "Out",
                                        Goal = {
                                            Transparency = 1,
                                        },
                                    }):Play()
                                end
                            end
                        end

                        Value = Name
                        OnValue(true)
                        DropdownModule:UpdateFooter()
                        pcall(Callback, Value)
                    end
                end

                task.delay(0.1, function()
                    if Multi then
                        if IsValueInTable(Name, Value) then
                            SelectedOrder += 1
                            SelectedValues[Name] = SelectedOrder
                            OnValue(true)
                        end
                    elseif Name == Value then
                        OnValue(true)
                    end
                end)

                Module.Button(NewList).MouseButton1Click:Connect(OnSelected)

                return NewList
            end

            function DropdownModule:Refresh()
                local PreviousSelected = {}

                for Name, Order in pairs(SelectedValues) do
                    PreviousSelected[Name] = Order
                end

                local PreviousValue = Value

                for _, Item in ipairs(DropdownModule.Scrolling:GetChildren()) do
                    if Item:IsA("Frame") and Item.Name == "NewList" then
                        Item:Destroy()
                    end
                end

                List = (OnRefresh and OnRefresh()) or {}

                if Multi then
                    SelectedValues = {}
                    SelectedOrder = 0

                    local NewValue = {}

                    for _, Name in ipairs(List) do
                        if PreviousSelected[Name] then
                            SelectedValues[Name] = PreviousSelected[Name]
                            SelectedOrder = math.max(SelectedOrder, PreviousSelected[Name])
                            table.insert(NewValue, Name)
                        end
                    end

                    Value = NewValue
                else
                    if IsValueInTable(PreviousValue, List) then
                        Value = PreviousValue
                    else
                        Value = List[1] or "None"
                    end
                end

                for _, Name in ipairs(List) do
                    DropdownModule:AddList(Name)
                end

                UpdateOrder()
                DropdownModule:UpdateFooter()

                pcall(Callback, Value)
            end

            Module.Button(Row.Row).MouseButton1Click:Connect(function()
                if IsShowing then
                    DropdownModule:Close()
                    return
                end

                IsShowing = true
                NewDropdown.Visible = true

                Module.Tween(NewDropdown, {
                    Time = 0.3,
                    Style = "Back",
                    Direction = "Out",
                    Goal = {
                        Size = UDim2.new(0, 230, 1, 0),
                    },
                }):Play()
            end)

            for _, Name in ipairs(List) do
                DropdownModule:AddList(Name)
            end

            UpdateOrder()
            DropdownModule:UpdateFooter()
            task.spawn(pcall, Callback, Value)

            return DropdownModule
        end

        return TabModule
    end

    Window.PageLayout:JumpTo(Window.Homes)

    return Window
end

return Module
