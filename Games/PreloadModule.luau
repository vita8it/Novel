local Packages = ...

local _ENV = (getgenv or getrenv or getfenv)()

local HIDDEN_SETTINGS = Packages.HIDDEN_SETTINGS

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterGui = game:GetService('StarterGui')
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local Map = workspace:WaitForChild("Map")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Effect = ReplicatedStorage:WaitForChild('Effect')

local GunValidator = Remotes:WaitForChild("Validator2")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild('CommE')

local Net = Modules:WaitForChild("Net")

local Player = Players.LocalPlayer
local Settings = Packages.Settings
local Module = Packages.Module
local Cached = Packages.Cached
local Utils = Packages.Utils

local AssetModule = Utils.AssetModule
local GoodQueue = Utils.GoodQueue
local Plugins = Utils.Plugins

local Options = GoodQueue.Build() do
	local RunFunctions = Module.__RunFunctions

	local PlayerManager = Module.PlayerManager
	local EnemiesModule = Module.EnemiesModule
	local SkillManager = Module.SkillManager
	local HookManager = Module.HookManager

	function Module:FastOption(Flag, Interval, ...)
		local Args = { ... }
		Options:NewOption(Flag, function()
			return RunFunctions[ Flag ](unpack(Args))
		end, Interval or 0.1) 
	end

	function Module:FastQueue(Flag, ...)
		local Args = { ... }
		Options:NewOption(Flag, function()
			return RunFunctions[ Flag ](function()
				return not Settings[ Flag ]
			end, unpack(Args))
		end) 
	end

	-- ([[ < Not Queue > ]])
	Module:FastOption('Death Aura', 0, 300)
	Module:FastOption('Activated V3', 5)
	Module:FastOption('Activated V4', 1)
	Module:FastOption('Upgrade Stats', 1)
	Module:FastOption('Random Surprise', 0.25)
	Module:FastOption('Random Fruit', 5)
	Module:FastOption('Store Fruit', 0.5)
	Module:FastOption('Unstore Fruit', 1)
	Module:FastOption('Buy Skill', 1)
	Module:FastOption('Enabled Unbreakable', 0)
	Module:FastOption('Enabled Pvp', 5)
	Module:FastOption('Kitsune Trade Items', 0.3)
	Module:FastOption('Buy Haki Dealers', 1)
	Module:FastOption('Buy Legendary Sword', 1)
	Module:FastOption('Spooky Gacha', 5)
	Module:FastOption('Auto Sell Fish', 5)
	Module:FastOption('Auto Buy Bait', 1)

	-- ([[ < High Layers > ]])
	Module:FastQueue('Dojo Trainer')
	Module:FastQueue('Dragon Hunter') do
		HookManager:Import('Dragon Hunter')
	end

	Module:FastQueue('Clear Dungeon')

	Module:FastQueue('Auto Fishing')
	Module:FastQueue("Complete Trial") do
		HookManager:Import('Complete Trial')
	end

	Module:FastQueue("Acient One Quest")
	Module:FastQueue("Travel to Door [ RACE ]")
	Module:FastQueue("Unlock Race V4")

	Module:FastQueue("Clear Raid", "Select Raid")
	Module:FastQueue("Travel to Lab")

	Module:FastQueue("Farm Law")
	Module:FastQueue("Cyborg Quest")

	Module:FastQueue("Race II Quest")
	Module:FastQueue("Race III Quest") do
		HookManager:Import('Race III Quest')
	end

	Module:FastQueue("Third Sea")
	Module:FastQueue("Second Sea")
	Module:FastQueue("Bartilo Quest")

	Module:FastQueue("Nearest")
	Module:FastQueue("Travel Island", "Select Island")

	Module:FastQueue("Cursed Dual Katana")
	Module:FastQueue("Midnight Blade")
	Module:FastQueue("Tushita")
	Module:FastQueue("Yama")

	Module:FastQueue("Defeat Leviathan")
	Module:FastQueue("Travel High Position")
	Module:FastQueue("Travel Advanced Dealer")

	Module:FastQueue('Farm Sea Event', "Select Enemies", "Farm Sea Event") do
		Module:FastQueue("Drive a Ship", "Select Zone", "Select Ship")

		Module:FastQueue("Open Mirage")
		Module:FastQueue("Open Shrine")
		Module:FastQueue("Open Frozen")
		Module:FastQueue("Open Prehistoric")

		HookManager:Import('Farm Sea Event')
		HookManager:Import('Open Prehistoric')
		HookManager:Import('Defeat Leviathan')
	end

	-- ([[ < Queue Layers > ]])
	Module:FastQueue("Farm Darkbeard")
	Module:FastQueue("Farm Rip Indra")
	Module:FastQueue("Destroy Factory")
	Module:FastQueue("Pirate Raid")

	Module:FastQueue("Hellfire Gas")
	Module:FastQueue("Great Pumpkin")
	Module:FastQueue("Trick or Treat")
	Module:FastQueue("Farm Pumpkin")

	Module:FastQueue("Farm Elite")
	Module:FastQueue("Farm Boss", "Select Bosses")

	Module:FastQueue("Ghoul Quest")
	Module:FastQueue("Collect Fruit")

	Module:FastQueue("Farm Berry")
	Module:FastQueue("Farm Chest")

	-- ([[ < Lower Layers > ]])
	Module:FastQueue('Sanguine Art')
	Module:FastQueue('Godhuman')
	Module:FastQueue('Dragon Talon')
	Module:FastQueue('Electric Claw')
	Module:FastQueue('Sharkman Karate')
	Module:FastQueue('Death Step')
	Module:FastQueue('Superhuman')
	Module:FastQueue('Electro')

	Module:FastQueue("Farm Mastery") do
		HookManager:Import('Farm Mastery')
	end

	Module:FastQueue("Farm Material", "Select Material")
	Module:FastQueue("Farm Cake Prince")

	Module:FastQueue("Farm Soul Reaper")
	Module:FastQueue("Farm Ectoplasm")
	Module:FastQueue("Farm Bones")

	Module:FastQueue('Tyrant Skies') do
		HookManager:Import('Tyrant Skies')
	end

	Module:FastQueue('Level') do
		HookManager:Import('Level')
	end
end

