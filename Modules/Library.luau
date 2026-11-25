local _ENV = (getgenv or getrenv or getfenv)()

local Framework = {}
local Types = {}

local clonefunction = clonefunction or function( ... ) return ... end
local cloneref = cloneref or function( ... ) return ... end

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
	})

	if _ENV.__SQC then _ENV.__SQC:Destroy() end
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

Module.New = function(Class, Properties)
	local Creations = Instance.new(Class)

	for Property, Value in Properties do
		Creations[Property] = Value
	end

	if Class == "Frame" or Class == "ImageLabel" then
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

Module.Tween = function(Object, Info)
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

Module.Asset = function(Id)
	if type(Id) == 'number' then
		return `rbxassetid://{Id}`
	elseif type(Id) == 'string' and Id:find('rbxassetid://') then
		return Id
	end

	return Id
end

Module.Transition = function(Frame)
	return Module.New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Parent = Frame
	})
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
	local zRows = {}
	
	local Rows = Module.New("Frame", {
		BackgroundTransparency = 0.97,
		Name = "Rows",
		Parent = Parent,
		Size = UDim2.new(1, 0, 0, Args.Footer and 35 or 30),
		Selectable = false
	}) do
		Module.New("UICorner", {
			CornerRadius = UDim.new(0, 6),
			Parent = Rows
		})
	end

	local Left = Module.New("Frame", {
		BackgroundTransparency = 1,
		Name = "Left",
		Parent = Rows,
		Size = UDim2.new(1, 0, 1, 0),
		Selectable = false
	}) do
		Module.New("UIListLayout", {
			Padding = UDim.new(0, 10),
			Parent = Left,
			FillDirection = FillDirection.Horizontal,
			SortOrder = SortOrder.LayoutOrder,
			VerticalAlignment = VerticalAlignment.Center
		})

		Module.New("UIPadding", {
			Parent = Left,
			PaddingLeft = UDim.new(0, 10)
		})
	end

	local Contents = Module.New("Frame", {
		BackgroundTransparency = 1,
		Name = "Contents",
		Parent = Left,
		Size = UDim2.new(1, -32, 1, 0),
		Selectable = false
	}) do
		Module.New("UIListLayout", {
			Parent = Contents,
			SortOrder = SortOrder.LayoutOrder,
			VerticalAlignment = VerticalAlignment.Center
		})
		
		zRows.Title = Module.New("TextLabel", {
			AutomaticSize = AutomaticSize.Y,
			BackgroundTransparency = 1,
			Name = "Title",
			Parent = Contents,
			Size = UDim2.new(1, 0, 0, 0),
			Selectable = false,
			FontFace = Module.FontMedium,
			Text = Args.Title,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 10,
			TextTruncate = TextTruncate.AtEnd,
			TextXAlignment = TextXAlignment.Left
		})
		
		if Args.Footer then
			zRows.Footer = Module.New("TextLabel", {
				AutomaticSize = AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Footer",
				Parent = Contents,
				Size = UDim2.new(1, 0, 0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				Text = Args.Footer,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 8,
				TextTransparency = 0.5,
				TextTruncate = TextTruncate.AtEnd,
				TextXAlignment = TextXAlignment.Left
			})
		end
	end

	local Right = Module.New("Frame", {
		BackgroundTransparency = 1,
		Name = "Right",
		Parent = Rows,
		Size = UDim2.new(1, 0, 1, 0),
		Selectable = false
	}) do
		Module.New("UIListLayout", {
			Padding = UDim.new(0, 10),
			Parent = Right,
			FillDirection = FillDirection.Horizontal,
			SortOrder = SortOrder.LayoutOrder,
			HorizontalAlignment = HorizontalAlignment.Right,
			VerticalAlignment = VerticalAlignment.Center
		})

		Module.New("UIPadding", {
			Parent = Right,
			PaddingRight = UDim.new(0, 10)
		})
	end
	
	function zRows:Padding(Side, Paddings)
		local Padding = Rows[Side]:FindFirstChildOfClass("UIPadding")
		if not Padding then return end

		for Index, Value in Paddings do
			Padding[Index] = UDim.new(0, Value)
		end
	end

	function zRows:Layout(Side, Value)
		local Layout = Rows[Side]:FindFirstChildOfClass("UIListLayout")
		if not Layout then return end

		Layout.Padding = UDim.new(0, Value)
	end
	
	zRows.Row = Rows
	zRows.Left = Left
	zRows.Right = Right
	
	return zRows
end

function Module:Window(Args)
	local Window = {} do
		Window.IsOpen = true
	end

	local Signal = Module.GoodSignal.new()

	local Title = Args.Title or "Novel's official"
	local Footer = Args.Footer or "Made by vita8it"
	
	function Window:NewModule(Name, Function)
		return Function and Function(Name)
	end
	
	Window:NewModule("@Window", function()
		local Squircle = Module.New("ScreenGui", {
			ScreenInsets = ScreenInsets.DeviceSafeInsets,
			IgnoreGuiInset = true,
			Name = "Squircle",
			Parent = Module.Parent,
			ZIndexBehavior = ZIndexBehavior.Global,
			DisplayOrder = 100
		})
		
		local UIScale = Module.New("UIScale", {
			Parent = Squircle,
		})

		local Background = Module.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			Name = "Background",
			Parent = Squircle,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 500, 0, 360),
			Selectable = false
		}) do
			Module.New("UICorner", {
				CornerRadius = UDim.new(0, 10),
				Parent = Background
			})

			Module.New("UIShadow", {
				Parent = Background,
				BlurRadius = UDim.new(0, 20),
				Transparency = 0.5
			}) 
		end
		
		CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			Module.SetAutoScale(Background, UIScale)
		end)
		
		_ENV.__SQC = Squircle
		
		Window.UIScale = UIScale
		Window.Background = Background
		
		Module.Draggable(Background, UIScale)
		Module.SetAutoScale(Background, UIScale)
	end)
	
	Window:NewModule('@Header', function()
		local Header = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Header",
			Parent = Window.Background,
			Size = UDim2.new(1, 0, 0, 50),
			Selectable = false
		})

		local Left = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Left",
			Parent = Header,
			Size = UDim2.new(1, 0, 1, 0),
			Selectable = false
		}) do
			Module.New("UIListLayout", {
				Padding = UDim.new(0, 10),
				Parent = Left,
				FillDirection = FillDirection.Horizontal,
				SortOrder = SortOrder.LayoutOrder,
				VerticalAlignment = VerticalAlignment.Center
			})
		end

		local Contents = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Content",
			Parent = Left,
			Size = UDim2.new(1, -32, 1, 0),
			Selectable = false
		}) do
			Module.New("UIListLayout", {
				Parent = Contents,
				SortOrder = SortOrder.LayoutOrder,
				VerticalAlignment = VerticalAlignment.Center
			})
			
			Module.New("UIPadding", {
				Parent = Left,
				PaddingLeft = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 10)
			})
		end
		
		Window.HeaderComponents = {
			Title = Module.New("TextLabel", {
				AutomaticSize = AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = Title,
				Parent = Contents,
				Size = UDim2.new(1, 0, 0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				Text = Title,
				TextColor3 = Color3.fromRGB(255, 0, 127),
				TextSize = 15,
				TextXAlignment = TextXAlignment.Left
			}),
			Footer = Module.New("TextLabel", {
				AutomaticSize = AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Footer",
				Parent = Contents,
				Size = UDim2.new(1, 0, 0, 0),
				Selectable = false,
				FontFace = Module.FontRegular,
				Text = Footer,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				TextTransparency = 0.5,
				TextXAlignment = TextXAlignment.Left
			})
		}
	end)
	
	Window:NewModule('@Sidebar', function()
		local Sidebar = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Sidebar",
			Parent = Window.Background,
			Size = UDim2.new(0, 150, 1, 0),
			Selectable = false
		}) do
			Module.New("UIPadding", {
				Parent = Sidebar,
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 7),
				PaddingTop = UDim.new(0, 55)
			})
		end

		local Scrolling = Module.New("ScrollingFrame", {
			BackgroundTransparency = 1,
			Name = "Scrolling",
			Parent = Sidebar,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarImageTransparency = 1,
			ScrollBarThickness = 0
		}) do
			Module.New("UIListLayout", {
				Parent = Scrolling,
				SortOrder = SortOrder.LayoutOrder
			})

			Module.New("UIPadding", {
				Parent = Scrolling,
				PaddingBottom = UDim.new(0, 1),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 3),
				PaddingTop = UDim.new(0, 1)
			})
		end
		
		Window.Sidebar = Sidebar
		Window.SidebarScrolling = Scrolling
		Module.UpdateCanvas(Scrolling, Scrolling.UIListLayout, Window.UIScale)
	end)
	
	Window:NewModule('@Pages', function()
		local Pages = Module.New("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Name = "Pages",
			Parent = Window.Background,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(1, -155, 1, 0),
			ClipsDescendants = true,
			Selectable = false
		}) do
			Module.New("UIPageLayout", {
				Parent = Pages,
				EasingStyle = EasingStyle.Exponential,
				TweenTime = 0.45,
				FillDirection = FillDirection.Horizontal,
				SortOrder = SortOrder.LayoutOrder,
				VerticalAlignment = VerticalAlignment.Center
			})
		end
		
		Window.Pages = Pages
		Window.PageLayout = Pages.UIPageLayout
	end)
	
	function Window:MakeTab(Args)
		local TabModule = {}

		local Title = Args.Title or "Unknow"
		local Icon = Args.Icon or 80212074789397
		local TextColor = Args.TextColor or Color3.fromRGB(255, 255, 255)
		
		local Transequence = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		local NewTab = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "NewTab",
			Parent = Window.SidebarScrolling,
			Size = UDim2.new(1, 0, 0, 30),
			Selectable = false
		}) do
			Module.New("UICorner", {
				CornerRadius = UDim.new(0, 6),
				Parent = NewTab
			})
			
			Module.New("UIStroke", {
				Color = Color3.fromRGB(50, 50, 50),
				Thickness = 0.75,
				Transparency = 1,
				Parent = NewTab
			})

			Module.New("UIGradient", {
				Parent = NewTab.UIStroke,
				Transparency = Transequence,
				Rotation = 90
			})
		end

		local Index = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Index",
			Parent = NewTab,
			Size = UDim2.new(1, 0, 1, 0),
			Selectable = false
		}) do
			Module.New("UIListLayout", {
				Parent = Index,
				FillDirection = FillDirection.Horizontal,
				SortOrder = SortOrder.LayoutOrder
			})
			
			Module.New("TextLabel", {
				BackgroundTransparency = 1,
				Name = "Title",
				Parent = Index,
				Size = UDim2.new(1, -30, 1, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				Text = "Tasks",
				TextColor3 = TextColor,
				TextSize = 12,
				TextXAlignment = TextXAlignment.Left,
				TextTransparency = 0.5
			})
		end

		local IconFrame = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "IconFrame",
			LayoutOrder = -1,
			Parent = Index,
			Size = UDim2.new(0, 30, 0, 30),
			Selectable = false
		}) do
			Module.New("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Name = "Icon",
				Parent = IconFrame,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 15, 0, 15),
				Image = Module.Asset(Icon),
				ImageColor3 = TextColor,
				ImageTransparency = 0.5
			})
		end
		
		local NewPage = Module.New("ScrollingFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Name = "NewPage",
			Parent = Window.Pages,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, -20),
			ScrollBarImageTransparency = 1,
			ScrollBarThickness = 0
		}) do
			Module.New("UIListLayout", {
				Padding = UDim.new(0, 5),
				Parent = NewPage,
				SortOrder = SortOrder.LayoutOrder
			})

			Module.New("UIPadding", {
				Parent = NewPage,
				PaddingTop = UDim.new(0, 1),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 10)
			})
			
			Module.UpdateCanvas(NewPage, NewPage.UIListLayout, Window.UIScale)
		end
		
		function TabModule.__Update(Tab, Value)
			Module.Tween(Tab, {
				Time = 0.15,
				Style = "Linear",
				Direction = "Out",
				Goal = {
					BackgroundTransparency = Value and 0.95 or 1,
				},
			}):Play()
			
			Module.Tween(Tab.UIStroke, {
				Time = 0.15,
				Style = "Linear",
				Direction = "Out",
				Goal = {
					Transparency = Value and 0 or 1,
				},
			}):Play()
			
			Module.Tween(Tab.Index.Title, {
				Time = 0.15,
				Style = "Linear",
				Direction = "Out",
				Goal = {
					TextTransparency = Value and 0 or 0.5,
				},
			}):Play()
			
			Module.Tween(Tab.Index.IconFrame.Icon, {
				Time = 0.15,
				Style = "Linear",
				Direction = "Out",
				Goal = {
					ImageTransparency = Value and 0 or 0.5,
				},
			}):Play()
		end
		
		function TabModule.__Select()
			if Window.IsTransparent then return end
			if Window.CurrentPage == NewPage then
				return nil
			end
			
			for _, Tab in Window.SidebarScrolling:GetChildren() do
				if Tab.Name == "NewTab" and Tab ~= NewTab then
					TabModule.__Update(Tab, false)
				end
			end
			
			TabModule.__Update(NewTab, true)
			Window.PageLayout:JumpTo(NewPage)
			Window.CurrentPage = NewPage
		end
		
		Module.Button(NewTab).MouseButton1Click:Connect(function()
			if Window.IsTransparent then return end
			
			TabModule.__Select()
		end)
		
		function TabModule:Section(Title)
			return Module.New("TextLabel", {
				AutomaticSize = AutomaticSize.XY,
				BackgroundTransparency = 1,
				Name = "Section",
				Parent = NewPage,
				Size = UDim2.new(0, 0, 0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				Text = tostring(Title),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16
			})
		end
		
		function TabModule:TextLabel(Args)
			local LabelModule = {}

			local Title = Args.Title or "Unknow"
			local Footer = Args.Footer or nil
			local Text = Args.Text or nil
			
			local Row = Module.NewRows(NewPage, {
				Title = Title, Footer = Footer, Icon = Icon,
			})
			
			local Texts = Module.New("TextLabel", {
				Name = "Text",
				Parent = Row.Right,
				AutomaticSize = AutomaticSize.XY,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				RichText = true,
				Visible = Text and true or false,
				Text = tostring(Text),
				TextColor3 = Color3.fromRGB(125, 125, 125),
				TextSize = 11,
				TextXAlignment = TextXAlignment.Right,
			})
			
			function LabelModule:SetTitle(Texter)
				Row.Title.Text = tostring(Texter)
			end

			function LabelModule:SetDesc(Texter)
				Row.Footer.Text = tostring(Texter)
			end

			function LabelModule:SetText(Texter)
				Texts.Text = tostring(Texter)
			end
			
			return LabelModule
		end
		
		function TabModule:Button(Args)
			local ButtonModule = {} do
				ButtonModule.LastClick = 0
			end

			local Title = Args.Title or "Unknow"
			local Footer = Args.Footer or nil
			
			local Callback = Args.Callback or function() end
			local Cooldown = Args.Cooldown or 0.5

			local Row = Module.NewRows(NewPage, {
				Title = Title,
				Footer = Footer
			})

			local Icon = Module.New("ImageLabel", {
				BackgroundTransparency = 1,
				Name = "Icon",
				Parent = Row.Right,
				Size = UDim2.new(0, 15, 0, 15),
				Image = "rbxassetid://73595924463234",
				ImageTransparency = 0.35
			})

			Module.Button(Row.Row).MouseButton1Click:Connect(function()
				if Window.IsTransparent then return end
				
				Module.Tween(Icon, {
					Time = 0.15,
					Style = "Quad",
					Direction = "Out",
					Goal = {
						ImageTransparency = 0,
						ImageColor3 = Color3.fromRGB(255, 0, 127),
					}
				}):Play()
				
				Module.Tween(Row.Row, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						BackgroundTransparency = 0.94,
					}
				}):Play()

				task.delay(0.1, function()
					Module.Tween(Icon, {
						Time = 0.15,
						Style = "Quad",
						Direction = "Out",
						Goal = {
							ImageTransparency = 0.35,
							ImageColor3 = Color3.fromRGB(255, 255, 255),
						}
					}):Play()
				end)
				
				task.delay(0.075, function()
					Module.Tween(Row.Row, {
						Time = 0.15,
						Style = "Linear",
						Direction = "Out",
						Goal = {
							BackgroundTransparency = 0.97,
						}
					}):Play()
				end)
				
				if tick() - ButtonModule.LastClick <= Cooldown then
					return false
				end

				ButtonModule.LastClick = tick()
				task.spawn(pcall, Callback)
			end)

			return ButtonModule
		end
		
		function TabModule:Toggle(Args)
			local ToggleModule = {}

			local Title = Args.Title or "Unknow"
			local Footer = Args.Footer or nil
			local Value = Args.Value or false
			local Callback = Args.Callback or function() end

			local Row = Module.NewRows(NewPage, {
				Title = Title,
				Footer = Footer,
				Icon = Icon,
			})
			
			local ValueFrame = Module.New("Frame", {
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				Name = "ValueFrame",
				Parent = Row.Right,
				Size = UDim2.new(0, 28, 0, 16),
				Selectable = false
			}) do
				Module.New("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = ValueFrame
				})
			end

			local Circle = Module.New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 0.5,
				Name = "Circle",
				Parent = ValueFrame,
				Position = UDim2.new(0.5, -5, 0.5, 0),
				Size = UDim2.new(0, 10, 0, 10),
				Selectable = false
			}) do
				Module.New("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = Circle
				})
			end
			
			function ToggleModule.__Update(__Value)
				Module.Tween(ValueFrame, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						BackgroundColor3 = __Value and Color3.fromRGB(255, 0, 127) or Color3.fromRGB(50, 50, 50),
						BackgroundTransparency = __Value and 0.8 or 0
					}
				}):Play()
				
				Module.Tween(Circle, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						BackgroundColor3 = __Value and Color3.fromRGB(255, 0, 127) or Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = __Value and 0.35 or 0.5,
						Position = __Value and UDim2.new(0.5, 6, 0.5, 0) or UDim2.new(0.5, -6, 0.5, 0)
					}
				}):Play()
				
				Module.Tween(Row.Title, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						TextColor3 = __Value and Color3.fromRGB(255, 0, 127) or Color3.fromRGB(255, 255, 255),
					}
				}):Play()
				
				Module.Tween(Row.Row, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						BackgroundTransparency = 0.94,
					}
				}):Play()
				
				task.delay(0.075, function()
					Module.Tween(Row.Row, {
						Time = 0.15,
						Style = "Linear",
						Direction = "Out",
						Goal = {
							BackgroundTransparency = 0.97,
						}
					}):Play()
				end)
				
				task.spawn(pcall, Callback, __Value)
			end
			
			function ToggleModule:SetValue(Value)
				Value = Value
				self.__Update(Value)
			end
			
			Module.Button(Row.Row).MouseButton1Click:Connect(function()
				if Window.IsTransparent then return end
				
				Value = not Value
				ToggleModule.__Update(Value)
			end)
			
			task.spawn(ToggleModule.__Update, Value)
			
			return ToggleModule
		end
		
		function TabModule:Slider(Args)
			local SliderModule = {}

			local Title = Args.Title or ""
			local Footer = Args.Footer or nil
			
			local Min = Args.Min or 1
			local Max = Args.Max or 10
			
			local Value = Args.Value or Min
			local Rounding = Args.Rounding or 0
			
			local Callback = Args.Callback or function() end

			local Row = Module.NewRows(NewPage, {
				Title = Title, Footer = Footer, Icon = Icon,
			})
			
			Row:Padding("Right", {
				PaddingRight = 7
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
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
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
				BackgroundColor3 = Color3.fromRGB(255, 0, 127),
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
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromOffset(7, 10),
				Selectable = false,
			}) do
				Module.New("UICorner", {
					Parent = Circle,
					CornerRadius = UDim.new(1, 0),
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
				if Window.IsTransparent then return end
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
				if Window.IsTransparent then return end
				if not Dragging then return end

				if Input.UserInputType == Enum.UserInputType.MouseMovement
					or Input.UserInputType == Enum.UserInputType.Touch then

					Update(InputValue(Input))
				end
			end)

			TextBox.FocusLost:Connect(function()
				local Value = tonumber(TextBox.Text:match("%d+"))
				Update(Value ~= nil and Value or Min)
			end)
			
			Signal:Connect(function(Type, Value)
				if Type == 'UnloadTextbox' then
					TextBox.TextEditable = not Value
					TextBox.Interactable = not Value
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
			
			local Value = Args.Value or "None"
			local Callback = Args.Callback or function() end

			local Row = Module.NewRows(NewPage, {
				Title = Title, Footer = Footer, Icon = Icon,
			})
			
			local ValueFrame = Module.New("Frame", {
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				Name = "Value",
				Parent = Row.Right,
				Size = UDim2.new(0, 60, 0, 16),
				Selectable = false
			}) do
				Module.New("UICorner", {
					CornerRadius = UDim.new(0, 4),
					Parent = ValueFrame
				})
			end

			local TextBox: TextBox = Module.New("TextBox", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Parent = ValueFrame,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -20, 1, 0),
				FontFace = Module.FontRegular,
				PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
				PlaceholderText = "Empty",
				Text = tostring(Value),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 9,
				TextTransparency = 0.5,
				TextTruncate = Enum.TextTruncate.AtEnd
			})

			TextBox.FocusLost:Connect(function()
				Value = TextBox.Text
				Callback(Value)
			end)
			
			Signal:Connect(function(Type, Value)
				if Type == 'UnloadTextbox' then
					TextBox.TextEditable = not Value
					TextBox.Interactable = not Value
				end
			end)

			task.spawn(pcall, Callback, Value)
			
			return TextboxModule
		end
		
		function TabModule:Dropdown(Args)
			local DropdownModule = {
				IsShowing = false,
				SelectedValues = {},
			}

			local Title = Args.Title or "Unknown"

			local List = Args.List or { "None" }
			local Value = Args.Value or List[1]

			local Multi = typeof(Value) == "table"
			local Callback = Args.Callback or function() end

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

			local Row = Module.NewRows(NewPage, {
				Title = Title,
				Footer = GetText(),
				Icon = Icon,
			})

			Module.New("ImageLabel", {
				Name = "Dropdown",
				Parent = Row.Right,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(15, 15),
				Image = "rbxassetid://132291592681506",
				ImageTransparency = 0.5,
			})

			DropdownModule.BuildLayer = (function()
				local Dropdown = Module.New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(29, 29, 29),
					Name = "Dropdown",
					Parent = Window.Background,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 300, 0, 250),
					Selectable = false,
					Visible = false,
					ZIndex = 999,
				}) do
					Module.New("UICorner", {
						Parent = Dropdown,
					})

					Module.New("UIStroke", {
						Color = Color3.fromRGB(60, 60, 60),
						Parent = Dropdown,
					})

					Module.New("UIListLayout", {
						Parent = Dropdown,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					})

					Module.New("Frame", {
						BackgroundColor3 = Color3.fromRGB(50, 50, 50),
						LayoutOrder = -4,
						Name = "Line",
						Parent = Dropdown,
						Size = UDim2.new(1, 0, 0, 1),
						Selectable = false,
						ZIndex = 999,
					})

					Module.Transition(Dropdown.UIStroke)
				end

				local Header = Module.New("Frame", {
					BackgroundTransparency = 1,
					LayoutOrder = -5,
					Name = "Header",
					Parent = Dropdown,
					Size = UDim2.new(1, 0, 0, 35),
					Selectable = false,
					ZIndex = 999,
				}) do
					Module.New("UIPadding", {
						Parent = Header,
						PaddingBottom = UDim.new(0, 5),
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 5),
					})

					Module.New("UIListLayout", {
						Padding = UDim.new(0, 5),
						Parent = Header,
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
					})
				end

				local Searching = Module.New("Frame", {
					BackgroundColor3 = Color3.fromRGB(35, 35, 35),
					Name = "Searching",
					Parent = Header,
					Size = UDim2.new(1, 0, 1, 0),
					Selectable = false,
					ZIndex = 999,
				}) do
					Module.New("ImageLabel", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundTransparency = 1,
						Name = "Icon",
						Parent = Searching,
						Position = UDim2.new(1, -6, 0.5, 0),
						Size = UDim2.new(0, 12, 0, 12),
						Image = "rbxassetid://74498754645375",
						ImageTransparency = 0.5,
						ZIndex = 999,
					})

					Module.New("UICorner", {
						Parent = Searching,
						TopRightRadius = UDim.new(0, 5),
						BottomRightRadius = UDim.new(0, 2),
						TopLeftRadius = UDim.new(0, 5),
						BottomLeftRadius = UDim.new(0, 2),
					})
				end

				local TextBox = Module.New("TextBox", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Parent = Searching,
					Position = UDim2.new(0.47, 0, 0.5, 0),
					Size = UDim2.new(0.925, -20, 1, 0),
					FontFace = Module.FontMedium,
					PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
					PlaceholderText = "Search",
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 10,
					TextTransparency = 0.5,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 999,
				})

				local Scrolling = Module.New("ScrollingFrame", {
					BackgroundTransparency = 1,
					LayoutOrder = -3,
					Name = "Scrolling",
					Parent = Dropdown,
					Size = UDim2.new(1, 0, 1, -45),
					ScrollBarImageTransparency = 1,
					ScrollBarThickness = 0,
					ZIndex = 999,
				}) do
					Module.New("UIListLayout", {
						Padding = UDim.new(0, 5),
						Parent = Scrolling,
						SortOrder = Enum.SortOrder.LayoutOrder,
					})

					Module.New("UIPadding", {
						Parent = Scrolling,
						PaddingBottom = UDim.new(0, 5),
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 5),
					})
				end

				TextBox:GetPropertyChangedSignal("Text"):Connect(function()
					local SearchText = string.lower(TextBox.Text)

					for _, NewList in Scrolling:GetChildren() do
						if NewList:IsA("Frame") and NewList.Name == "NewList" then
							local ItemTitle = NewList:FindFirstChild("Index") and NewList.Index:FindFirstChild("Title")

							if ItemTitle then
								NewList.Visible = SearchText == "" or string.find(string.lower(ItemTitle.Text), SearchText, 1, true) ~= nil
							end
						end
					end
				end)

				function DropdownModule:Close()
					self.IsShowing = false

					Dropdown.Visible = false
					Dropdown.Position = UDim2.new(0.5, 0, 0.4, 0)
					Window:LockWindow(false)
				end

				function DropdownModule:Open()
					self.IsShowing = true
					Dropdown.Visible = true

					Module.Tween(Dropdown, {
						Time = 0.3,
						Style = "Back",
						Direction = "Out",
						Goal = {
							Position = UDim2.new(0.5, 0, 0.5, 0),
						},
					}):Play()

					Window:LockWindow(true)
				end

				DropdownModule.Scrolling = Scrolling
				Module.UpdateCanvas(Scrolling, Scrolling.UIListLayout, Window.UIScale)

				UserInputService.InputBegan:Connect(function(Input)
					if not DropdownModule.IsShowing then
						return
					end

					if Input.UserInputType ~= Enum.UserInputType.MouseButton1
						and Input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					local Mouse = Players.LocalPlayer:GetMouse()
					local Position = Dropdown.AbsolutePosition
					local Size = Dropdown.AbsoluteSize

					local IsInside = Mouse.X >= Position.X
						and Mouse.X <= Position.X + Size.X
						and Mouse.Y >= Position.Y
						and Mouse.Y <= Position.Y + Size.Y

					if not IsInside then
						DropdownModule:Close()
					end
				end)
			end)()

			function DropdownModule:UpdateFooter()
				if Row.Footer then
					Row.Footer.Text = GetText()
				end
			end

			function DropdownModule:OnSelect(Frame, IsSelected)
				Module.Tween(Frame, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						BackgroundTransparency = IsSelected and 0.95 or 1,
					},
				}):Play()

				Module.Tween(Frame.UIStroke, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						Transparency = IsSelected and 0 or 1,
					},
				}):Play()

				Module.Tween(Frame.Index.Icon, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						ImageTransparency = IsSelected and 0 or 1,
					},
				}):Play()

				Module.Tween(Frame.Index.Title, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						TextTransparency = IsSelected and 0 or 0.5,
					},
				}):Play()
			end

			function DropdownModule:UnSelectAll()
				for _, NewList in DropdownModule.Scrolling:GetChildren() do
					if NewList:IsA("Frame") and NewList.Name == "NewList" then
						DropdownModule:OnSelect(NewList, false)
					end
				end
			end

			function DropdownModule:AddList(Name)
				local NewList = Module.New("Frame", {
					BackgroundTransparency = 1,
					Name = "NewList",
					Parent = DropdownModule.Scrolling,
					Size = UDim2.new(1, 0, 0, 30),
					Selectable = false,
					ZIndex = 999,
				}) do
					Module.New("UICorner", {
						CornerRadius = UDim.new(0, 3),
						Parent = NewList,
					})

					Module.New("UIStroke", {
						Color = Color3.fromRGB(50, 50, 50),
						Transparency = 1,
						Parent = NewList,
					})

					Module.Transition(NewList.UIStroke)
				end

				local Button = Module.Button(NewList) do
					Button.ZIndex = 999
				end

				local Index = Module.New("Frame", {
					BackgroundTransparency = 1,
					Name = "Index",
					Parent = NewList,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 999,
					Selectable = false,
				}) do
					Module.New("TextLabel", {
						BackgroundTransparency = 1,
						Name = "Title",
						Parent = Index,
						Size = UDim2.new(1, -30, 1, 0),
						Selectable = false,
						FontFace = Module.FontMedium,
						Text = tostring(Name),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextTransparency = 0.5,
						TextSize = 12,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 999,
					})

					Module.New("UIPadding", {
						Parent = Index,
						PaddingLeft = UDim.new(0, 10),
					})

					Module.New("ImageLabel", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundTransparency = 1,
						Name = "Icon",
						Parent = Index,
						Position = UDim2.new(1, -10, 0.5, 0),
						Size = UDim2.new(0, 12, 0, 12),
						Image = "rbxassetid://93349826813564",
						ImageTransparency = 1,
						ZIndex = 999,
					})
				end

				local function OnSelect()
					if Multi then
						if DropdownModule.SelectedValues[Name] then
							DropdownModule.SelectedValues[Name] = nil
							DropdownModule:OnSelect(NewList, false)
						else
							DropdownModule.SelectedValues[Name] = true
							DropdownModule:OnSelect(NewList, true)
						end

						local Values = {}
						
						for SelectedName in pairs(DropdownModule.SelectedValues) do
							table.insert(Values, SelectedName)
						end
						
						Value = Values
						DropdownModule:UpdateFooter()
						pcall(Callback, Value)
					else
						DropdownModule:UnSelectAll()

						DropdownModule.SelectedValues = { [Name] = true }
						DropdownModule:OnSelect(NewList, true)

						Value = Name
						DropdownModule:UpdateFooter()
						pcall(Callback, Value)
					end
				end

				Button.MouseButton1Click:Connect(OnSelect)

				task.delay(0.1, function()
					if Multi then
						if IsValueInTable(Name, Value) then
							DropdownModule.SelectedValues[Name] = true
							DropdownModule:OnSelect(NewList, true)
						end
					elseif Name == Value then
						DropdownModule:OnSelect(NewList, true)
					end
				end)

				return NewList
			end

			local Button = Module.Button(Row.Row) do
				Button.ZIndex = 999
			end

			Button.MouseButton1Click:Connect(function()
				if Window.IsTransparent then return end
				if DropdownModule.IsShowing then return end

				DropdownModule:Open()
			end)

			for _, Name in List do
				DropdownModule:AddList(Name)
			end

			DropdownModule:UpdateFooter()
			task.spawn(pcall, Callback, Value)

			return DropdownModule
		end
		
		function TabModule:Banner()
			local Banner = Module.New("ImageLabel", {
				BackgroundTransparency = 1,
				Name = "Banner",
				Parent = NewPage,
				Size = UDim2.new(1, 0, 0, 160),
				Image = "rbxassetid://102933007142060",
				ScaleType = Enum.ScaleType.Crop
			}) do
				Module.New("UICorner", {
					CornerRadius = UDim.new(0, 6),
					Parent = Banner
				})

				Module.New("UIStroke", {
					Color = Color3.fromRGB(45, 45, 45),
					Parent = Banner
				})
			end
		end
		
		function TabModule:SectionBanner(Args)
			local Banner = Module.New("ImageLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				Name = "Banner",
				Parent = NewPage,
				Size = UDim2.new(1, 0, 0, Args.Size or 70),
				Image = Module.Asset(Args.Banner),
				ScaleType = Enum.ScaleType.Crop
			}) do
				Module.New("UICorner", {
					CornerRadius = UDim.new(0, 6),
					Parent = Banner
				})

				Module.New("UIStroke", {
					Color = Color3.fromRGB(45, 45, 45),
					Parent = Banner
				})
			end

			local Black = Module.New("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.25,
				Name = "Black",
				Parent = Banner,
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false
			}) do
				Module.New("UICorner", {
					CornerRadius = UDim.new(0, 6),
					Parent = Black
				})
				
				Module.New("UIGradient", {
					Rotation = -90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.5, 0),
						NumberSequenceKeypoint.new(1, 1)
					}),
					Parent = Black
				})
			end

			local Title = Module.New("TextLabel", {
				BackgroundTransparency = 1,
				Name = "Title",
				Parent = Black,
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false,
				FontFace = Font.new("rbxassetid://12187374537", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Text = Args.Title,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 25,
				TextStrokeTransparency = 0.5,
				TextTruncate = Enum.TextTruncate.AtEnd
			}) do
				Module.New("UIGradient", {
					Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
					},
					Offset = Vector2.new(0, 0.30000001192092896),
					Rotation = 90,
					Parent = Title
				})
			end
			
			return Banner
		end
			
		
		return TabModule
	end
	
	Window:NewModule('@Toggle', function()
		local Toggle = Module.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(39, 39, 39),
			Name = "Toggle",
			Parent = _ENV.__SQC,
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.new(0, 200, 0, 45),
			Selectable = false
		}) do
			Module.New("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = Toggle
			})

			Module.New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 52, 52))
				}),
				Rotation = 90,
				Parent = Toggle
			})

			Module.New("UIShadow", {
				Parent = Toggle,
				BlurRadius = UDim.new(0, 20),
				Transparency = 0.5
			}) 
			
			Module.New("UIPadding", {
				Parent = Toggle,
				PaddingLeft = UDim.new(0, 8)
			})
			
			Module.New("UIListLayout", {
				Padding = UDim.new(0, 2),
				Parent = Toggle,
				FillDirection = FillDirection.Horizontal,
				SortOrder = SortOrder.LayoutOrder,
				VerticalAlignment = VerticalAlignment.Center
			})
		end


		local IconFrame = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "IconFrame",
			Parent = Toggle,
			Size = UDim2.new(0, 30, 0, 30),
			Selectable = false
		}) do
			Module.New("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Name = "Icon",
				Parent = IconFrame,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 17, 0, 17),
				Image = "rbxassetid://104985774171028",
			})
		end

		local Contents = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Contents",
			Parent = Toggle,
			Size = UDim2.new(1, -105, 1, 0),
			Selectable = false
		}) do
			Module.New("TextLabel", {
				AutomaticSize = AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Title",
				Parent = Contents,
				Size = UDim2.new(1, 0, 0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				RichText = true,
				Text = "Empty",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 10,
				TextTruncate = TextTruncate.AtEnd,
				TextXAlignment = TextXAlignment.Left
			})

			Module.New("UIListLayout", {
				Parent = Contents,
				SortOrder = SortOrder.LayoutOrder,
				VerticalAlignment = VerticalAlignment.Center
			})

			Module.New("TextLabel", {
				AutomaticSize = AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Footer",
				Parent = Contents,
				Size = UDim2.new(1, -10, 0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				Text = "Nothing runnings",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 8,
				TextTransparency = 0.5,
				TextXAlignment = TextXAlignment.Left
			})
			
			function Window:WatermarkTitle(Text)
				Contents.Title.Text = tostring(Text)
			end
			
			function Window:WatermarkFooter(Text)
				Contents.Footer.Text = tostring(Text)
			end
		end

		local Right = Module.New("Frame", {
			BackgroundTransparency = 1,
			Name = "Right",
			Parent = Toggle,
			Size = UDim2.new(0, 65, 0, 45),
			Selectable = false
		})

		local Cancel = Module.New("Frame", {
			BackgroundColor3 = Color3.fromRGB(234, 234, 234),
			Name = "Cancel",
			Parent = Right,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 55, 0, 20),
			Selectable = false
		}) do
			Module.New("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = Cancel
			})

			Module.New("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutomaticSize = AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Title",
				Parent = Cancel,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -20, 1, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				RichText = true,
				Text = "Close",
				TextSize = 10,
				TextTruncate = TextTruncate.AtEnd
			})

			Module.New("UIListLayout", {
				Parent = Right,
				SortOrder = SortOrder.LayoutOrder,
				VerticalAlignment = VerticalAlignment.Center
			})

			Module.New("UIPadding", {
				Parent = Right,
				PaddingRight = UDim.new(0, 10)
			})
		end
		
		Module.Button(Cancel).MouseButton1Click:Connect(function()
			Window.IsOpen = not Window.IsOpen
			Window.Background.Visible = Window.IsOpen
			
			Cancel.Title.Text = Window.IsOpen and "Close" or "Open"
			
			Module.Tween(Cancel, {
				Time = 0.15,
				Style = "Linear",
				Direction = "Out",
				Goal = {
					BackgroundTransparency = 0.5
				},
			}):Play()
			
			task.delay(0.08, function()
				Module.Tween(Cancel, {
					Time = 0.15,
					Style = "Linear",
					Direction = "Out",
					Goal = {
						BackgroundTransparency = 0
					},
				}):Play()
			end)
		end)
	end)
	
	Window:NewModule('@Notification', function()
		local Notification = Module.New("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Name = "Notification",
			Parent = _ENV.__SQC,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 200, 1, 0),
			Selectable = false
		})

		Module.New("UIListLayout", {
			Parent = Notification,
			Padding = UDim.new(0, 5),
			SortOrder = SortOrder.LayoutOrder,
			HorizontalAlignment = HorizontalAlignment.Right,
			VerticalAlignment = VerticalAlignment.Bottom
		})

		Module.New("UIPadding", {
			Parent = Notification,
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10)
		})
		
		function Window:Notification(Args)
			local Title = Args.Title
			local Footer = Args.Footer
			local Duration = Args.Duration or 5
			local Icon = Args.Icon

			local NewNotify = Module.New("Frame", {
				BackgroundTransparency = 1,
				Name = "NewNotify",
				Parent = Notification,
				Size = UDim2.new(1, 0, 0, 50),
				Selectable = false,
			})

			local Scale = Module.New("Frame", {
				BackgroundColor3 = Color3.fromRGB(39, 39, 39),
				Name = "Scale",
				Parent = NewNotify,
				Position = UDim2.new(1.5, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false,
			})

			Module.New("UICorner", {
				CornerRadius = UDim.new(0, 5),
				Parent = Scale,
			})

			Module.New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 52, 52)),
				}),
				Rotation = 90,
				Parent = Scale,
			})

			Module.New("UIShadow", {
				Parent = Scale,
				BlurRadius = UDim.new(0, 20),
				Transparency = 0.5
			}) 

			local Rows = Module.New("Frame", {
				BackgroundTransparency = 0.97,
				Name = "Rows",
				Parent = Scale,
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false,
			})

			Module.New("UICorner", {
				CornerRadius = UDim.new(0, 6),
				Parent = Rows,
			})

			local Left = Module.New("Frame", {
				BackgroundTransparency = 1,
				Name = "Left",
				Parent = Rows,
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false,
			})

			local Content = Module.New("Frame", {
				BackgroundTransparency = 1,
				Name = "Content",
				Parent = Left,
				Size = UDim2.new(1, -32, 1, 0),
				Selectable = false,
			})

			Module.New("UIListLayout", {
				Parent = Content,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			})

			Module.New("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Title",
				Parent = Content,
				Size = UDim2.new(1, 0, 0, 0),
				Selectable = false,
				FontFace = Module.FontMedium,
				Text = Title or "Notification",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 10,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			Module.New("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Footer",
				Parent = Content,
				Size = UDim2.new(1, 0, 0, 0),
				Selectable = false,
				FontFace = Font.new("rbxassetid://12187374537", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Text = Footer or "This is notification.",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 8,
				TextTransparency = 0.5,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			Module.New("UIListLayout", {
				Padding = UDim.new(0, 5),
				Parent = Left,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			})

			Module.New("UIPadding", {
				Parent = Left,
				PaddingLeft = UDim.new(0, 10),
			})

			local IconFrame = Module.New("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = -10,
				Name = "IconFrame",
				Parent = Left,
				Size = UDim2.new(0, 30, 0, 30),
				Selectable = false,
			})

			Module.New("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Name = "Icon",
				Parent = IconFrame,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				Image = Module.Asset(Icon) or "rbxassetid://70987453123239",
				ImageColor3 = Color3.fromRGB(255, 170, 0),
			})

			local Right = Module.New("Frame", {
				BackgroundTransparency = 1,
				Name = "Right",
				Parent = Rows,
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false,
			})

			Module.New("UIListLayout", {
				Padding = UDim.new(0, 10),
				Parent = Right,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			})

			Module.New("UIPadding", {
				Parent = Right,
				PaddingRight = UDim.new(0, 10),
			})

			Module.Tween(Scale, {
				Time = 0.45,
				Style = "Back",
				Direction = "Out",
				Goal = {
					Position = UDim2.new(0, 0, 0, 0),
				},
			}):Play()

			task.delay(Duration, function()
				local SlideOut = Module.Tween(Scale, {
					Time = 0.45,
					Style = "Back",
					Direction = "In",
					Goal = {
						Position = UDim2.new(1.5, 0, 0, 0),
					},
				})

				SlideOut.Completed:Once(function()
					NewNotify:Destroy()
				end)

				SlideOut:Play()
			end)
		end
	end)

	function Window:Load()
		local Blackframe = Module.New("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			Name = "Blackframe",
			Parent = Window.Background,
			Size = UDim2.new(1, 0, 1, 0),
			Selectable = false
		}) do
			Module.New("UICorner", {
				CornerRadius = UDim.new(0, 10),
				Parent = Blackframe
			})
		end

		function Window:LockWindow(Value)
			Module.Tween(Blackframe, {
				Time = 0.15,
				Style = "Linear",
				Direction = "Out",
				Goal = {
					BackgroundTransparency = Value and 0.2 or 1,
				},
			}):Play()

			Window.IsTransparent = Value
			Signal:Fire('UnloadTextbox', Value)
		end
	end
	
	return Window
end

return Module