task.spawn(function()
	local ServerManager = Module.ServerManager
	local QuestModule = Module.QuestModule
	local DataModule = Module.DataModule
	local GameInfo = Module.GameInfo

	local MaterialNames = DataModule.__get('MaterialNames')
	local IslandNames = DataModule.__get('IslandNames')
	local BosseNames = QuestModule:GetAllBossNames()

	local Window = Plugins:Window(Options) do
		Plugins:Community() 
	end

	local Controllers = Plugins:MakeTab({
		Plugins.Add("Controllers", "การควบคุม"),
		Color3.fromRGB(255, 255, 255),
		106205298246017
	}) do
		Plugins:MakeBanner(Controllers, {
			"Controllers", 102942690288169, 130
		})

		Controllers:Section(Plugins.Add("Servers", 'เซิร์ฟเวอร์')) do
			Cached.TextLabels['Server Uptime'] = Plugins:TextLabel(Controllers, {
				Plugins.Add("Server Uptime", "เวลาเปิดเซิร์ฟเวอร์"),
				Plugins.Add("Displays how long the server has been running.", "แสดงระยะเวลาที่เซิร์ฟเวอร์เริ่มต้น"),
				89035384177367
			}, "00:00:00") 
		end

		Controllers:Section(Plugins.Add("Farming", "การฟาร์ม")) do 
			Settings['Fast Attack'] = true

			Plugins:Default("Select Weapon", "Melee")
			Plugins:Default("Travel Velocity", 150)

			Plugins:Dropdown(Controllers, {
				Plugins.Add("Select Weapon", "เลือกอาวุธ"),
				99199363807265
			}, HIDDEN_SETTINGS.TOOLS, "Select Weapon")

			Plugins:Toggle(Controllers, {
				Plugins.Add("Fast Attack", "โจมตีอย่างรวดเร็ว"),
				Plugins.Add("Enabled fast attack all weapon.", "เปิดใช้งานการโจมตีอย่างรวดเร็วสำหรับอาวุธทุกชนิด"),
				115187682954150
			}, "Fast Attack")

			Plugins:Toggle(Controllers, {
				Plugins.Add("Ignore Players", "ไม่สนใจผู้เล่น"),
				Plugins.Add("Prevent attacking other players.", "ป้องกันไม่ให้โจมตีผู้เล่นคนอื่น"),
				131047339765356
			}, "Players Filter")

			Plugins:Slider(Controllers, {
				Plugins.Add("Travel Velocity", "ความเร็วการเดินทาง"),
				Plugins.Add("Adjust travel velocity.", "ปรับแต่งค่าความเร็วการเดินทาง"),
				72695820718432
			}, { 100, 300, 0 }, "Travel Velocity")
		end

		Controllers:Section(Plugins.Add("Pulling", "การดึงศัตรู")) do 
			Plugins:Default("Enabled Bring", true)
			Plugins:Default("Bring Distance", 220)

			Plugins:Toggle(Controllers, {
				Plugins.Add("Pulls Enemies", "ดึงศัตรู"),
				Plugins.Add("Pulls nearby enemies toward you.", "ดึงศัตรูทั้งหมดที่อยู่ในระยะเข้าหาตัวเอง"),
				128222685814268
			}, "Enabled Bring")

			Plugins:Slider(Controllers, {
				Plugins.Add("Pull Range", "ระยะการดึง"),
				Plugins.Add("Adjust pull enemies range.", "ปรับแต่งระยะการดึงศัตรู"),
				138728743107015
			}, { 100, 350, 0 }, "Bring Distance")
		end

		Controllers:Section(Plugins.Add("Distance", "ระยะห่าง")) do 
			Plugins:Default("Melee Axis Distance", 25)
			Plugins:Default("Gun Axis Distance", 50)
			Plugins:Default("Fruit Axis Distance", 15)

			Plugins:Slider(Controllers, {
				Plugins.Add("Melee", "ระยะประชิด"),
				Plugins.Add("Adjust farming distance when using melee.", "ปรับระยะห่างในการฟาร์มจากด้านบนเมื่อใช้อาวุธโจมตีระยะประชิด"),
				106980798153392
			}, { 5, 50, 0 }, "Melee Axis Distance")

			Plugins:Slider(Controllers, {
				Plugins.Add("Gun", "ปืน"),
				Plugins.Add("Adjust farming distance when using gun.", "ปรับระยะห่างในการฟาร์มจากด้านบนเมื่อใช้อาวุธปืน"),
				131151646821198
			}, { 5, 200, 0 }, "Gun Axis Distance")

			Plugins:Slider(Controllers, {
				Plugins.Add("Blox Fruit", "ผลปีศาจ"),
				Plugins.Add("Adjust farming distance when using blox fruit.", "ปรับระยะห่างในการฟาร์มจากด้านบนเมื่อใช้พลังผลปีศาจ"),
				122308930322531
			}, { 5, 50, 0 }, "Fruit Axis Distance")
		end

		Controllers:Section(Plugins.Add("Visualizer", "การมองเห็น")) do
			Plugins:Default('Select Object', { HIDDEN_SETTINGS.VISUAL_LIST[1] })

			Plugins:Dropdown(Controllers, {
				Plugins.Add("Select Object", "เลือกวัตถุ"),
				138509832369309
			}, HIDDEN_SETTINGS.VISUAL_LIST, "Select Object", function(Value)
				Module.VisualManager.OnToggle(Settings['Name Visibility'], Value)
			end)

			Plugins:Toggle(Controllers, {
				Plugins.Add("Name Visibility", "แสดงชื่อวัตถุ"),
				Plugins.Add("Show the object name.", "แสดงชื่อของวัตถุ"),
				131837581673100
			}, 'Name Visibility', function(Value)
				Module.VisualManager.OnToggle(Value, Settings['Select Object'])
			end)

			Plugins:Toggle(Controllers, {
				Plugins.Add("Distance Indicator", "แสดงระยะห่าง"),
				Plugins.Add("Show the distance to object.", "แสดงระยะห่างไปยังวัตถุ"),
				128385985315493
			}, 'Distance Indicator')
		end

		Controllers:Section(Plugins.Add("Abilities", "ความสามารถ")) do
			Plugins:Toggle(Controllers, {
				Plugins.Add("Activated Race V3", "ออโต้เปิดเผ่า V3"),
				Plugins.Add("Automatically activates race V3.", "เปิดใช้เผ่า V3 โดยอัตโนมัติ"),
				110354272746916
			}, "Activated V3")

			Plugins:Toggle(Controllers, {
				Plugins.Add("Activated Race V4", "ออโต้เปิดเผ่า V4"),
				Plugins.Add("Automatically activates race V4.", "เปิดใช้เผ่า V4 โดยอัตโนมัติ"),
				89832410659011
			}, "Activated V4")
		end

		Controllers:Section(Plugins.Add("Others", "เพิ่มเติม")) do
			Plugins:Toggle(Controllers, {
				Plugins.Add("Disable Notifications", "ปิดการแจ้งเตือน"),
				Plugins.Add("Turns off game notifications such as EXP and money gains.", "ปิดการแจ้งเตือนในเกม เช่น ข้อความเงินที่ได้รับ"),
				85646968765632
			}, "Disable Notification", function(Value)
				PlayerGui.Notifications.Enabled = not Value
			end)

			Plugins:Toggle(Controllers, {
				Plugins.Add("Walk On Water", "เดินบนน้ำ"),
				Plugins.Add("Allowed you to walk one water.", "ผู้ใช้สามารถเดินบนน้ำได้"),
				124559525708854
			}, "Walk On Water", function(Value)
				WaterBasePlane.Size = Vector3.new(1000, Value and HIDDEN_SETTINGS.WATER_Y or 80, 1000)
			end)

			Plugins:Toggle(Controllers, {
				Plugins.Add("Disabled Effects", "ปิดเอฟเฟกต์"),
				Plugins.Add("Disabled all effects in the game.", "ปิดเอฟเฟกต์ทั้งหมดในเกม"),
				72205943386691
			}, "Disabled Effect")
		end
	end

	local Standards = Plugins:MakeTab({
		Plugins.Add("Standards", "มาตฐาน"),
		Color3.fromRGB(255, 255, 255),
		101784622859642
	}) do
		Plugins:MakeBanner(Standards, {
			"Standards", AssetModule:GetAssetByName('Standard')
		})

		Standards:Section(Plugins.Add("Leveling", "เลเวล")) do
			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Farm Level", "ออโต้ฟาร์มเลเวล"),
				Plugins.Add("Farm levels from 1 – 2800 || Update from game.", "ฟาร์มเลเวลตั้งแต่ 1 – 2800 || อัปเดตตามเลเวลสูงสุดของเกม"),
				90744681472260
			}, "Level")

			Plugins:Button(Standards, {
				Plugins.Add("Redeem Codes", "แลกโค้ด"),
				Plugins.Add("Lets a player redeem all actived codes.", "แลกโค้ดที่ใช้งานได้ทั้งหมด"),
				88903930207158
			}, function()
				task.spawn(function()
					for _, Code in DataModule.__get('Codes') do
						Remotes.Redeem:InvokeServer(Code)
					end
				end)
			end)
		end

		Standards:Section(Plugins.Add("Stories", "สตอรี่")) do
			Settings['Second Sea'] = false
			Settings['Third Sea'] = false

			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Second Sea", "ออโต้ไปโลกสอง"),
				Plugins.Add("Complete second sea quest.", "ออโต้ทำเควสไปโลกสอง"),
				132409462620188
			}, "Second Sea")

			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Third Sea", "ออโต้ไปโลกสาม"),
				Plugins.Add("Complete third sea quest.", "ออโต้ทำเควสไปโลกสาม"),
				85144748886419
			}, "Third Sea")

			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Bartilo Quest", "ออโต้เควสบาโทโรมิโอ"),
				Plugins.Add("Complete bartilo quest and unlock ZQuest.", "ออโต้ทำเควสบาโทโรมิโอเพื่อ ปลดล็อคเควสไปโลกสาม"),
				110354272746916
			}, "Bartilo Quest")
		end

		Standards:Section(Plugins.Add("Stats", "ค่าพลัง")) do
			Plugins:Default("Select Stats", { "Melee" })

			Plugins:Dropdown(Standards, {
				Plugins.Add("Select Stats", "เลือกค่าพลัง"),
				125949254729936
			}, HIDDEN_SETTINGS.STATS_UPGRADE, "Select Stats")

			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Upgrade Stats", "ออโต้อัพค่าพลัง"),
				Plugins.Add("Automatically upgrades stats as you level up.", "อัพค่าพลังของผู้ใช้โดยอัตโนมัติเมื่อเลเวลเพิ่มขึ้น"),
				124447084147678
			}, "Upgrade Stats")

			Plugins:Button(Standards, {
				Plugins.Add("Refund Stats", "รีเซ็ตค่าพลัง"),
				Plugins.Add("Lets a player reset and reallocate their stat points.", "รีเซ็ตค่าพลังของผู้ใช้ให้เป็นศุนย์"),
				91396967371078
			}, function()
				Module:ComF("BlackbeardReward", "Refund", "2")
			end)

			Plugins:Button(Standards, {
				Plugins.Add("Race Reroll", "สุ่มเผ่าพันธุ์"),
				Plugins.Add("Lets a player randomly change their current race.", "สุ่มเปลี่ยนเผ่าพันธุ์ปัจจุบัน"),
				88831180897487
			}, function()
				Module:ComF("BlackbeardReward", "Reroll", "2")
			end)
		end

		Standards:Section(Plugins.Add("Enemies", "ศัตรู")) do
			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Farm Nearest", "ออโต้ฟาร์มศัตรูรอบตัว"),
				Plugins.Add("Farm nearest enemies in 1000 m.", "ฟาร์มศัตรูรอบตัวที่อยู่ในระยะ 1000 m"),
				124620021946523
			}, "Nearest")

			Plugins:Toggle(Standards, {
				Plugins.Add("Death Aura", "ออร่าแห่งความตาย"),
				Plugins.Add("Instant kill nearest enemies in 300 m.", "สังหารศัตรูที่ใกล้ที่สุดในระยะ 300 m ในชั่วพริบตา"),
				107548730556070
			}, "Death Aura")
		end

		Standards:Section(Plugins.Add("Bosses", "บอส")) do
			Plugins:Default("Accept Quest", true)
			Plugins:Default("Select Bosses", { BosseNames[1], BosseNames[2] })

			Plugins:Dropdown(Standards, {
				Plugins.Add("Select Bosses", "เลือกบอส"),
				137977318801190
			}, BosseNames, "Select Bosses")

			Plugins:Toggle(Standards, {
				Plugins.Add("Auto Farm Boss", "ออโต้ฟาร์มบอส"),
				Plugins.Add("Farms the target bosses when it spawns.", "ฟาร์มบอสที่เลือกทั้งหมด"),
				128445021580075
			}, "Farm Boss")

			Plugins:Toggle(Standards, {
				Plugins.Add("Accept Quest", "รับเควสบอส"),
				Plugins.Add("Accept boss quest before farming.", "รับเควสบอสก่อนฟาร์ม"),
				109404150132067
			}, "Accept Quest")
		end
	end

	local Mastery = Plugins:MakeTab({
		Plugins.Add("Mastery", "ความเชี่ยวชาญ"),
		Color3.fromRGB(255, 255, 255),
		75684988221384
	}) do
		Plugins:MakeBanner(Mastery, {
			"Mastery", AssetModule:GetAssetByName('Mastery')
		})

		Mastery:Section(Plugins.Add("Grinding", 'ความเชี่ยวชาญ')) do
			Plugins:Default("Select Mastery Weapon", "Blox Fruit")
			Plugins:Default("Select Mastery Skill", { "Z", "X" })
			Plugins:Default("Select Enemies Group", "Level")
			Plugins:Default("Mastery Health Threshold", 25)

			Plugins:Slider(Mastery, {
				Plugins.Add("Health Threshold", "เกณฑ์เลือด"),
				Plugins.Add("Kill after target health lower than threshold.", "สังหารเมื่อเลือดเป้าหมายต่ำกว่าเกณฑ์"),
				119594100509168
			}, { 5, 100, 1 }, "Mastery Health Threshold")

			Plugins:Dropdown(Mastery, {
				Plugins.Add("Select Mastery Skill", "เลือกสกิล"),
				89540163684599
			}, { "Z", "X", "C", "V", "F" }, "Select Mastery Skill")

			Plugins:Dropdown(Mastery, {
				Plugins.Add("Select Enemies Group", "เลือกกลุ่มศัตรู"),
				128445021580075
			}, { "Bones", "Tiki", "Level" }, "Select Enemies Group")

			Plugins:Dropdown(Mastery, {
				Plugins.Add("Select Mastery Weapon", "เลือกอาวุธ"),
				99199363807265
			}, HIDDEN_SETTINGS.TOOLS, "Select Mastery Weapon")

			Plugins:Toggle(Mastery, {
				Plugins.Add("Auto Farm Mastery", "ออโต้ฟาร์มมาสเตอรี่"),
				Plugins.Add("Grinding the mastery of select weapon.", "เก็บเกี่ยวความเชี่ยวชาญของอาวุธที่เลือก"),
				75684988221384
			}, 'Farm Mastery')
		end
	end

	local Hunters = Plugins:MakeTab({
		Plugins.Add("Hunters", "การล่าค่าหัว"),
		Color3.fromRGB(255, 255, 255),
		99199363807265
	}) do
		Plugins:MakeBanner(Hunters, {
			"Hunter", AssetModule:GetAssetByName('Hunter')
		})

		Hunters:Section(Plugins.Add("Aimbot", "ระบบช่วยเล็ง")) do
			Plugins:Default("Targets Filter", { "Players" })
			Plugins:Default("Detect Angle", "180°")
			Plugins:Default("Detect Range", 750)

			Plugins:Toggle(Hunters, {
				Plugins.Add("Silent Skill", "เล็งสกิลอัตโนมัติ"),
				Plugins.Add("Automatically aim skills at the nearest target.", "เล็งสกิลไปยังเป้าหมายที่ใกล้ที่สุดโดยอัตโนมัติ"),
				124563301518789
			}, "Silent Skill")

			Plugins:Dropdown(Hunters, {
				Plugins.Add("Targets Filter", "ประเภทเป้าหมาย"),
				139791530843118
			}, { "Players", "Monsters" }, "Targets Filter")

			Plugins:Dropdown(Hunters, {
				Plugins.Add("Detect Angle", "มุมการตรวจจับ"),
				75671092280513
			}, { "180°", "360°" }, "Detect Angle")

			Plugins:Slider(Hunters, {
				Plugins.Add("Detect Range", "ระยะการตรวจจับ"),
				Plugins.Add("Adjust the range for detecting targets.", "ปรับระยะสำหรับตรวจจับเป้าหมาย"),
				112105283657248
			}, { 100, 1000, 0 }, "Detect Range")
		end

		Hunters:Section(Plugins.Add("Visual", "การมองเห็น")) do
			Plugins:Toggle(Hunters, {
				Plugins.Add("Line Target", "เส้นแสดงเป้าหมาย"),
				Plugins.Add("Draw a line pointing toward the target.", "แสดงเส้นสีแดงชี้ไปยังเป้าหมาย"),
				86228494730662
			}, "Line Target")

			Plugins:Toggle(Hunters, {
				Plugins.Add("Box Target", "กรอบเป้าหมาย"),
				Plugins.Add("Draw a red box around the locked target.", "แสดงกรอบสีแดงรอบเป้าหมายที่ถูกล็อค"),
				100791768133731
			}, "Box Target")
		end

		Hunters:Section(Plugins.Add("Client", "ผู้เล่น")) do
			Plugins:Default("Player Velocity", 10)
			Plugins:Default("Jump Power", 50)

			Plugins:Slider(Hunters, {
				Plugins.Add("Player Velocity", "ความเร็วผู้เล่น"),
				Plugins.Add("Adjust the player's movement velocity.", "ปรับความเร็วในการเคลื่อนที่ของผู้เล่น"),
				73652062010077
			}, { 1, 20, 0 }, "Player Velocity")

			Plugins:Slider(Hunters, {
				Plugins.Add("Jump Power", "พลังการกระโดด"),
				Plugins.Add("Adjust the player's jump power.", "ปรับพลังการกระโดดของผู้เล่น"),
				104647642415801
			}, { 50, 300, 0 }, "Jump Power")

			Plugins:Toggle(Hunters, {
				Plugins.Add("Enabled Velocity", "เปิดใช้งานความเร็ว"),
				Plugins.Add("Enable or disable player velocity modification.", "เปิดหรือปิดการปรับความเร็วในการเคลื่อนที่ของผู้เล่น"),
				85529287041825
			}, "Enabled Velocity", function(Value)
				Module.HunterService:SetSpeed(Value)
			end)

			Plugins:Toggle(Hunters, {
				Plugins.Add("Enabled Jump Power", "เปิดใช้งานพลังกระโดด"),
				Plugins.Add("Enable or disable jump power modification.", "เปิดหรือปิดการปรับพลังการกระโดดของผู้เล่น"),
				109377136928158
			}, "Enabled Jump Power", function(Value)
				Module.HunterService:SetJump(Value)
			end)
		end

		Hunters:Section(Plugins.Add("Special", "ฟังก์ชันพิเศษ")) do
			Plugins:Toggle(Hunters, {
				Plugins.Add("Enabled Unbreakable", "เปิดใช้งานป้องกันสกิลถูกยกเลิก"),
				Plugins.Add("Prevent your skills from being interrupted when taking damage.", "ป้องกันสกิลถูกยกเลิกเมื่อได้รับความเสียหาย"),
				99391808337829
			}, "Enabled Unbreakable")

			Plugins:Toggle(Hunters, {
				Plugins.Add("Silent Flashstep", "โซรุล็อคเป้าหมาย"),
				Plugins.Add("Flashstep will teleport to the closest target.", "โซรุจะวาร์ปไปหาเป้าหมายที่ใกล้ที่สุด"),
				85674802634571
			}, "Soru Target")

			Plugins:Toggle(Hunters, {
				Plugins.Add("Auto Enabled Pvp", "ออโต้เปิดโหมด PvP"),
				Plugins.Add("Auto enable pvp combat.", "เปิดใช้งานการต่อสู้ระหว่างผู้เล่นอัตโนมัติ"),
				73349792670294
			}, "Enabled Pvp")
		end
	end

	local Items = Plugins:MakeTab({
		Plugins.Add("Items", "ไอเท็ม"),
		Color3.fromRGB(255, 255, 255),
		138222466511351
	}) do
		Plugins:MakeBanner(Items, {
			"Items", 100041896541168, 150
		})

		Items:Section(Plugins.Add("Fruit Shop", "ร้านค้าผลไม้ปีศาจ")) do
			Cached.TextLabels['Devil Fruit'] = Plugins:TextLabel(Items, {
				Plugins.Add("Devil Fruit", "ผลไม้ปีศาจ"),
				Plugins.Add("Indicate the countdown until the player can roll a Devil Fruit.", "แสดงเวลานับถอยหลังจนกว่าผู้เล่นจะสามารถสุ่มผลไม้ปีศาจได้"),
				97093610797523
			}, "N/A")

			Plugins:Button(Items, {
				Plugins.Add("Random Fruit", "ไม้ปีศาจ"),
				Plugins.Add("Lets a player randomly devil fruits.", "กดเพื่อสุ่มผลไม้ปีศาจทันที"),
				118276622427805
			}, function()
				Net["RF/GachaNetworkRF"]:InvokeServer({
					Context = "Purchase",
					BoxName = "ZiolesGacha"
				})
			end)

			Plugins:Button(Items, {
				Plugins.Add("Normal Stock", "สต็อกปกติ"),
				Plugins.Add("Lets a player open devil fruits shop.", "เปิดร้านผลปีศาจแบบปกติ"),
				128138009595555
			}, function()
				Module.OpenStock()
			end)

			Plugins:Button(Items, {
				Plugins.Add("Advanced Stock", "สต็อกพิเศษ"),
				Plugins.Add("Lets a player open devil fruits shop.", "เปิดร้านผลปีศาจของเกาะลับ"),
				127465846320593
			}, function()
				Module.OpenStock(true)
			end)
		end

		Items:Section(Plugins.Add("Devil Fruit", "ผลไม้ปีศาจ")) do
			Plugins:Toggle(Items, {
				Plugins.Add("Auto Collect Fruit", "ออโต้เก็บผลไม้ปีศาจ"),
				Plugins.Add("Collect all devil fruit in the game.", "เก็บผลไม้ปีศาจทั้งหมดภายในเกม"),
				122308930322531
			}, "Collect Fruit")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Store Fruit", "ออโต้เก็บผลไม้ปีศาจเข้ากล่อง"),
				Plugins.Add("Stored all devil fruit to inventory.", "เก็บผลไม้ปีศาจทั้งหมดที่มีเข้ากล่อง ถ้าผลเต็มจะไม่เก็บ"),
				109382772184214
			}, "Store Fruit")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Random Fruit", "ออโต้สุ่มผลไม้ปีศาจ"),
				Plugins.Add("Lets a player randomly devil fruits every 2 hours.", "สุ่มผลไม้ปีศาจอัตโนมัติในทุกๆ 2 ชั่วโมง"),
				131466952075959
			}, "Random Fruit")
		end

		Items:Section(Plugins.Add("Collectable", "การเก็บของ")) do
			Plugins:Toggle(Items, {
				Plugins.Add("Auto Farm Chest", "ออโต้ฟาร์มกล่อง"),
				Plugins.Add("Collect all chest in the game.", "เก็บกล่องทั้งหมดภายในเกม"),
				124280643854087
			}, "Farm Chest")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Farm Berry", "ออโต้ฟาร์มผลเบอร์รี่"),
				Plugins.Add("Collect all berry in the game.", "เก็บผลเบอร์รี่ทั้งหมดภายในเกม"),
				113299220848937
			}, "Farm Berry")
		end

		Items:Section(Plugins.Add("Bones", "กระดูก")) do
			Cached.TextLabels['Bones'] = Plugins:TextLabel(Items, {
				Plugins.Add("Bones", "กระดูก"),
				Plugins.Add("Indicate the number of bones the player has.", "แสดงจำนวนกระดูกที่ผู้เล่นมีอยู่"),
				101435689894494
			}, "N/A")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Farm Bones", "ออโต้ฟาร์มกระดูก"),
				Plugins.Add("Farm enemies in haunted castle.", "ฟาร์มศัตรูทั้งหมดในประสาทผีสิง"),
				121397832880333
			}, "Farm Bones")

			Plugins:Toggle(Items, {
				Plugins.Add("Random Surprise", "สุ่มของรางวัล"),
				Plugins.Add("Use 50 bones to get a random reward.", "ใช้กระดูก 50 อัน เพื่อสุ่มของรางวัล"),
				119594100509168
			}, "Random Surprise")
		end

		Items:Section(Plugins.Add("Ectoplasm", "สสารลึกลับ")) do
			Cached.TextLabels['Ectoplasm'] = Plugins:TextLabel(Items, {
				Plugins.Add("Ectoplasm", "สสารลึกลับ"),
				Plugins.Add("Indicate the number of ectoplasm the player has.", "แสดงจำนวนสสารลึกลับที่ผู้เล่นมีอยู่"),
				101435689894494
			}, "N/A")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Farm Ectoplasm", "ออโต้ฟาร์มสสารลึกลับ"),
				Plugins.Add("Farm enemies in haunted ship.", "ฟาร์มศัตรูในเรือผี"),
				121397832880333
			}, "Farm Ectoplasm")
		end

		Items:Section(Plugins.Add("Materials", "วัตถุดิบ")) do
			Plugins:Default('Select Material', MaterialNames[1])

			Plugins:Dropdown(Items, {
				Plugins.Add("Select Material", "วัตถุดิบ"),
				128042328338966
			}, MaterialNames, "Select Material")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Farm Material", "ออโต้ฟาร์มวัตถุดิบ"),
				Plugins.Add("Farm enemies taht drop select material.", "ฟาร์มศัตรูที่ดรอปวัตถุดิบ"),
				82593752006757
			}, "Farm Material")
		end

		Items:Section(Plugins.Add("Dealers", "ร้านค้าลึกลับ")) do
			Plugins:Toggle(Items, {
				Plugins.Add("Buy Legendary Sword", "ออโต้ซื้อสามดาบ"),
				Plugins.Add("Automatic buys 3 legendary sword.", "ซื้อสามดาบในตำนานโดยอัตโนมัติ"),
				88742805058563
			}, "Buy Legendary Sword")

			Plugins:Toggle(Items, {
				Plugins.Add("Buy Haki Colors", "ออโต้ซื้อสีฮาคิ"),
				Plugins.Add("Automatic buy all haki dealer.", "ซื้อสีฮาคิที่ขายอยุ่อัตโนมัติ"),
				140462335976396
			}, "Buy Haki Dealers")
		end

		Items:Section(Plugins.Add("Fishing", "การตกปลา")) do
			Plugins:Default('Fishing Process', 95)

			Plugins:Slider(Items, {
				Plugins.Add("Cast Power", "พลังการเหวี่ยงเบ็ด"),
				Plugins.Add("Adjust the casting power percentage.", "ปรับระดับพลังการเหวี่ยงเบ็ดเป็นเปอร์เซ็นต์"),
				134209783050231
			}, {10, 100, 0}, "Fishing Process")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Fishing", "ออโต้ตกปลา"),
				Plugins.Add("Automatic cast rod, play reeling minigame.", "ออโต้โยนเบ็ดลงน้ำและเล่นมินิเกมตกปลา"),
				85878285383695
			}, "Auto Fishing")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Buy Bait", "ออโต้ซื้อเหยื่อ"),
				Plugins.Add("Automatic buy basic bait.", "ซื้อเหยื่อตกปลาระดับกากอัตโนมัติ"),
				73149838418422
			}, "Auto Buy Bait")

			Plugins:Toggle(Items, {
				Plugins.Add("Auto Sell Fish", "ออโต้ขายปลา"),
				Plugins.Add("Automatic sell all fish.", "ขายปลาทั้งหมดอันโตมัติ"),
				78135879158899
			}, "Auto Sell Fish")
		end
	end

	local Tasks = Plugins:MakeTab({
		Plugins.Add("Tasks", "ภารกิจ"),
		Color3.fromRGB(255, 255, 255),
		70987453123239
	}) do
		Plugins:MakeBanner(Tasks, {
			"Tasks", AssetModule:GetAssetByName('Task')
		})

		Tasks:Section(Plugins.Add("Pirate Raid", "โจรสลัดบุก")) do
			Cached.TextLabels['Pirate Raid'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Pirate Raid", "โจรสลัดบุก"),
				Plugins.Add("Show pirate raid status and time until next raid.", "แสดงสถานะและเวลาที่เหลือก่อนโจรสลัดบุกครั้งถัดไป"),
				129482599094151
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Pirate Raid", "ออโต้โจรสลัดบุก"),
				Plugins.Add("Clear pirate raid spawn every 1 hour 15 mins.", "กำจัดโจรสลัดบุกที่เกาะกลางทะเล เกิดทุกๆ 1 ชั่วโมง 30 นาที"),
				99225867963798
			}, "Pirate Raid")
		end

		Tasks:Section(Plugins.Add("Factory", "เหตการณ์")) do
			Cached.TextLabels['Factory'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Factory", "โรงงาน"),
				Plugins.Add("Show factory status and time until next factory.", "แสดงสถานะและเวลาที่เหลือก่อนโรงงานเปิดครั้งถัดไป"),
				133514583225306
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Destroy Factory", "ออโต้ทำลายโรงงาน"),
				Plugins.Add("Destroy factory spawn every 1 hour 30 minutes.", "ทำลายโรงงานที่เกิดทุกๆ 1 ชั่วโมง 30 นาที"),
				136617830785023
			}, "Destroy Factory")
		end

		Tasks:Section(Plugins.Add("Elite", "อีลิท")) do
			Cached.TextLabels['Elite'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Elite", "อีลิท"),
				Plugins.Add("Indicate elite's alive status.", "แสดงสถานะการมีชีวิตอยู่ของอีลิท"),
				93958516335421
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Farm Elite", "ออโต้ฟาร์มอีลิท"),
				Plugins.Add("Get quest and kill elite.", "รับภารกิจและสังหารอีลิทอัตโนมัติ"),
				139791530843118
			}, "Farm Elite")
		end

		Tasks:Section(Plugins.Add("Dojo", "โดโจ")) do
			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Dojo Trainer", "ออโต้ทำภารกิจโดโจ"),
				Plugins.Add("Complete belt white, yellow, green, purple, red, black.", "ทำภารกิจเทรนเนอร์ ขาว เหลือง เขียว ม่วง แดง ดำ"),
			}, "Dojo Trainer")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Dragon Hunter", "ออโต้ทำภารกิจนักล่ามังกร"),
				Plugins.Add("Complete dragon hunter blaze ember quest.", "ทำภารกิจของเก็บลูกไฟของนักล่ามังกร"),
			}, "Dragon Hunter")
		end

		Tasks:Section(Plugins.Add("Rip Indra", "บอสแอดมิน")) do
			Cached.TextLabels['Rip Indra'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Rip Indra", "บอสแอดมิน"),
				Plugins.Add("Indicate rip indra's alive status.", "แสดงสถานะการมีชีวิตอยู่ของบอสแอดมิน"),
				100189393807285
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Farm Rip Indra", "ออโต้ฟาร์มบอสแอดมิน"),
				Plugins.Add("Farm Rip Indra only when it is spawned.", "ฟาร์มบอสแอดมิน หาถ้วย เสกบอส ฆ่าบอส"),
				88267918572119
			}, "Farm Rip Indra")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Skip God Chalice", "ข้ามการหาที่เสก"),
				Plugins.Add("Skip searching for God Chalice and wait for Rip Indra to spawn.", "ข้ามการค้นหาที่เสก และรอให้บอสแอดมินเกิดเท่านั้น"),
				85529287041825
			}, "Skip God Chalice")
		end

		Tasks:Section(Plugins.Add("Darkbeard", "หนวดำ")) do
			Cached.TextLabels['Darkbeard'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Darkbeard", "หนวดดำ"),
				Plugins.Add("Indicate darkbeard's alive status.", "แสดงสถานะการมีชีวิตอยู่ของหนวดำ"),
				95842914219662
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Farm Darkbeard", "ออโต้ฟาร์มหนวดดำ"),
				Plugins.Add("Find fist of darkness, spawn and kill darkbeard.", "หาที่เสก ทำการเสก ทำการฆ่าหนวดดำ"),
				139502853870457
			}, "Farm Darkbeard")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Skip Fist of Darkness", "ข้ามการหาที่เสก"),
				Plugins.Add("Skip searching for Fist of Darkness and wait for Darkbeard to spawn.", "ข้ามการค้นหาที่เสก และรอให้หนวดดำเกิดเท่านั้น"),
				85529287041825
			}, "Skip Fist of Darkness")
		end

		Tasks:Section(Plugins.Add("Cake Prince", "คาตาคุริ")) do
			Cached.TextLabels['Cake Prince'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Cake Prince", "คาตาคุริ"),
				Plugins.Add("Indicate cake prince's alive status.", "แสดงสถานะการมีชีวิตอยู่ของคาตาคุริ"),
				80516246798614
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Farm Cake Prince", "ออโต้ฟาร์มคาตาคุริ"),
				Plugins.Add("Farm enemies, spawn boss, kill Cake Prince.", "สังหารศัตรู ทำลายไห และกำจัดคาตาคุริอัตโนมัติ"),
				73139979429556
			}, "Farm Cake Prince")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Disabled Auto Spawn", "ปิดออโต้เสกคาตาคุริ"),
				Plugins.Add("When you disabled it, cake prince will not spawn automatic.", "ถ้าผู้ใช้เปิดฟังชั่นนี้จะทำให้สคริปต์ไม่เสกคาตาคุริแบบอัตโนมัติ"),
				132395726525059
			}, "Disabled Auto Spawn")
		end

		Tasks:Section(Plugins.Add("Tyrant Skies", "ทรราชแห่งท้องนภา")) do
			Cached.TextLabels['Tyrant Skies'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Tyrant of the Skies", "ทรราชแห่งท้องนภา"),
				Plugins.Add("Indicate tyrant of the skies's alive status.", "แสดงสถานะการมีชีวิตอยู่ของทรราชแห่งท้องนภา"),
				100791768133731
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Farm Tyrant of the Skies", "ออโต้ฟาร์มทรราชแห่งท้องนภา"),
				Plugins.Add("Farm enemies, destroy jars and kill tyrant of the skies.", "สังหารศัตรู ทำลายไห และกำจัดทรราชแห่งท้องนภาอัตโนมัติ"),
				111725000135913
			}, "Tyrant Skies")
		end

		Tasks:Section(Plugins.Add("Soul Reaper", "บอสเคียว")) do
			Cached.TextLabels['Soul Reaper'] = Plugins:TextLabel(Tasks, {
				Plugins.Add("Soul Reaper", "บอสเคียว"),
				Plugins.Add("Indicate soul reaper's alive status.", "แสดงสถานะการมีชีวิตอยู่ของบอสเคียว"),
				76747045648234
			}, "N/A")

			Plugins:Toggle(Tasks, {
				Plugins.Add("Auto Farm Soul Reaper", "ออโต้ฟาร์มบอสเคียว"),
				Plugins.Add("Farm bone, random surpire, spawn and kill soul reaper.", "ฟาร์มกระดูก สุ่มหาลูกไฟ ถ้าเจอจะทำการเสกและฆ่าบอสเคียว"),
				121397832880333
			}, "Farm Soul Reaper")
		end
	end

	local Equipment = Plugins:MakeTab({
		Plugins.Add("Equipment", "อุปกรณ์"),
		Color3.fromRGB(255, 255, 255),
		93200406372411
	}) do
		Plugins:MakeBanner(Equipment, {
			"Equipments", AssetModule:GetAssetByName('Equipment')
		})

		Equipment:Section(Plugins.Add("Sword", "ดาบ")) do
			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Cursed Katana", "ออโต้ทำดาบคู่"),
				Plugins.Add("Complete quest and unlock Cursed Dual Katana.", "ทำภารกิจปลดล็อคดาบคู่"),
			}, "Cursed Dual Katana") 

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Tushita", "ออโต้ทำทุชิตะ"),
				Plugins.Add("Complete quest and unlock Tushita.", "ทำภารกิจปลดล็อคทุชิตะ"),
			}, "Tushita")  

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Yama", "ออโต้ทำยามะ"),
				Plugins.Add("Complete quest and unlock Yama.", "ทำภารกิจปลดล็อคยามะ"),
			}, "Yama")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Midnight Blade", "ออโต้ทำมิดไนท์เบลด"),
				Plugins.Add("Complete quest and unlock Midnight Blade.", "ทำภารกิจปลดล็อคมิดไนท์เบลด"),
			}, "Midnight Blade")
		end

		Equipment:Section(Plugins.Add("Fighting Style", "สไตล์การต่อสู้")) do
			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Electro", "ออโต้หมัดสายฟ้า"),
				Plugins.Add("Complete quest and unlock Superhuman.", "ทำภารกิจปลดล็อคหมัดสายฟ้า"),
			}, "Electro")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Superhuman", "ออโต้หมัดซุป"),
				Plugins.Add("Complete quest and unlock Superhuman.", "ทำภารกิจปลดล็อคหมัดซุป"),
			}, "Superhuman")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Death Step", "ออโต้ขาไฟ"),
				Plugins.Add("Complete quest and unlock Death Step.", "ทำภารกิจปลดล็อคขาไฟ"),
			}, "Death Step")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Electric Claw", "ออโต้กรงเล็บสายฟ้า"),
				Plugins.Add("Complete quest and unlock Electric Claw.", "ทำภารกิจปลดล็อคกรงเล็บสายฟ้า"),
			}, "Electric Claw")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Dragon Talon", "ออโต้หมัดมังกร"),
				Plugins.Add("Complete quest and unlock Dragon Talon.", "ทำภารกิจปลดล็อคหมัดมังกร"),
			}, "Dragon Talon")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Sharkman Karate", "ออโต้หมัดมนุษย์เงือก"),
				Plugins.Add("Complete quest and unlock Sharkman Karate.", "ทำภารกิจปลดล็อคหมัดมนุษย์เงือก"),
			}, "Sharkman Karate")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Godhuman", "ออโต้หมัดก็อต"),
				Plugins.Add("Complete quest and unlock Godhuman.", "ทำภารกิจปลดล็อคหมัดก็อต"),
			}, "Godhuman")

			Plugins:Toggle(Equipment, {
				Plugins.Add("Auto Sanguine Art", "ออโต้หมัดแวมไพร์"),
				Plugins.Add("Complete quest and unlock Sanguine Art.", "ทำภารกิจปลดล็อคหมัดแวมไพร์"),
			}, "Sanguine Art")
		end
	end

	local Spacials = Plugins:MakeTab({
		Plugins.Add("Spacials", "พิเศษ"),
		Color3.fromRGB(255, 255, 255),
		118996986971457
	}) do
		Plugins:MakeBanner(Spacials, {
			"Specials", AssetModule:GetAssetByName('Specials')
		})

		Spacials:Section(Plugins.Add("Mirage Island", "เกาะลับ")) do
			Cached.TextLabels['Mirage Island'] = Plugins:TextLabel(Spacials, {
				Plugins.Add("Mirage Island", "เกาะลับ"),
				Plugins.Add("Show mirage island's current status.", "แสดงสถานะของเกาะลับในตอนนี้"),
				70616019606039
			}, "N/A")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Auto Mirage Island", "ออโต้หาเกาะลับ"),
				Plugins.Add("Buy ship, drive and find mirage island.", "ซื้อเรือและขับเรือหาเกาะลับ"),
				72936889032997
			}, "Open Mirage")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Travel Advance Dealer", "หาคนขายผลในเกาะ"),
				Plugins.Add("Travel to advance dealer in mirage island.", "เดินทางไปยังคนขายผลในเกาะลับ"),
				127465846320593
			}, "Travel Advanced Dealer")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Travel High Position", "เดินทางไปยังจุดสูงสุด"),
				Plugins.Add("Travel to high position in mirage island.", "เดินทางไปยังจุดสูงสุดในเกาะลับ"),
				84675860591128
			}, "Travel High Position")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Travel to Gear", "เดินทางไปยังฟันเฟือง"),
				Plugins.Add("Travel to gear in mirage island.", "เดินทางไปยังฟันเฟืองในเกาะลับ"),
				129748151876892
			}, "Travel Gear")
		end

		Spacials:Section(Plugins.Add("Kitsune Shrine", "เกาะคิสึเนะ")) do
			Cached.TextLabels['Kitsune Shrine'] = Plugins:TextLabel(Spacials, {
				Plugins.Add("Kitsune Shrine", "เกาะคิสึเนะ"),
				Plugins.Add("Show kitsune shrine's current status.", "แสดงสถานะของเกาะคิสึเนะในตอนนี้"),
				116121657056274
			}, "N/A")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Auto Kitsune Shrine", "ออโต้หาเกาะคิสึเนะ"),
				Plugins.Add("Buy ship, drive and find kitsune shrine.", "ซื้อเรือและขับเรือหาเกาะคิสึเนะ"),
				72936889032997
			}, "Open Shrine")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Auto Trade Items", "ออโต้แลกของ"),
				Plugins.Add("Trade items from kitsune shrine.", "แลกของจากเกาะคิสึเนะอัตโนมัติ"),
				73349792670294
			}, "Kitsune Trade Items")
		end

		Spacials:Section(Plugins.Add("Prehistoric Island", "เกาะภูเขาไฟ")) do
			Cached.TextLabels['Prehistoric Island'] = Plugins:TextLabel(Spacials, {
				Plugins.Add("Prehistoric Island", "เกาะภูเขาไฟ"),
				Plugins.Add("Show prehistoric island's current status.", "แสดงสถานะของเกาะภูเขาไฟในตอนนี้"),
				108433349941552
			}, "N/A")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Auto Prehistoric Island", "ออโต้หาเกาะภูเขาไฟ"),
				Plugins.Add("Buy ship, drive and find prehistoric island.", "ซื้อเรือและขับเรือหาเกาะภูเขาไฟ"),
				72936889032997
			}, "Open Prehistoric")
		end

		Spacials:Section(Plugins.Add("Leviathan Island", "เกาะลิเวียธาน")) do
			Cached.TextLabels['Leviathan Island'] = Plugins:TextLabel(Spacials, {
				Plugins.Add("Leviathan Island", "เกาะลิเวียธาน"),
				Plugins.Add("Show leviathan island's current status.", "แสดงสถานะของเกาะลิเวียธานในตอนนี้"),
				94751326384376
			}, "N/A")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Auto Leviathan Island", "ออโต้หาเกาะลิเวียธาน"),
				Plugins.Add("Buy ship, drive and find leviathan island.", "ซื้อเรือและขับเรือหาเกาะลิเวียธาน"),
				72936889032997
			}, "Open Frozen")

			Plugins:Toggle(Spacials, {
				Plugins.Add("Auto Defeat Leviathan", "ออโต้ตีลิเวียธาน"),
				Plugins.Add("Attack leviathan segment.", "โจมตีส่วนต่างๆของลิเวียธาน"),
				94212870836670
			}, "Defeat Leviathan")
		end
	end

	local Dungeons = Plugins:MakeTab({
		Plugins.Add("Dungeons", "ดันเจี้ยน"),
		Color3.fromRGB(255, 255, 255),
		100189393807285
	}) do
		Plugins:MakeBanner(Dungeons, {
			"Dungeons", AssetModule:GetAssetByName('Dungeon')
		})

		Dungeons:Section(Plugins.Add("Raiders", "ดันผลตื่น")) do
			Plugins:Default("Select Raid", GameInfo.RaidList[1])

			Plugins:Dropdown(Dungeons, {
				Plugins.Add("Select Raid", "เลือกดัน"),
				108818972048732
			}, GameInfo.RaidList, "Select Raid")

			Plugins:Toggle(Dungeons, {
				Plugins.Add("Auto Clear Raid", "ออโต้ลงดัน"),
				Plugins.Add("Buys the chip, starts raids and clears all enemies.", "ซื้อชิป เริ่มดันเจี้ยน กำจัดศัตรูทั้งหมด"),
				138187784140293
			}, "Clear Raid")

			Plugins:Toggle(Dungeons, {
				Plugins.Add("Auto Buy Skill", "ออโต้ซื้อสกิล"),
				Plugins.Add("Buys skill after end raids.", "ซื้อสกิลหลังจากจบดันเจี้ยน"),
				89540163684599
			}, 'Buy Skill')

			Plugins:Toggle(Dungeons, {
				Plugins.Add("Auto Unstore Fruit", "ออโต้เอาผลออก"),
				Plugins.Add("Unstore fruits that price lower than 1m.", "นำผลไม้ที่ราคาต่ำกว่า 1 ล้าน ออกจากกระเป๋า"),
				77471925416584
			}, 'Unstore Fruit')

			Plugins:Toggle(Dungeons, {
				Plugins.Add("Travel to Lab", "เดินทางไปแล็บ"),
				Plugins.Add("Travel to the Lab", "เดินทางไปยังห้องทดลอง"),
				133230946823703
			}, 'Travel to Lab')

			Plugins:Button(Dungeons, {
				Plugins.Add("Buy Chip", "ซื้อชิป"),
				Plugins.Add("Lets user buy select chip", "ซื้อชิปที่เลือก"),
				80223798831884
			}, function()
				Module:ComF("RaidsNpc", "Select", Settings['Select Dungeon'])
			end)
		end

		Dungeons:Section(Plugins.Add("Dungeons", "ดันเจี้ยน")) do
			Plugins:Toggle(Dungeons, {
				Plugins.Add("Auto Clear Dungeon", "ออโต้เคลียร์ดันเจี้ยน"),
				Plugins.Add("Clear dungeon enemies, boss, final 100 wave.", "เคลียร์ดันเจี้ยน ศัตรู บอส จนถึงด่านที่ 100"),
				128222685814268
			}, "Clear Dungeon")
		end

		Dungeons:Section(Plugins.Add("Orders", "บอสลอว์")) do
			Cached.TextLabels['Orders'] = Plugins:TextLabel(Dungeons, {
				Plugins.Add("Orders", "บอสลอว์"),
				Plugins.Add("Show orders's current status.", "แสดงสถานะของบอสลอว์ในตอนนี้"),
				130153784550753
			}, "N/A")

			Plugins:Toggle(Dungeons, {
				Plugins.Add("Auto Farm Law", "ออโต้ฟาร์มบอสลอว์"),
				Plugins.Add("Buy chip, start raid, kill boss.", "ซื้อชิปกดเริ่มแล้วทำการฆ่าบอสลอว์อัตโนมัติ"),
				77508665483937
			}, 'Farm Law')
		end
	end

	local Races = Plugins:MakeTab({
		Plugins.Add("Races", "เผ่าพันธ์"),
		Color3.fromRGB(255, 255, 255),
		88267918572119
	}) do
		Plugins:MakeBanner(Races, {
			"Race Awakening", 95977298986394, 70
		})

		Races:Section(Plugins.Add("Quest", "ภารกิจ")) do
			Cached.TextLabels['Moon Phase'] = Plugins:TextLabel(Races, {
				Plugins.Add("Moon Phase", "ดวงจันทร์"),
				Plugins.Add("Show moon's current status.", "แสดงสถานะของดวงจันทร์ในตอนนี้"),
				103796631744059
			}, "N/A")

			Plugins:Toggle(Races, {
				Plugins.Add("Auto Unlock Race V4", "ออโต้ปลดล็อคเผ่า V4"),
				Plugins.Add("Find mirage, look moon, collect gear in mirage and open door.", "หาเกาะลับ มองดวงจันทร์ หาฟันเฟืองและเปิดประตู"),
				83362499956496
			}, 'Unlock Race V4')
		end

		Races:Section(Plugins.Add("Trials", "บททดสอบ")) do
			Cached.TextLabels['Player Race'] = Plugins:TextLabel(Races, {
				Plugins.Add("Race", "เผ่าพันธ์"),
				Plugins.Add("Show user's current race status.", "แสดงสถานะเผ่าพันธ์ของผู้ใช้ในตอนนี้"),
				128992215676684
			}, "N/A")

			Plugins:Toggle(Races, {
				Plugins.Add("Auto Complete Trial", "ออโต้ผ่านบททดสอบ"),
				Plugins.Add("Completed the race trials.", "ผ่านบททดสอบของเผ่าพันธ์อัตโนมัติ"),
				79878942189036
			}, 'Complete Trial')

			Plugins:Toggle(Races, {
				Plugins.Add("Auto Acient One Quest", "ออโต้ทำภารกิจเปิดเผ่า"),
				Plugins.Add("Completed the acient one quest.", "ทำภารกิจเปิดเผ่าและทำการซื้อเทียร์"),
				110354272746916
			}, 'Acient One Quest')

			Plugins:Toggle(Races, {
				Plugins.Add("Travel to Door", "เดินทางไปยังประตู"),
				Plugins.Add("Travel to the user's race door.", "เดินทางไปยังประตูทำเผ่าของผู้ใช้"),
				105842535520221
			}, 'Travel to Door [ RACE ]')
		end

		Races:Section(Plugins.Add("Evolution", "วิวัฒนาการ")) do
			Plugins:Toggle(Races, {
				Plugins.Add("Auto Evolution Race II", "ออโต้ทำเผ่า V2"),
				Plugins.Add("Completed the flower quest.", "เคลียร์ภารกิจดอกไม้"),
				129210907844729
			}, 'Race II Quest')

			Plugins:Toggle(Races, {
				Plugins.Add("Auto Evolution Race III", "ออโต้ทำเผ่า V3"),
				Plugins.Add("Support all races in the game.", "รองรับเผ่าพันธ์ทั้งหมดในเกม"),
				106104714655787
			}, 'Race III Quest')
		end

		Races:Section(Plugins.Add("Spacials", "เผ่าพิเศษ")) do  
			Plugins:Toggle(Races, {
				Plugins.Add("Auto Cyborg Race", "ออโต้ทำเผ่าไซบอร์ก"),
				Plugins.Add("Unlocks the cyborg race, recomended use private or low players server.", "ทำภารกิจปลดล็อคเผ่าไซบอร์ก แนะนำให้ใช้ในเซิร์ฟวีหรือเซิฟคนน้อย"),
				126897921136641
			}, 'Cyborg Quest')

			Plugins:Toggle(Races, {
				Plugins.Add("Auto Ghoul Race", "ออโต้ทำเผ่ากูล"),
				Plugins.Add("Unlocks the ghoul race.", "ทำภารกิจปลดล็อคเผ่ากูล"),
				107911350846151
			}, 'Ghoul Quest')
		end
	end

	local Oceans = Plugins:MakeTab({
		Plugins.Add("Oceans", "มหาสมุทร"),
		Color3.fromRGB(255, 255, 255),
		72030941561448
	}) do
		Plugins:MakeBanner(Oceans, {
			"Sea Events", 81613683312286, 150
		})

		Oceans:Section(Plugins.Add("Options", "ตัวเลือก")) do
			Plugins:Default("Select Enemies", { "Piranha", "Terrorshark" })
			Plugins:Default("Select Ship", "PirateBrigade")
			Plugins:Default("Select Zone", 'Infinite - ∞')

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Select Enemies", "เลือกศัตรู"),
				137977318801190
			}, HIDDEN_SETTINGS.SEA_ENEMIES, "Select Enemies")

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Select Ship", "เลือกเรือ"),
				104961350396463
			}, HIDDEN_SETTINGS.SHIPS, "Select Ship")

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Select Zone", "เลือกโซน"),
				101466797589743
			}, HIDDEN_SETTINGS.SEA_ZONES, "Select Zone")
		end

		Oceans:Section(Plugins.Add("Controller", "การควบคุม")) do
			Plugins:Default("Flight Height", 150)
			Plugins:Default("Flight Velocity", 150)
			Plugins:Default("Reset Threshold", 25)

			Plugins:Slider(Oceans, {
				Plugins.Add("Flight Velocity", "ความเร็วขณะบิน"),
				Plugins.Add("Adjust the boat's flight velocity.", "ปรับความเร็วในการบินของเรือ"),
				85529287041825
			}, { 100, 300, 0 }, "Flight Velocity")

			Plugins:Slider(Oceans, {
				Plugins.Add("Flight Height", "ความสูงขณะบิน"),
				Plugins.Add("Adjust the boat's altitude while flying.", "ปรับระดับความสูงของเรือขณะบิน"),
				84675860591128
			}, { 20, 175, 0 }, "Flight Height")

			Plugins:Slider(Oceans, {
				Plugins.Add("Reset Threshold", "เกณฑ์การรีเซ็ต"),
				Plugins.Add("Reset the ship when its health drops below threshold.", "รีเซ็ตเรือเมื่อพลังชีวิตต่ำกว่าค่าที่กำหนด"),
				119594100509168
			}, { 0, 100, 0 }, "Reset Threshold")
		end

		Oceans:Section(Plugins.Add("Spacial", "ฟังชั่นพิเศษ")) do
			Plugins:Toggle(Oceans, {
				Plugins.Add("Overheater", "Overheater"),
				Plugins.Add("Use Dragonstorm to sea events.", "ใช้ปืนพายุมังกรในการล่าอีเว้นทะเล"),
				118996986971457
			}, 'Overheater')

			Plugins:Button(Oceans, {
				Plugins.Add("Remove Rock", "ลบโขดหิน"),
				Plugins.Add("Removes rocks to clear the ocean.", "ลบโขดหินเพื่อเคลียร์ท้องทะเล"),
				108433349941552
			}, function()
				local Rocks = workspace:FindFirstChild('Rocks')
				if Rocks then Rocks.Parent = nil end
			end)

			Plugins:Button(Oceans, {
				Plugins.Add("Boost Ship", "เพิ่มความเร็วเรือ"),
				Plugins.Add("Boost ship speed drive.", "เพิ่มความเร็วในการขับเรือ"),
				73652062010077
			}, function()
				task.spawn(function()
					for _, Object in Boats:GetDescendants() do
						if Object:IsA('VehicleSeat') then
							Object.MaxSpeed = 300
						end
					end
				end)
			end)

			Plugins:Button(Oceans, {
				Plugins.Add("Remove Fog", "ลบหมอก"),
				Plugins.Add("Remove all fog in the game.", "ลบหมอกทั้งหมดในเกม"),
				132837860156075
			}, function()
				Player.PlayerScripts.WeatherStuff.Disabled = true
				Lighting.Brightness = 2

				if Lighting:FindFirstChild('LightingLayers') then
					Lighting.LightingLayers:Destroy()
				end
			end)
		end

		Oceans:Section(Plugins.Add("Skills", "เลือกสกิล")) do
			Plugins:Default("Ocean Melee", { "Z", "X", "C" })
			Plugins:Default("Ocean Sword", { "Z", "X" })
			Plugins:Default("Ocean Gun", { "Z", "X" })
			Plugins:Default("Ocean Fruit", { "Z", "X", "C" })

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Melee", "หมัด"),
				106980798153392
			}, { "Z", "X", "C", "V" }, "Ocean Melee")

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Sword", "ดาบ"),
				99199363807265
			}, { "Z", "X" }, "Ocean Sword")

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Gun", "ปืน"),
				131151646821198
			}, { "Z", "X" }, "Ocean Gun")

			Plugins:Dropdown(Oceans, {
				Plugins.Add("Fruit", "ผลปีศาจ"),
				122308930322531
			}, { "Z", "X", "C", "V", "F" }, "Ocean Fruit")
		end

		Oceans:Section(Plugins.Add("Hunting", "การล่า")) do
			Plugins:Toggle(Oceans, {
				Plugins.Add("Drive a Ship", "ออโต้ขับเรือ"),
				Plugins.Add("Automatically drive the ship during Sea Events.", "แล่นเรืออัตโนมัติระหว่างฟาร์มอีเวนต์ทะเล"),
				129748151876892
			}, "Drive a Ship")

			Plugins:Toggle(Oceans, {
				Plugins.Add("Auto Farm Sea Event", "ออโต้ฟาร์มอีเวนต์ทะเล"),
				Plugins.Add("Defeat select enemies, Enable Drive a Ship to sail automatically.", "กำจัดศัตรูในอีเวนต์ทะเลอัตโนมัติ เปิดออโต้ขับเรือเพื่อแล่นเรืออัตโนมัติ ถ้าปิดจะกำจัดศัตรูเท่านั้น"),
				72030941561448
			}, "Farm Sea Event")
		end
	end

	local Teleports = Plugins:MakeTab({
		Plugins.Add("Traveler", "การเดินทาง"),
		Color3.fromRGB(255, 255, 255),
		83036232330767
	}) do
		Plugins:MakeBanner(Teleports, {
			"Teleports", AssetModule:GetAssetByName('Teleport')
		})

		Teleports:Section(Plugins.Add("Island", "เกาะ")) do
			Plugins:Default("Select Island", IslandNames[1])

			Plugins:Dropdown(Teleports, {
				Plugins.Add("Select Island", "เลือกเกาะ"),
				70616019606039
			}, IslandNames, "Select Island")

			Plugins:Toggle(Teleports, {
				Plugins.Add("Travel", "เดินทาง"),
				Plugins.Add("Travel to the select island.", "เดินทางไปยังเกาะที่เลือก"),
				72695820718432
			}, "Travel Island")
		end

		Teleports:Section(Plugins.Add("Seas", "ทะเล")) do
			Plugins:Button(Teleports, {
				Plugins.Add("Third Sea", "โลก 3"),
				Plugins.Add("Travel to the third sea.", "เดินทางไปยังโลกที่สาม"),
				85144748886419
			}, function()
				Module:TravelTo(3)
			end)

			Plugins:Button(Teleports, {
				Plugins.Add("Second Sea", "โลก 2"),
				Plugins.Add("Travel to the second sea.", "เดินทางไปยังโลกที่สอง"),
				132409462620188
			}, function()
				Module:TravelTo(2)
			end)

			Plugins:Button(Teleports, {
				Plugins.Add("First Sea", "โลก 1"),
				Plugins.Add("Travel to the first sea.", "เดินทางไปยังโลกที่หนึ่ง"),
				95312464677622
			}, function()
				Module:TravelTo(1)
			end)
		end
	end

	Plugins:Managers()
	Options:RunQueue()

	Cached.Window = Window
end);

local Tick = tick() do
	_ENV.NVL_TICK_CLIENT = Tick

	local DevilFruitModule = Module.DevilFruitModule
	local EnemiesModule = Module.EnemiesModule
	local HunterService = Module.HunterService
	local ItemsService = Module.ItemsService
	local DataModule = Module.DataModule
	local RaceModule = Module.RaceModule
	local GameInfo = Module.GameInfo

	local TextLabels = Cached.TextLabels
	local Window = Cached.Window

	local Spawned = Cached.Spawned
	local Despawned = Cached.Despawned

	local Layers = {} do
		Layers.__Enemies = {
			{ Tag = "Order", Label = TextLabels['Orders'] },
			{ Tag = "Darkbeard", Label = TextLabels["Darkbeard"] },
			{ Tag = "Soul Reaper", Label = TextLabels['Soul Reaper'] },
			{ Tag = "rip_indra True Form", Label = TextLabels["Rip Indra"] },
			{ Tag = "Tyrant of the Skies", Label = TextLabels["Tyrant Skies"] },
		}

		Layers.__Items = {
			{ Tag = "Bones", Label = TextLabels["Bones"] },
			{ Tag = "Ectoplasm", Label = TextLabels["Ectoplasm"] },
			{ Tag = "Candy Corn", Label = TextLabels["Candy Corn"] }
		}

		Layers.__Islands = {
			{ Tag = "MysticIsland", Label = TextLabels["Mirage Island"] },
			{ Tag = "KitsuneIsland", Label = TextLabels["Kitsune Shrine"] },
			{ Tag = "LeviathanGate", Label = TextLabels["Leviathan Island"] },
			{ Tag = "PrehistoricIsland", Label = TextLabels["Prehistoric Island"] },
		}
	end

	function Layers.__remain(Data)
		return tonumber(string.match(tostring(Data), "%d+"))
	end

	function Layers.__cakeprince()
		local Enemy = EnemiesModule:GetClosest({
			"Cake Prince", "Dough King"
		})

		if Settings['Disabled Auto Spawn'] then
			return TextLabels['Cake Prince']:SetText(Enemy and Spawned or Despawned)
		end

		local CakePrinceSpawner = Module:ComF("CakePrinceSpawner")
		local Required = Layers.__remain(CakePrinceSpawner)

		if Enemy then
			TextLabels['Cake Prince']:SetText(Spawned)
		elseif Required then
			TextLabels['Cake Prince']:SetText(Utils:Color(tostring(Required),Color3.fromRGB(255, 170, 0)))
		end
	end

	function Layers.__enemy(Data)
		return EnemiesModule:GetClosestByTag(Data.Tag) and Spawned or Despawned
	end

	function Layers.__island(Data)
		return Map:FindFirstChild(Data.Tag) and Spawned or Despawned
	end

	function Layers.__item(Data)
		return Utils:Color( tostring( ItemsService:GetCount(Data.Tag) ), Color3.fromRGB(255, 170, 0) )
	end

	function Layers.__devilfruit()
		TextLabels['Devil Fruit']:SetText( DevilFruitModule:GetRemainTime() )
	end

	function Layers.__elite()
		if EnemiesModule:GetClosestByTag('Elite') then
			return TextLabels["Elite"]:SetText(Spawned)
		end

		if GameInfo.NextElite == 0 then
			return TextLabels["Elite"]:SetText(Despawned)
		end

		TextLabels['Elite']:SetText(GameInfo:GetRemainTime(GameInfo.NextElite))
	end

	function Layers.__moonphase()
		if Lighting:GetAttribute("IsBlueMoon") == true then
			return Utils:Color('Bluemoon', Color3.fromRGB(85, 170, 255))
		end

		local MoonPhase = Lighting:GetAttribute("MoonPhase") or 1

		if MoonPhase == 5 then
			return Utils:Color('Fullmoon', Color3.fromRGB(0, 255, 127))
		end

		local NightsUntilFullMoon = (5 - MoonPhase) % 8

		if NightsUntilFullMoon == 0 then
			NightsUntilFullMoon = 8
		end

		return string.format("%d Nights until full.", NightsUntilFullMoon)
	end

	function Layers.__pirateraid()
		local RemainTime = GameInfo:GetRemainTime(GameInfo.NextPirateRaid, GameInfo.IsPirateRaid)
		if RemainTime ~= 'N/A' then return RemainTime end
		return EnemiesModule:GetClosestByTag('PirateRaid') and Spawned or Despawned
	end

	function Layers.__factory()
		local RemainTime = GameInfo:GetRemainTime(GameInfo.NextFactory, GameInfo.IsFactory)
		if RemainTime ~= 'N/A' then return RemainTime end

		local Factory = Enemies:FindFirstChild('Core')

		if not Factory then
			local StorageCore = ReplicatedStorage:FindFirstChild('Core')

			if not StorageCore then return Despawned end
			if not Module:IsAlive(StorageCore) then return Despawned end

			return Spawned
		end

		return Spawned
	end

	function Layers.__watermark()
		if _ENV.OnFarm then
			if _ENV.RunningOption then
				Window:WatermarkTitle(_ENV.RunningOption)
			end

			if _ENV.RunningMethod then
				Window:WatermarkFooter(_ENV.RunningMethod)
			end
		else
			Window:WatermarkTitle("Empty")
			Window:WatermarkFooter("Nothing running.")
		end
	end

	task.spawn(pcall, function()
		while _ENV.NVL_TICK_CLIENT == Tick do task.wait(0.1)
			GuiService:ClearError()

			pcall(Layers.__devilfruit)
			pcall(Layers.__watermark)

			TextLabels['Server Uptime']:SetText(GameInfo:GetUptime())

			TextLabels['Pirate Raid']:SetText(Layers.__pirateraid())
			TextLabels['Factory']:SetText(Layers.__factory())
		end
	end)

	task.spawn(pcall, function()
		while _ENV.NVL_TICK_CLIENT == Tick do task.wait(1)
			TextLabels['Moon Phase']:SetText(Layers.__moonphase())

			TextLabels['Player Race']:SetTitle(DataModule.__currently('__Race'))
			TextLabels['Player Race']:SetText(RaceModule:GetRaceStatus())

			for _, Data in Layers.__Enemies do
				if Data.Label then
					Data.Label:SetText( Layers.__enemy(Data) )
				end
			end

			for _, Data in Layers.__Items do
				if Data.Label then
					Data.Label:SetText( Layers.__item(Data) )
				end
			end

			for _, Data in Layers.__Islands do
				if Data.Label then
					Data.Label:SetText( Layers.__island(Data) )
				end
			end

			pcall(Layers.__elite)
			pcall(Layers.__cakeprince)

			if not HunterService:IsSoruValid() then
				HunterService.__SoruFunction = nil

				if Player.Character then
					pcall(HunterService.ApplySoru, HunterService)
				end
			end
		end
	end)

	task.defer(ItemsService.__InitClient)
	task.defer(RaceModule.__InitTempleOfTime)
end
