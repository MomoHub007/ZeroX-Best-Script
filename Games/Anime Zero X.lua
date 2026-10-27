local AutoSkillWarn = warn
local AUTO_SKILL_DEBUG = false -- หลังตรวจเสร็จเปลี่ยนเป็น false



local print = function() end
local warn = function() end


if not game:IsLoaded() then
    repeat
        game.Loaded:Wait()
    until game:IsLoaded()
end

local BASE = (getgenv and getgenv().MacUIBase) or "https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/"

local MacUI = loadstring(game:HttpGet(BASE .. "MacUIFramework.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE .. "SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(BASE .. "InterfaceManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE .. "ThemeManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[Zero X] This UI must run on the client.")
    return
end
local Options = MacUI.Options

-- Local overhead name
do
    local DISPLAY_TEXT = "ZeroX Script Hub"

    local alive = true
    local currentCharacter
    local characterConnections = {}
    local records = {}

    local function clearLabels()
        for label, record in pairs(records) do
            record.connection:Disconnect()

            if label.Parent and label.Text == DISPLAY_TEXT then
                label.Text = record.original
            end
        end

        table.clear(records)
    end

    local function clearCharacter()
        for _, connection in ipairs(characterConnections) do
            connection:Disconnect()
        end

        table.clear(characterConnections)
        clearLabels()
        currentCharacter = nil
    end

    local function bindCharacter(character)
        clearCharacter()

        if not alive then
            return
        end

        currentCharacter = character
        local queued = false

        local function sync()
            if not alive
                or currentCharacter ~= character
                or LocalPlayer.Character ~= character then

                return
            end

            local overhead = character:FindFirstChild("OverHead")

            local main = overhead
                and overhead:IsA("BillboardGui")
                and overhead:FindFirstChild("Main")

            local holder = main
                and main:FindFirstChild("DisplayName")

            local shadow = holder
                and holder:FindFirstChild("TxtShadow")

            local foreground = shadow
                and shadow:FindFirstChild("Txt")

            local targets = {}

            if shadow and shadow:IsA("TextLabel") then
                targets[shadow] = true
            end

            if foreground and foreground:IsA("TextLabel") then
                targets[foreground] = true
            end

            -- ตัด Connection ของป้ายเก่าที่ถูกเปลี่ยน
            for label, record in pairs(records) do
                if not targets[label] then
                    record.connection:Disconnect()

                    if label.Parent
                        and label.Text == DISPLAY_TEXT then

                        label.Text = record.original
                    end

                    records[label] = nil
                end
            end

            for label in pairs(targets) do
                if not records[label] then
                    local record = {
                        original = label.Text,
                    }

                    records[label] = record

                    record.connection =
                        label:GetPropertyChangedSignal("Text"):Connect(function()
                            if not alive
                                or currentCharacter ~= character
                                or LocalPlayer.Character ~= character then

                                return
                            end

                            if label.Text ~= DISPLAY_TEXT then
                                -- เก็บข้อความล่าสุดของเกมไว้คืนตอน Unload
                                record.original = label.Text
                                label.Text = DISPLAY_TEXT
                            end
                        end)

                    if label.Text ~= DISPLAY_TEXT then
                        label.Text = DISPLAY_TEXT
                    end
                end
            end
        end

        local function scheduleSync()
            if queued then
                return
            end

            queued = true

            task.defer(function()
                queued = false
                sync()
            end)
        end

        local relevant = {
            OverHead = true,
            Main = true,
            DisplayName = true,
            TxtShadow = true,
            Txt = true,
        }

        table.insert(
            characterConnections,
            character.DescendantAdded:Connect(function(object)
                if relevant[object.Name] then
                    scheduleSync()
                end
            end)
        )

        table.insert(
            characterConnections,
            character.DescendantRemoving:Connect(function(object)
                if relevant[object.Name] then
                    scheduleSync()
                end
            end)
        )

        sync()
    end

    local added =
        LocalPlayer.CharacterAdded:Connect(bindCharacter)

    local removing =
        LocalPlayer.CharacterRemoving:Connect(function(character)
            if currentCharacter == character then
                clearCharacter()
            end
        end)

    MacUI:OnUnload(function()
        alive = false
        added:Disconnect()
        removing:Disconnect()
        clearCharacter()
    end)

    if LocalPlayer.Character then
        bindCharacter(LocalPlayer.Character)
    end
end

-- Anti AFK: เปิดตลอดขณะที่ Zero X ทำงาน
do
    local virtualUser = game:GetService("VirtualUser")
    local alive = true
    local lastAttemptAt = -math.huge
    local connection

    connection = LocalPlayer.Idled:Connect(function()
        if not alive or MacUI.Unloaded then
            return
        end

        local now = os.clock()

        if now - lastAttemptAt < 10 then
            return
        end

        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        lastAttemptAt = now

        local ok, err = pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(
                Vector2.new(0, 0),
                camera.CFrame
            )
        end)

        if not ok then
            warn("[Zero X / Anti AFK] Input failed:", err)
        end
    end)

    MacUI:OnUnload(function()
        alive = false

        if connection then
            connection:Disconnect()
            connection = nil
        end
    end)
end

local ZeroXContext = {
    LobbyOwner = nil,
}

function ZeroXContext.IsLobby()
    return game.PlaceId == 114574503491412
end

function ZeroXContext.IsMatch()
    return game.PlaceId == 109151342576374
end

function ZeroXContext.EvolvingRequested()
    local option = Options.ZeroXAutoEvolveCharacter
    return option ~= nil and option.Value == true
end

function ZeroXContext.CraftingRequested()
    local craft = Options.ZeroXAutoCraftAccessory
    local farm = Options.ZeroXAutoFarmCraftMaterial

    return craft ~= nil and craft.Value == true
        and farm ~= nil and farm.Value == true
end

function ZeroXContext.DeliveryRequested()
    local toggle = Options.ZeroXAutoDeliveryQuest
    return toggle ~= nil and toggle.Value == true
end

--------------------------------------------------------------------------------
-- Original theme definitions retained unchanged.
--------------------------------------------------------------------------------

local rgb = Color3.fromRGB
MacUI:AddTheme("Ocean", {
	Background = rgb(14, 26, 40),
	Sidebar = rgb(19, 34, 52),
	SidebarDivider = rgb(8, 16, 26),
	Group = rgb(22, 39, 58),
	GroupStroke = rgb(34, 56, 80),
	Separator = rgb(36, 58, 82),
	SubText = rgb(150, 172, 196),
	Tertiary = rgb(96, 120, 146),
	Control = rgb(44, 70, 98),
	ControlHover = rgb(54, 84, 116),
	ControlStroke = rgb(58, 88, 120),
	Button = rgb(40, 66, 94),
	ButtonHover = rgb(50, 80, 112),
	Field = rgb(12, 22, 34),
	FieldStroke = rgb(40, 64, 90),
	Search = rgb(28, 48, 70),
	SwitchOff = rgb(44, 70, 98),
	Track = rgb(40, 64, 90),
	SegmentBg = rgb(30, 52, 76),
	SegmentSelected = rgb(64, 98, 134),
	Menu = rgb(22, 39, 58),
	MenuStroke = rgb(48, 76, 106),
	Code = rgb(10, 19, 30),
}, "Dark")

MacUI:AddTheme("Rose", {
	Background = rgb(252, 245, 247),
	Sidebar = rgb(246, 231, 236),
	Group = rgb(255, 255, 255),
	Search = rgb(238, 222, 228),
	SegmentBg = rgb(240, 225, 231),
}, "Light")

local Window

-- In-Game: แสดง Cursor และปลดล็อกเมาส์
do
    local input = game:GetService("UserInputService")
    local runService = game:GetService("RunService")
    local mouse = LocalPlayer:GetMouse()
    local alive = true
    local saved

    local binding = "ZeroXInGameCursor_"
        .. game:GetService("HttpService"):GenerateGUID(false)

    local function restore()
        if not saved then return end

        input.MouseIconEnabled = saved.IconEnabled
        input.MouseBehavior = saved.Behavior
        mouse.Icon = saved.Icon
        saved = nil
    end

    local function updateCursor()
        if not alive then return end

        if not ZeroXContext.IsMatch()
            or not input.MouseEnabled
            or not Window
            or Window.Shown ~= true then

            restore()
            return
        end

        if not saved then
            saved = {
                IconEnabled = input.MouseIconEnabled,
                Behavior = input.MouseBehavior,
                Icon = mouse.Icon,
            }
        end

        if not input.MouseIconEnabled then
            input.MouseIconEnabled = true
        end

        if input.MouseBehavior ~= Enum.MouseBehavior.Default then
            input.MouseBehavior = Enum.MouseBehavior.Default
        end

        -- แสดงลูกศรเริ่มต้น
        if mouse.Icon ~= "" then
            mouse.Icon = ""
        end
    end

    runService:BindToRenderStep(
        binding,
        Enum.RenderPriority.Last.Value + 1,
        updateCursor
    )

    MacUI:OnUnload(function()
        alive = false
        runService:UnbindFromRenderStep(binding)
        restore()
    end)
end

--------------------------------------------------------------------------------
-- Window: original theme, accent, layout and sizing retained.
--------------------------------------------------------------------------------

Window = MacUI:CreateWindow({
	Title = "Zero X",
	SubTitle = "",
	Icon = "command", -- Lucide icon name, rbxassetid:// or a number
	IconColor = "Blue", -- tile colour for that icon (dock, dialogs)
	Size = UDim2.fromOffset(820, 600),
	MinSize = Vector2.new(620, 420),
	TabWidth = 214, -- sidebar width
	Theme = "Dark", -- "Dark" | "Light" | "Midnight" | "Ocean" | "Rose"
	Accent = "Blue", -- accent name, hex string or Color3
	SidebarStyle = "Tile", -- "Tile" | "Tinted" | "Plain"
	Profile = {
		Title = "ZeroX Script Hub",
		Subtitle = "",
	},
	MinimizeKey = Enum.KeyCode.RightControl,
	Acrylic = false, -- frosted-glass sidebar (graphics quality 8+)
	KeybindList = false, -- floating list of keybinds and shortcuts
	Search = true, -- toolbar search field
	SearchPlaceholder = "Search",
	Spotlight = true, -- Ctrl/Cmd + K command palette
	SpotlightKey = Enum.KeyCode.K,
	Resizable = true,
	ConfirmClose = true, -- the red button asks before unloading
	ReplaceExisting = true, -- running the script again replaces this window
	ShowDock = false, -- dock icon while minimised
	Loading = false,
	Undo = true, -- Ctrl + Z / Ctrl + Shift + Z for changes you make
	PerformanceGuard = true, -- pause blur and animations if the game slows down
})

--------------------------------------------------------------------------------
-- ใช้ PlayerGui สำหรับหน้าต่างหลัก
-- ต้องวางก่อนส่วน Lobby ที่ require Module ของเกม
--------------------------------------------------------------------------------
do
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)

    local screenGui = Window.ScreenGui

    if not playerGui or not playerGui:IsA("PlayerGui") then
        warn("[Zero X] PlayerGui unavailable")
        return
    end

    if not screenGui or not screenGui:IsA("ScreenGui") then
        warn("[Zero X] Window.ScreenGui unavailable")
        return
    end

    -- ป้องกัน ScrollRail ของเกมเฉพาะ UI Zero X
    local function DisableGameScrollRail(object)
        if object:IsA("ScrollingFrame") then
            object:SetAttribute("ScrollRail", false)
        end
    end

    -- รองรับหน้าหรือ Dropdown ที่สร้างภายหลัง
    local scrollConnection = screenGui.DescendantAdded:Connect(
        DisableGameScrollRail
    )

    -- ตั้งค่าของเดิมก่อนย้ายเข้า PlayerGui
    for _, object in ipairs(screenGui:GetDescendants()) do
        DisableGameScrollRail(object)
    end

    MacUI:OnUnload(function()
        scrollConnection:Disconnect()
    end)

    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    print("[Zero X] UI Parent:", screenGui.Parent:GetFullName())
end

--------------------------------------------------------------------------------
-- ZERO X: macOS-style logo / draggable / visible while UI is hidden
--------------------------------------------------------------------------------

do
	local screenGui = Window.ScreenGui

	if screenGui and screenGui:IsA("ScreenGui") then
		local UserInputService = game:GetService("UserInputService")
		local TweenService = game:GetService("TweenService")

		-- ปรับค่าเองตรงนี้
		local LOGO_IMAGE = "rbxassetid://138334792995002"
		local ICON_SIZE = 64
		local TOP_OFFSET = 12
		local DRAG_THRESHOLD = 6
		local EDGE_MARGIN = 8

		local connections = {}

		local function Connect(signal, callback)
			local connection = signal:Connect(callback)
			table.insert(connections, connection)
			return connection
		end

		-- ตัวครอบ: รวมไอคอนและชื่อไว้ด้วยกัน
		local holder = Instance.new("Frame")
		holder.Name = "ZeroXLogoHolder"
		holder.Size = UDim2.fromOffset(ICON_SIZE + 12, ICON_SIZE + 28)
		holder.Position = UDim2.new(
			0.5,
			-(ICON_SIZE + 12) / 2,
			0,
			TOP_OFFSET
		)
		holder.BackgroundTransparency = 1
		holder.Visible = Window.Shown == false
		holder.ZIndex = 50
		holder.Parent = screenGui

		-- เงาแบบซ้อนชั้น ใช้เฉพาะ Frame ไม่โหลดรูปเพิ่ม
		local shadow = Instance.new("Frame")
		shadow.Name = "Shadow"
		shadow.Position = UDim2.fromOffset(4, 5)
		shadow.Size = UDim2.fromOffset(ICON_SIZE + 4, ICON_SIZE + 4)
		shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		shadow.BackgroundTransparency = 0.65
		shadow.BorderSizePixel = 0
		shadow.ZIndex = 50
		shadow.Parent = holder

		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = UDim.new(0, 20)
		shadowCorner.Parent = shadow

		-- พื้นผิวไอคอน
		local logoButton = Instance.new("ImageButton")
		logoButton.Name = "ZeroXLogoButton"
		logoButton.Position = UDim2.fromOffset(6, 0)
		logoButton.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
		logoButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		logoButton.BorderSizePixel = 0
		logoButton.Image = ""
		logoButton.AutoButtonColor = false
		logoButton.Active = true
		logoButton.ZIndex = 51
		logoButton.Parent = holder


		-- Keep the input target fixed; animate only its visual surface.
		logoButton.BackgroundTransparency = 1
		local visual = Instance.new("Frame")
		visual.Name = "LogoSurface"
		visual.AnchorPoint = Vector2.new(0.5, 0.5)
		visual.Position = UDim2.fromScale(0.5, 0.5)
		visual.Size = UDim2.fromScale(1, 1)
		visual.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		visual.BorderSizePixel = 0
		visual.ZIndex = 51
		visual.Parent = logoButton

		local visualScale = Instance.new("UIScale")
		visualScale.Parent = visual

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 18)
		corner.Parent = visual

		local surface = Instance.new("UIGradient")
		surface.Rotation = 90
		surface.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		surface.Parent = visual

		local border = Instance.new("UIStroke")
		border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		border.Color = Color3.fromRGB(190, 190, 195)
		border.Transparency = 0.65
		border.Thickness = 1
		border.Parent = visual

		-- แยกรูปจากพื้นหลัง เพื่อไม่ให้ Gradient เปลี่ยนสีโลโก้
		local logoImage = Instance.new("ImageLabel")
		logoImage.Name = "Logo"
		logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
		logoImage.Position = UDim2.fromScale(0.5, 0.5)
		logoImage.Size = UDim2.fromOffset(ICON_SIZE - 12, ICON_SIZE - 12)
		logoImage.BackgroundTransparency = 1
		logoImage.Image = LOGO_IMAGE
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.ZIndex = 52
		logoImage.Parent = visual

		local sheen = Instance.new("Frame")
		sheen.Name = "HoverSheen"
		sheen.Size = UDim2.fromScale(1, 1)
		sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		sheen.BorderSizePixel = 0
		sheen.ZIndex = 53
		sheen.Parent = visual
		local sheenCorner = Instance.new("UICorner")
		sheenCorner.CornerRadius = UDim.new(0, 18)
		sheenCorner.Parent = sheen
		local sheenGradient = Instance.new("UIGradient")
		sheenGradient.Rotation = 25
		sheenGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 1),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(0.65, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		sheenGradient.Offset = Vector2.new(-1.5, 0)
		sheenGradient.Parent = sheen

		-- One tween per target; rapid hover changes cancel the previous tween.
		local effectTweens = {}
		local hovered = false
		local function Animate(target, properties, instant, duration)
			if effectTweens[target] then
				effectTweens[target]:Cancel()
				effectTweens[target] = nil
			end
			if instant then
				for key, value in pairs(properties) do
					target[key] = value
				end
				return
			end
			local tween = TweenService:Create(target,
				TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				properties)
			effectTweens[target] = tween
			tween:Play()
		end

		local function SetEffect(pressed, instant)
			local highlighted = hovered or pressed
			Animate(visualScale, { Scale = pressed and 0.96 or (hovered and 1.08 or 1) }, instant)
			Animate(visual, {
				Position = UDim2.new(0.5, 0, 0.5, pressed and 0 or (hovered and -3 or 0)),
			}, instant)
			Animate(border, {
				Color = highlighted and Color3.fromRGB(95, 175, 255) or Color3.fromRGB(190, 190, 195),
				Transparency = highlighted and 0.12 or 0.65,
				Thickness = highlighted and 1.8 or 1,
			}, instant)
			Animate(shadow, {
				BackgroundTransparency = highlighted and 0.5 or 0.65,
				Position = UDim2.fromOffset(4, hovered and 8 or 5),
			}, instant)
		end

		local function ResetEffects()
			hovered = false
			SetEffect(false, true)
			Animate(sheenGradient, { Offset = Vector2.new(-1.5, 0) }, true)
		end


		-- ลากโดยใช้ระยะจากจุดกดเริ่มต้น
		local activeInput
		local startPointer
		local startPosition
		local moved = false

		local function SetPositionClamped(position)
			local bounds = screenGui.AbsoluteSize
			local size = holder.AbsoluteSize

			local marginX = math.min(
				EDGE_MARGIN,
				math.max(0, (bounds.X - size.X) / 2)
			)
			local marginY = math.min(
				EDGE_MARGIN,
				math.max(0, (bounds.Y - size.Y) / 2)
			)

			local x = math.clamp(
				position.X,
				marginX,
				math.max(marginX, bounds.X - size.X - marginX)
			)
			local y = math.clamp(
				position.Y,
				marginY,
				math.max(marginY, bounds.Y - size.Y - marginY)
			)

			holder.Position = UDim2.fromOffset(x, y)
		end

		local function GetLocalPosition()
			local bounds = screenGui.AbsoluteSize
			local position = holder.Position

			return Vector2.new(
				position.X.Scale * bounds.X + position.X.Offset,
				position.Y.Scale * bounds.Y + position.Y.Offset
			)
		end

		local function ResetDrag()
			activeInput = nil
			startPointer = nil
			startPosition = nil
			moved = false
			SetEffect(false)
		end

		Connect(logoButton.MouseEnter, function()
			if MacUI.Unloaded or not holder.Visible then return end
			hovered = true
			SetEffect(activeInput ~= nil)
			if not activeInput then
				Animate(sheenGradient, { Offset = Vector2.new(-1.5, 0) }, true)
				Animate(sheenGradient, { Offset = Vector2.new(1.5, 0) }, false, 0.65)
			end
		end)

		Connect(logoButton.MouseLeave, function()
			hovered = false
			SetEffect(activeInput ~= nil)
		end)

		Connect(logoButton.InputBegan, function(input)
			if activeInput or MacUI.Unloaded or not holder.Visible then
				return
			end

			local inputType = input.UserInputType

			if inputType ~= Enum.UserInputType.MouseButton1
				and inputType ~= Enum.UserInputType.Touch then
				return
			end

			activeInput = input
			startPointer = Vector2.new(input.Position.X, input.Position.Y)
			startPosition = GetLocalPosition()
			moved = false
			SetEffect(true)
		end)

		Connect(UserInputService.InputChanged, function(input)
			if not activeInput or not holder.Visible then
				return
			end

			local isTouch = activeInput.UserInputType
				== Enum.UserInputType.Touch

			if isTouch then
				if input ~= activeInput then
					return
				end
			elseif input.UserInputType
				~= Enum.UserInputType.MouseMovement then
				return
			end

			local pointer = Vector2.new(input.Position.X, input.Position.Y)
			local delta = pointer - startPointer

			if delta.Magnitude >= DRAG_THRESHOLD then
				moved = true
			end

			if moved then
				SetPositionClamped(startPosition + delta)
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if not activeInput or input ~= activeInput then
				return
			end

			local shouldOpen = not moved and holder.Visible
				and input.UserInputState ~= Enum.UserInputState.Cancel

			ResetDrag()

			if shouldOpen and not MacUI.Unloaded and not Window.Loading then
				Window:Restore()
			end
		end)

		Connect(UserInputService.WindowFocusReleased, function()
			ResetDrag()
			ResetEffects()
		end)

		Connect(screenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
			ResetDrag()
			ResetEffects()
			SetPositionClamped(GetLocalPosition())
		end)

		-- ซิงก์กับการเปิด / ซ่อน UI ทั้งปุ่มย่อและปุ่มลัด
		local originalSetVisible = Window.SetVisible

		local function SetVisibleWithLogo(self, visible, instant)
			originalSetVisible(self, visible, instant)

			if holder.Parent then
				ResetDrag()
				ResetEffects()
				holder.Visible = self.Shown == false
			end
		end

		Window.SetVisible = SetVisibleWithLogo

		MacUI:OnUnload(function()
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			table.clear(connections)

			if Window.SetVisible == SetVisibleWithLogo then
				Window.SetVisible = originalSetVisible
			end

			for target, tween in pairs(effectTweens) do
				tween:Cancel()
				effectTweens[target] = nil
			end
			holder:Destroy()
		end)
	else
		warn("[Zero X] Cannot create logo: Window.ScreenGui unavailable")
	end
end

-- Pages
local Tabs = {}

Tabs.Home = Window:AddTab({
    Title = "Home",
    Icon = "home",
    Section = "Overview",
})

Tabs.Lobby = Window:AddTab({
    Title = "Lobby",
    Icon = "log-in",
    Section = "Gameplay",
})

Tabs.InGame = Window:AddTab({
    Title = "In-Game",
    Icon = "swords",
    Section = "Gameplay",
})

Tabs.Card = Window:AddTab({
    Title = "Card",
    Icon = "layers",
    Section = "Gameplay",
})

Tabs.Gacha = Window:AddTab({
    Title = "Gacha",
    Icon = "sparkles",
    Section = "Character",
})

Tabs.Progress = Window:AddTab({
    Title = "Progress",
    Icon = "trending-up",
    Section = "Character",
})

Tabs.Crafting = Window:AddTab({
    Title = "Crafting",
    Icon = "hammer",
    Section = "Character",
})

Tabs.Player = Window:AddTab({
    Title = "Player",
    Icon = "user",
    Section = "System",
})

Tabs.Appearance = Window:AddTab({
    Title = "Settings",
    Icon = "palette",
    Section = "System",
})

Tabs.Profiles = Window:AddTab({
    Title = "Profiles",
    Icon = "folder",
    Section = "System",
})

--------------------------------------------------------------------------------
-- ZERO X: Uniform section styling
--------------------------------------------------------------------------------
do
    local styles = {
        ["🚪 Auto Join"] = {
            Title = "Auto Join",
            Icon = "log-in",
            Description = "เลือก Mode, Map, Chapter และ Difficulty "
                .. "เพื่อเข้าห้องว่างและเริ่มเล่นอัตโนมัติ\n"
                .. "ทำงานใน: Lobby",
        },

        ["Auto Join"] = {
            Icon = "log-in",
            Description = "เลือก Mode, Map, Chapter และ Difficulty "
                .. "เพื่อเข้าห้องว่างและเริ่มเล่นอัตโนมัติ\n"
                .. "ทำงานใน: Lobby",
        },

        ["Delivery Quest"] = {
            Icon = "package",
            Description = "รับพัสดุ ส่งให้ NPC เป้าหมาย "
                .. "และ Claim Reward อัตโนมัติจนถึงโควต้าประจำวัน\n"
                .. "ทำงานใน: Lobby",
        },

        ["Auto Claim"] = {
            Icon = "gift",
            Description = "รับรางวัล Quest, Level Milestone และ Achievement "
                .. "ที่สำเร็จและยังไม่ได้รับ ตาม Toggle ที่เปิด\n"
                .. "ทำงานใน: Lobby",
        },

        ["Auto Farm"] = {
            Icon = "swords",
            Description = "ค้นหาและโจมตีศัตรูอัตโนมัติ "
                .. "ปรับตำแหน่ง Below, Above หรือ Orbit "
                .. "และเปิด Auto Start Vote ได้\n"
                .. "ทำงานใน: ด่าน",
        },

        ["Auto Skill"] = {
            Icon = "electricity",
            Description = "เลือก Skill 1–3 และ Ultimate "
                .. "ตั้งลำดับ Skill Combo "
                .. "และจำกัด Ultimate ให้ใช้เฉพาะ Boss ได้\n"
                .. "ทำงานใน: ด่าน ขณะ Auto Farm",
        },

        ["Retreat Heal"] = {
            Icon = "heart-pulse",
            Description = "ถอยเมื่อ HP ต่ำกว่าเปอร์เซ็นต์ที่ตั้ง "
                .. "และกลับไปสู้เมื่อ HP ฟื้นถึงค่าที่กำหนด\n"
                .. "ทำงานใน: ด่าน ขณะ Auto Farm",
        },

        ["End Game"] = {
            Icon = "flag",
            Description = "เมื่อจบด่านและเกมพร้อม ให้ Retry, Next Chapter "
                .. "หรือ Leave ตามที่เลือก; งานฟาร์ม Craft/Evolve "
                .. "จะกำหนด Retry/Leave ตามของที่ยังขาด\n"
                .. "ทำงานใน: ด่าน",
        },

        ["Characters"] = {
            Icon = "users",
            Description = "สุ่ม Character ลง Slot ที่เลือก "
                .. "ใช้ Normal หรือ Lucky และหยุดเมื่อได้ตัวละครเป้าหมาย "
                .. "พร้อมแสดงผลสุ่มล่าสุด\n"
                .. "ทำงานใน: Lobby",
        },

        ["Traits"] = {
            Icon = "gem",
            Description = "สุ่ม Trait ให้ตัวละครที่เลือก "
                .. "หยุดเมื่อได้ Trait หรือระดับความหายากตามเงื่อนไข "
                .. "พร้อมแสดงผลสุ่มล่าสุด\n"
                .. "ทำงานใน: Lobby",
        },

        ["Character Slots"] = {
            Icon = "unlock",
            Description = "ปลดล็อก Slot เก็บตัวละครตามลำดับ "
                .. "เมื่อมีเงินเพียงพอตามราคาของเกม\n"
                .. "ทำงานใน: Lobby",
        },

        ["Skill Tree"] = {
            Icon = "git-branch",
            Description = "อัป Skill Tree Tier ถัดไป "
                .. "ของตัวละครและ Branch ที่เลือก "
                .. "เมื่อมี Token เพียงพอ\n"
                .. "ทำงานใน: Lobby",
        },

        ["Best Gear"] = {
            Icon = "award",
            Description = "สวม Accessory และ Title ที่ดีที่สุดจากของที่มี "
                .. "โดยใช้เกณฑ์คะแนน Buff และ Tier ของระบบเดิม\n"
                .. "ทำงานใน: Lobby",
        },

        ["Auto Evolve Character"] = {
            Icon = "trending-up",
            Description = "เลือกตัวละครใน Slot แล้วฟาร์ม Material "
                .. "และฟาร์ม Shadow Gate เมื่อ Coins/Gems ไม่พอ "
                .. "จากนั้นกลับ Lobby เพื่อ Evolve; "
                .. "[Evo] หมายถึงปลดล็อก Ultimate แล้ว "
                .. "และ Jinwoo ทำถึง Stage I\n"
                .. "ทำงานใน: Lobby และด่าน",
        },

        ["Accessory Crafting"] = {
            Icon = "hammer",
            Description = "เลือก Accessory แล้วเปิด Auto Craft; "
                .. "Auto Farm Material จะหาวัสดุที่ขาด "
                .. "Retry เมื่อยังต้องฟาร์มด่านเดิม "
                .. "และกลับ Lobby เพื่อคราฟเมื่อครบ\n"
                .. "ทำงานใน: คราฟที่ Lobby / ฟาร์มในด่าน",
        },

        ["Movement"] = {
            Icon = "move",
            Description = "ตั้ง WalkSpeed, Infinite Jump, Noclip "
                .. "และ Instant ProximityPrompt ตามตัวเลือกที่เปิด\n"
                .. "ทำงานใน: Lobby และด่าน",
        },

        ["Performance"] = {
            Icon = "monitor",
            Description = "ลดภาระการแสดงผลด้วย FPS Boost, Ultra FPS Boost, "
                .. "ปิด Animation หรือปิด 3D Rendering ตามที่เลือก\n"
                .. "ทำงานใน: Lobby และด่าน",
        },

        ["Fly"] = {
            Icon = "send",
            Description = "เปิดการบินและตั้งความเร็ว "
                .. "ใช้ WASD เคลื่อนที่ตามกล้อง, Space ขึ้น "
                .. "และ Left Ctrl ลง\n"
                .. "ทำงานใน: Lobby และด่าน",
        },

        ["Session"] = {
            Icon = "refresh-cw",
            Description = "ตั้ง Auto Reconnect เมื่อถูก Kick "
                .. "ในสภาพแวดล้อมที่รองรับ "
                .. "และตั้งซ่อน UI เมื่อเริ่มสคริปต์\n"
                .. "ทำงานใน: Lobby และด่าน",
        },

        ["Interface"] = {
            Icon = "palette",
            Description = "ปรับ Theme, Accent, รูปแบบหน้าต่าง "
                .. "และตัวเลือกการแสดงผลของ UI\n"
                .. "มีผลกับ: หน้าต่าง Zero X",
        },

        ["Configurations"] = {
            Icon = "folder",
            Description = "บันทึก โหลด และตั้ง Autoload "
                .. "สำหรับชุดการตั้งค่า "
                .. "โดย Profiles แยกตาม PlaceId\n"
                .. "มีผลกับ: การตั้งค่าของ Zero X",
        },
    }

    for _, tab in pairs(Tabs) do
        local originalAddSection = tab.AddSection

        if type(originalAddSection) == "function" then
            tab.AddSection = function(self, info)
                local spec

                if type(info) == "table" then
                    spec = table.clone(info)
                else
                    spec = {
                        Title = tostring(info or ""),
                    }
                end

                local style = styles[spec.Title]

                if style then
                    spec.Title = style.Title or spec.Title
                    spec.Icon = style.Icon
                    spec.Description = style.Description
                end

                -- ใช้สี Accent ปัจจุบันเหมือนกันทุก Section
                spec.IconColor = nil

                -- เริ่มต้นแสดง Controls ทั้งหมด และกดพับได้
                spec.Collapsible = true
                spec.Collapsed = false

                return originalAddSection(self, spec)
            end
        end
    end
end

Tabs.Home:Select()

--------------------------------------------------------------------------------
-- HOME: Character / Account Status
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")

    local alive = true
    local accountNS
    local traits
    local traitRetryAt = 0

    local cards = {}
    local lastText = {}

    local overview = Tabs.Home:AddSection({
        Title = "Account Status",
        Description = "ตัวละครที่สวมใส่ สถานที่ปัจจุบัน และทรัพยากรในบัญชี",
        Icon = "user",
    })

    local summary = overview:AddParagraph({
        Title = "Account",
        Content = "รอข้อมูลบัญชี",
    })

    local characters = Tabs.Home:AddSection({
        Title = "Character Status",
        Description = "ตัวละครแต่ละ Slot พร้อม Evo, Trait, XP และ Skill Tree; อัปเดตเมื่อเปิดหน้า Home",
        Icon = "users",
    })

    local function write(paragraph, text)
        if lastText[paragraph] ~= text then
            lastText[paragraph] = text
            paragraph:SetContent(text)
        end
    end

    local function readModule(path)
        local node = RS

        for _, name in ipairs(path) do
            node = node:FindFirstChild(name)

            if not node then
                return nil
            end
        end

        assert(
            node:IsA("ModuleScript"),
            "Expected ModuleScript"
        )

        return require(node)
    end

    local function loadTraits()
        if traits or os.clock() < traitRetryAt then
            return
        end

        traitRetryAt = os.clock() + 10

        local config = readModule({
            "assets", "config", "Traits", "traitConfig",
        })

        if type(config) ~= "table" then
            return
        end

        local byId = {}

        for _, def in pairs(config) do
            if type(def) == "table"
                and type(def.Id) == "number"
                and type(def.Name) == "string" then

                byId[def.Id] = def
            end
        end

        traits = byId
    end

    local function traitText(info)
        local id = type(info.TraitData) == "table"
            and info.TraitData.Trait

        if type(id) ~= "number" then
            return "รอข้อมูล"
        end

        if id == 0 then
            return "ไม่มี Trait"
        end

        local def = traits and traits[id]

        if not def then
            return "ID " .. id .. " (ยังไม่มีชื่อจาก Config)"
        end

        local rarity = def.Rarity == "Exotic"
            and "MYTHIC" or def.Rarity

        return def.Name .. (
            type(rarity) == "string"
                and " [" .. rarity .. "]"
                or ""
        )
    end

    local function render()
        accountNS = accountNS or readModule({
            "global", "stores", "accountNamespace",
        })

        if not accountNS then
            write(summary, "รอ accountNamespace")
            return
        end

        local account = accountNS.getLocalPlayerAccount()

        if not account then
            write(summary, "รอข้อมูลบัญชี")
            return
        end

        local data = account:toTable()

        if type(data) ~= "table"
            or type(data.UnlockedCharacters) ~= "table" then

            write(summary, "รอข้อมูล Slot")
            return
        end

        -- ชื่อ Trait เป็นข้อมูลเสริม ไม่ให้ขัดขวางส่วนอื่น
        local ok, err = pcall(loadTraits)

        local lines = {
            "ZeroX Script Hub",

            "สถานที่: " .. (
                ZeroXContext.IsLobby() and "Lobby"
                or ZeroXContext.IsMatch() and "In-Game"
                or tostring(game.PlaceId)
            ),

            "กำลังสวมใส่: " .. (
                type(data.character) == "string"
                    and data.character
                    or "รอข้อมูล"
            ),
        }

        if type(data.currencies) == "table" then
            local keys = {}

            for key, value in pairs(data.currencies) do
                if type(value) == "number" then
                    table.insert(keys, key)
                end
            end

            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)

            for _, key in ipairs(keys) do
                table.insert(
                    lines,
                    tostring(key)
                        .. ": "
                        .. tostring(data.currencies[key])
                )
            end
        else
            table.insert(lines, "ทรัพยากร: รอข้อมูล")
        end

        if not ok then
            table.insert(
                lines,
                "อ่านชื่อ Trait ไม่สำเร็จ: " .. tostring(err)
            )
        end

        local rows = {}
        local present = {}
        local unlocked = 0
        local unique = {}

        for key, slot in pairs(data.UnlockedCharacters) do
            local index = type(key) == "string"
                and tonumber(key:match("^Slot(%d+)$"))

            if index and type(slot) == "table" then
                table.insert(rows, {
                    index = index,
                    slot = slot,
                })

                present[index] = true

                if slot.Unlocked == true then
                    unlocked += 1

                    if type(slot.Character) == "string"
                        and slot.Character ~= "" then

                        unique[slot.Character] = true
                    end
                end
            end
        end

        table.sort(rows, function(a, b)
            return a.index < b.index
        end)

        local count = 0

        for _ in pairs(unique) do
            count += 1
        end

        table.insert(
            lines,
            "Slot ปลดล็อก: " .. unlocked .. "/" .. #rows
        )

        table.insert(
            lines,
            "ตัวละครไม่ซ้ำใน Slot: " .. count
        )

        write(summary, table.concat(lines, "\n"))

        for _, row in ipairs(rows) do
            local index = row.index
            local slot = row.slot

            if not cards[index] then
                cards[index] = characters:AddParagraph({
                    Title = "Slot " .. index,
                    Content = "รอข้อมูล",
                })
            end

            local text

            if slot.Unlocked == false then
                text = "ยังไม่ปลดล็อก"

            elseif slot.Unlocked ~= true then
                text = "รอสถานะปลดล็อก"

            elseif type(slot.Character) ~= "string"
                or slot.Character == "" then

                text = "ไม่มีตัวละคร"

            else
                local key = slot.Character

                local info = type(data.CharactersData) == "table"
                    and data.CharactersData[key]

                local details = {
                    "Character: " .. key .. (
                        data.character == key
                            and " [สวมใส่อยู่]"
                            or ""
                    ),
                }

                if type(info) == "table" then
                    local evo = info.IsUltimateUnlocked

                    table.insert(
                        details,
                        "Evo: " .. (
                            evo == true and "Evo แล้ว"
                            or evo == false and "ยังไม่ Evo"
                            or "รอข้อมูล"
                        )
                    )

                    table.insert(
                        details,
                        "Trait: " .. traitText(info)
                    )

                    local progress = info.Progression

                    if type(progress) == "table" then
                        table.insert(
                            details,
                            "XP: " .. (
                                type(progress.Xp) == "number"
                                    and tostring(progress.Xp)
                                    or "รอข้อมูล"
                            )
                        )

                        if type(progress.Skills) == "table" then
                            local branches = {}

                            for branch, tier in pairs(progress.Skills) do
                                table.insert(
                                    branches,
                                    tostring(branch)
                                        .. ": Tier "
                                        .. tostring(tier)
                                )
                            end

                            table.sort(branches)

                            table.insert(
                                details,
                                "Skill Tree: " .. (
                                    #branches > 0
                                        and table.concat(branches, " | ")
                                        or "ไม่มีรายการ"
                                )
                            )
                        end
                    end

                    if key == "sung_jinwoo" then
                        local achievement = data.achievements

                        local stage = type(achievement) == "table"
                            and type(achievement.progress) == "table"
                            and achievement.progress["evo.sung_jinwoo"]

                        table.insert(
                            details,
                            "Monarch Stage: " .. (
                                type(stage) == "number"
                                    and tostring(stage)
                                    or "รอข้อมูล"
                            )
                        )
                    end
                else
                    table.insert(
                        details,
                        "Evo / Trait / Progression: รอข้อมูล"
                    )
                end

                text = table.concat(details, "\n")
            end

            write(cards[index], text)
        end

        for index, card in pairs(cards) do
            if not present[index] then
                write(
                    card,
                    "ไม่พบข้อมูล Slot ใน Account ปัจจุบัน"
                )
            end
        end
    end

    MacUI:OnUnload(function()
        alive = false
    end)

    task.spawn(function()
        while alive do
            -- อ่าน Account ทุก 2 วินาที เฉพาะเมื่อเปิดหน้า Home
            if Window.Shown and Tabs.Home.Selected then
                local ok, err = pcall(render)

                if not ok then
                    write(
                        summary,
                        "อ่าน Status ไม่สำเร็จ: " .. tostring(err)
                    )
                end
            end

            task.wait(2)
        end
    end)
end

--------------------------------------------------------------------------------
-- ADD YOUR FEATURES HERE
-- Use Tabs.Lobby:AddSection(...) or Window:AddTab(...) to add your own controls.
-- Register controls with unique indexes so SaveManager can save their values.
-- Add controls before LoadAutoloadConfig at the bottom of this file.
-- Connect callbacks only after the real game functions are available.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- PLAYER: Client utilities
--------------------------------------------------------------------------------
do
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local PromptService = game:GetService("ProximityPromptService")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")

    local state = {
        WalkSpeed = false,
        Speed = 32,
        InfiniteJump = false,
        Noclip = false,
        InstantPrompt = false,
        Fly = false,
        FlySpeed = 60,
        FPSBoost = false,
        UltraFPSBoost = false,
        DisableAnimations = false,
        Reconnect = false,
    }

    local alive = true
    local connections = {}
    local motionConnection
    local flight
    local watchedAnimator
    local animationConnection
    local reconnecting = false
    local reconnectToken = 0
    local renderDisabled = false
    local performanceVersion = 0

    local function WeakKeys()
        return setmetatable({}, { __mode = "k" })
    end

    local speedSaved = WeakKeys()
    local collisionSaved = WeakKeys()
    local promptSaved = WeakKeys()
    local animationSaved = WeakKeys()
    local performanceSaved = WeakKeys()

    local function Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function Report(message)
        warn("[Zero X / Player] " .. tostring(message))
        if alive and not MacUI.Unloaded then
            Window:Toast("Player", {
                Detail = tostring(message),
                Icon = "info",
            })
        end
    end

    -- เก็บค่าก่อนแก้ และคืนเฉพาะค่าที่ยังตรงกับที่ระบบนี้เขียนไว้
    local function Patch(bag, object, property, value)
        if not object then return end

        local ok, current = pcall(function()
            return object[property]
        end)
        if not ok then return end

        local properties = bag[object]
        local record = properties and properties[property]

        if current == value then
            if record then record.Applied = value end
            return
        end

        local written = pcall(function()
            object[property] = value
        end)
        if not written then return end

        if not properties then
            properties = {}
            bag[object] = properties
        end

        if not record then
            record = { Original = current }
            properties[property] = record
        end
        record.Applied = value
    end

    local function Restore(bag)
        for object, properties in pairs(bag) do
            for property, record in pairs(properties) do
                pcall(function()
                    if object[property] == record.Applied then
                        object[property] = record.Original
                    end
                end)
            end
            bag[object] = nil
        end
    end

    local function GetCharacter()
        local character = LocalPlayer.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")
        local root = humanoid and humanoid.RootPart
        return character, humanoid, root
    end

    --------------------------------------------------------------------------
    -- Fly: WASD / Space ขึ้น / LeftControl ลง
    --------------------------------------------------------------------------
    local function StopFlight()
        if not flight then return end

        local old = flight
        flight = nil

        old.Velocity:Destroy()
        old.Orientation:Destroy()
        old.Attachment:Destroy()

        pcall(function()
            if old.Humanoid.AutoRotate == false then
                old.Humanoid.AutoRotate = old.AutoRotate
            end
        end)
    end

    local function StartFlight(humanoid, root)
        StopFlight()

        local attachment = Instance.new("Attachment")
        attachment.Name = "ZeroXFlightAttachment"
        attachment.Parent = root

        local velocity = Instance.new("LinearVelocity")
        velocity.Name = "ZeroXFlightVelocity"
        velocity.Attachment0 = attachment
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        velocity.ForceLimitsEnabled = false
        velocity.VectorVelocity = Vector3.zero
        velocity.Parent = root

        local orientation = Instance.new("AlignOrientation")
        orientation.Name = "ZeroXFlightOrientation"
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Attachment0 = attachment
        orientation.MaxTorque = math.huge
        orientation.Responsiveness = 20
        orientation.CFrame = root.CFrame.Rotation
        orientation.Parent = root

        flight = {
            Root = root,
            Humanoid = humanoid,
            AutoRotate = humanoid.AutoRotate,
            Attachment = attachment,
            Velocity = velocity,
            Orientation = orientation,
        }

        humanoid.AutoRotate = false
    end

    --------------------------------------------------------------------------
    -- Animations: หยุดเวลา Animation ของตัวละครเรา และคืนความเร็วเมื่อปิด
    --------------------------------------------------------------------------
    local function FreezeTrack(track)
        if not alive or not state.DisableAnimations then return end

        pcall(function()
            if animationSaved[track] == nil then
                animationSaved[track] = track.Speed
            end
            track:AdjustSpeed(0)
        end)
    end

    local function ClearAnimations()
        if animationConnection then
            animationConnection:Disconnect()
            animationConnection = nil
        end

        watchedAnimator = nil

        for track, speed in pairs(animationSaved) do
            pcall(function()
                if track.IsPlaying and track.Speed == 0 then
                    track:AdjustSpeed(speed)
                end
            end)
            animationSaved[track] = nil
        end
    end

    local function UpdateAnimator(humanoid)
        local animator = humanoid
            and humanoid:FindFirstChildOfClass("Animator")

        if animator == watchedAnimator then return end

        ClearAnimations()
        watchedAnimator = animator

        if animator then
            animationConnection = animator.AnimationPlayed:Connect(FreezeTrack)

            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                FreezeTrack(track)
            end
        end
    end

    --------------------------------------------------------------------------
    -- Movement: มี Connection เดียวเฉพาะตอนมีฟังก์ชันที่ต้องอัปเดต
    --------------------------------------------------------------------------
    local function UpdateMotion()
        local needed = state.WalkSpeed or state.Noclip
            or state.Fly or state.DisableAnimations

        if not state.WalkSpeed then Restore(speedSaved) end
        if not state.Noclip then Restore(collisionSaved) end
        if not state.Fly then StopFlight() end
        if not state.DisableAnimations then ClearAnimations() end

        if not needed then
            if motionConnection then
                motionConnection:Disconnect()
                motionConnection = nil
            end
            return
        end

        if motionConnection then return end

        motionConnection = RunService.PreSimulation:Connect(function()
            if not alive then return end

            local character, humanoid, root = GetCharacter()

            if state.DisableAnimations then
                UpdateAnimator(humanoid)
            end

            if not humanoid or humanoid.Health <= 0 then
                StopFlight()
                return
            end

            if state.WalkSpeed then
                Patch(speedSaved, humanoid, "WalkSpeed", state.Speed)
            end

            if state.Noclip and character then
                for _, object in ipairs(character:GetDescendants()) do
                    if object:IsA("BasePart") then
                        Patch(collisionSaved, object, "CanCollide", false)
                    end
                end
            end

            if not state.Fly then return end

            if not root or not root.Parent or root.Anchored then
                StopFlight()
                return
            end

            if not flight or flight.Root ~= root
                or not flight.Velocity.Parent
                or not flight.Orientation.Parent then
                StartFlight(humanoid, root)
            end

            local camera = workspace.CurrentCamera
            local direction = Vector3.zero

            if camera and not UIS:GetFocusedTextBox() then
                local cf = camera.CFrame

                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + cf.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - cf.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + cf.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - cf.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    direction = direction + Vector3.yAxis
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    direction = direction - Vector3.yAxis
                end

                flight.Orientation.CFrame = cf.Rotation
            end

            if direction.Magnitude > 1 then
                direction = direction.Unit
            end

            flight.Velocity.VectorVelocity = direction * state.FlySpeed
        end)
    end

    Connect(LocalPlayer.CharacterRemoving, function()
        StopFlight()
        ClearAnimations()
        Restore(speedSaved)
        Restore(collisionSaved)
    end)

    Connect(UIS.JumpRequest, function()
        if not alive or not state.InfiniteJump
            or state.Fly or UIS:GetFocusedTextBox() then
            return
        end

        local _, humanoid = GetCharacter()
        if humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    --------------------------------------------------------------------------
    -- Instant Prompt: ปรับ HoldDuration ฝั่ง Client ไม่ส่ง Remote
    --------------------------------------------------------------------------
    Connect(PromptService.PromptShown, function(prompt)
        if alive and state.InstantPrompt then
            Patch(promptSaved, prompt, "HoldDuration", 0)
        end
    end)

    local function ApplyPrompts()
        if not state.InstantPrompt then
            Restore(promptSaved)
            return
        end

        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                Patch(promptSaved, object, "HoldDuration", 0)
            end
        end
    end

    --------------------------------------------------------------------------
    -- Performance: FPS = เงา/แสง, Ultra = เพิ่ม Material/Texture
    --------------------------------------------------------------------------
    local function ApplyPerformanceObject(object)
        if not (state.FPSBoost or state.UltraFPSBoost) then return end

        if object:IsA("BasePart") then
            Patch(performanceSaved, object, "CastShadow", false)

            if state.UltraFPSBoost then
                Patch(performanceSaved, object, "Material", Enum.Material.SmoothPlastic)
                Patch(performanceSaved, object, "Reflectance", 0)

                if object:IsA("MeshPart") then
                    Patch(performanceSaved, object, "TextureID", "")
                end
            end
        elseif object:IsA("Light") or object:IsA("PostEffect") then
            Patch(performanceSaved, object, "Enabled", false)
        elseif state.UltraFPSBoost then
            if object:IsA("Decal") or object:IsA("Texture") then
                Patch(performanceSaved, object, "Transparency", 1)
            elseif object:IsA("SpecialMesh") then
                Patch(performanceSaved, object, "TextureId", "")
            end
        end
    end

    local function ApplyPerformance()
        performanceVersion = performanceVersion + 1
        local version = performanceVersion

        Restore(performanceSaved)

        if not (state.FPSBoost or state.UltraFPSBoost) then return end

        Patch(performanceSaved, Lighting, "GlobalShadows", false)

        task.spawn(function()
            for _, parent in ipairs({ workspace, Lighting }) do
                for index, object in ipairs(parent:GetDescendants()) do
                    if not alive or version ~= performanceVersion then return end

                    ApplyPerformanceObject(object)

                    if index % 300 == 0 then
                        task.wait()
                    end
                end
            end
        end)
    end

    Connect(workspace.DescendantAdded, function(object)
        if not alive then return end

        ApplyPerformanceObject(object)

        if state.InstantPrompt and object:IsA("ProximityPrompt") then
            Patch(promptSaved, object, "HoldDuration", 0)
        end
    end)

    Connect(Lighting.DescendantAdded, function(object)
        if alive then ApplyPerformanceObject(object) end
    end)

    --------------------------------------------------------------------------
    -- Reconnect: เฉพาะ Kick code 267, กลับ JobId เดิม สูงสุด 3 ครั้ง
    --------------------------------------------------------------------------
    local originalPlaceId = game.PlaceId
    local originalJobId = game.JobId
    local reconnectAvailable = false
    local TryReconnect

    TryReconnect = function(attempt, token)
        if not alive or not state.Reconnect
            or token ~= reconnectToken then
            return
        end

        if attempt > 3 then
            reconnecting = false
            Report("กลับเซิร์ฟเวอร์เดิมไม่สำเร็จหลังลอง 3 ครั้ง")
            return
        end

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                originalPlaceId,
                originalJobId,
                LocalPlayer
            )
        end)

        if not ok then
            warn("[Zero X / Reconnect] " .. tostring(err))
        end

        task.delay(10, function()
            TryReconnect(attempt + 1, token)
        end)
    end

    local connected = pcall(function()
        -- ตรวจสิทธิ์อ่าน API ก่อนเปิดใช้งาน
        GuiService:GetErrorCode()

        Connect(GuiService.ErrorMessageChanged, function()
            if not alive or not state.Reconnect or reconnecting then return end

            local ok, code = pcall(function()
                return GuiService:GetErrorCode()
            end)

            if not ok or not code or code.Value ~= 267 then return end

            reconnecting = true
            reconnectToken = reconnectToken + 1
            TryReconnect(1, reconnectToken)
        end)
    end)

    reconnectAvailable = connected and originalJobId ~= ""

    Connect(LocalPlayer.OnTeleport, function(teleportState)
        if teleportState == Enum.TeleportState.InProgress then
            reconnectToken = reconnectToken + 1
            reconnecting = false
        end
    end)

    --------------------------------------------------------------------------
    -- Controls
    --------------------------------------------------------------------------
    local Movement = Tabs.Player:AddSection({
        Title = "Movement",
        Icon = "move",
    })

    local Performance = Tabs.Player:AddSection({
        Title = "Performance",
        Icon = "monitor",
    })

    local FlySection = Tabs.Player:AddSection({
        Title = "Fly",
        Icon = "send",
    })

    local Session = Tabs.Player:AddSection({
        Title = "Session",
        Icon = "refresh-cw",
    })

    local function AddStateToggle(section, index, title, key, changed)
        return section:AddToggle(index, {
            Title = title,
            Default = false,
            Callback = function(value)
                if not alive then return end
                state[key] = value
                if changed then changed() end
            end,
        })
    end

    AddStateToggle(Movement, "ZeroXWalkSpeed", "WalkSpeed",
        "WalkSpeed", UpdateMotion)

    Movement:AddSlider("ZeroXSpeed", {
        Title = "Speed",
        Min = 0,
        Max = 200,
        Default = 32,
        Increment = 1,
        Callback = function(value)
            state.Speed = value
        end,
    })

    AddStateToggle(Movement, "ZeroXInfiniteJump", "Infinite Jump",
        "InfiniteJump")

    AddStateToggle(Movement, "ZeroXNoclip", "Noclip",
        "Noclip", UpdateMotion)

    AddStateToggle(Movement, "ZeroXInstantPrompt", "Instant ProximityPrompt",
        "InstantPrompt", ApplyPrompts)

    Performance:AddToggle("ZeroXDisable3D", {
        Title = "Disable 3D Rendering",
        Default = false,
        Callback = function(value)
            if not alive then return end

            local ok, err = pcall(function()
                RunService:Set3dRenderingEnabled(not value)
            end)

            if ok then
                renderDisabled = value
            elseif value then
                Report("สภาพแวดล้อมนี้ปิด 3D Rendering ไม่ได้: " .. tostring(err))

                task.defer(function()
                    if alive and Options.ZeroXDisable3D then
                        Options.ZeroXDisable3D:SetValue(false)
                    end
                end)
            end
        end,
    })

    AddStateToggle(Performance, "ZeroXFPSBoost", "FPS Boost",
        "FPSBoost", ApplyPerformance)

    AddStateToggle(Performance, "ZeroXUltraFPSBoost", "Ultra FPS Boost",
        "UltraFPSBoost", ApplyPerformance)

    AddStateToggle(Performance, "ZeroXDisableAnimations",
        "Disable Player Animations", "DisableAnimations", UpdateMotion)

    AddStateToggle(FlySection, "ZeroXFly", "Fly",
        "Fly", UpdateMotion)

    FlySection:AddSlider("ZeroXFlySpeed", {
        Title = "Fly Speed",
        Min = 1,
        Max = 200,
        Default = 60,
        Increment = 1,
        Callback = function(value)
            state.FlySpeed = value
        end,
    })

    FlySection:AddParagraph({
        Title = "Fly controls",
        Content = "WASD: เคลื่อนที่ตามกล้อง\nSpace: ขึ้น\nLeft Ctrl: ลง",
    })

    Session:AddToggle("ZeroXReconnect", {
        Title = "Auto Reconnect on Kick",
        Default = false,
        Callback = function(value)
            if not alive then return end

            if value and not reconnectAvailable then
                Report("สภาพแวดล้อมนี้ไม่รองรับตรวจ Kick หรือไม่มี JobId")

                task.defer(function()
                    if alive and Options.ZeroXReconnect then
                        Options.ZeroXReconnect:SetValue(false)
                    end
                end)
                return
            end

            state.Reconnect = value

            if not value then
                reconnectToken = reconnectToken + 1
                reconnecting = false
            end
        end,
    })

    Session:AddToggle("ZeroXHideOnStart", {
        Title = "Hide UI On Start",
        Description = "มีผลครั้งถัดไปหลังบันทึกและตั้ง Autoload ใน Profiles",
        Default = false,
    })

    --------------------------------------------------------------------------
    -- Cleanup
    --------------------------------------------------------------------------
    MacUI:OnUnload(function()
        alive = false
        performanceVersion = performanceVersion + 1
        reconnectToken = reconnectToken + 1

        if motionConnection then
            motionConnection:Disconnect()
            motionConnection = nil
        end

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)

        StopFlight()
        ClearAnimations()
        Restore(speedSaved)
        Restore(collisionSaved)
        Restore(promptSaved)
        Restore(performanceSaved)

        if renderDisabled then
            pcall(function()
                RunService:Set3dRenderingEnabled(true)
            end)
        end
    end)
end

--------------------------------------------------------------------------------
-- LOBBY: Auto Join
--------------------------------------------------------------------------------
do
    local Section = Tabs.Lobby:AddSection({
        Title = "🚪 Auto Join",
        Description = "เลือกโหมด แมป บท และระดับความยาก "
            .. "แล้วเปิด Auto Join เพื่อเข้าห้องว่างและเริ่มเล่นอัตโนมัติ",
        Icon = "door-open",
    })

    local alive = true
    local enabled = false
    local running = false
    local revision = 0
    local cleanups = {}
    local pending = nil

    -- ค่าควบคุมการรอของสคริปต์ ไม่ใช่ Cooldown ของเกม
    local POLL_SECONDS = 1
    local ENTRY_TIMEOUT = 8
    local REQUEST_TIMEOUT = 20
    local TELEPORT_TIMEOUT = 60

    local function Report(message)
        warn("[Zero X / Lobby] " .. tostring(message))
    end

    MacUI:OnUnload(function()
        alive = false
        enabled = false
        revision = revision + 1

        for _, cleanup in ipairs(cleanups) do
            local ok, err = pcall(cleanup)
            if not ok then
                Report("Cleanup: " .. tostring(err))
            end
        end

        table.clear(cleanups)
    end)

    do
        local ok, setupError = xpcall(function()
            local RS = game:GetService("ReplicatedStorage")

            local function RequireAt(root, path)
                local object = root

                for _, name in ipairs(path) do
                    object = object and object:FindFirstChild(name)
                    assert(object, "Missing module: " .. table.concat(path, "."))
                end

                assert(object:IsA("ModuleScript"),
                    "Expected ModuleScript: " .. object:GetFullName())

                return require(object)
            end

            -- ข้อมูลสำรองสำหรับแสดงตัวเลือกเมื่ออยู่นอก Lobby
            -- อ้างอิงรายงานตรวจสอบที่ส่งมา ไม่ใช้ส่งคำขอเข้าด่าน
            local enum = {
                Gamemode = {
                    Story = {
                        Id = "Story",
                        Maps = {
                            { Id = "Hxh", Chapters = { 1, 2, 3 } },
                        },
                    },
                    Infinite = {
                        Id = "Infinite",
                        Maps = {
                            { Id = "Zzz" },
                        },
                    },
                    Raid = {
                        Id = "Raid",
                        FixedDifficulty = 4,
                        Maps = {
                            {
                                Id = "BathTub",
                                DropKey = "spiritedawayraid",
                            },
                            {
                                Id = "ShadowGate",
                                DropKey = "sololevelingraid",
                                Mode = "sololevelingraid",
                            },
                            {
                                Id = "Fate",
                                DisplayName = "Evil Reflection",
                                DropKey = "fateraid",
                                Mode = "fateraid",
                            },
                        },
                    },
                    Escape = {
                        Id = "Escape",
                        DisplayName = "Tidal High Rise",
                        FixedDifficulty = 4,

                        Maps = {
                            {
                                Id = "Flood",
                                DisplayName = "Tidal High Rise",
                                DropKey = "floodescape",
                                Mode = "floodescape",
                            },
                        },
                    },
                    Trials = {
                        Id = "Trials",
                        Maps = {
                            { Id = "Trials", Floors = true },
                        },
                    },
                },
            }

            local packets = nil
            local roomsNamespace = nil
            local raidConfig = nil

            -- โหลดข้อมูลจริงเฉพาะใน Lobby
            if ZeroXContext.IsLobby() then
                enum = RequireAt(RS, {
                    "lobby", "enums", "gamemodeSelectEnum",
                })

                packets = RequireAt(RS, {
                    "lobby", "packets",
                })

                roomsNamespace = RequireAt(RS, {
                    "lobby", "stores", "ququeRoomStore",
                })

                raidConfig = RequireAt(RS, {
                    "assets", "config", "RaidAttemptsConfig",
                })

                assert(type(enum) == "table"
                    and type(enum.Gamemode) == "table",
                    "Gamemode config unavailable")

                assert(type(raidConfig) == "table"
                    and type(raidConfig.IsLimited) == "function"
                    and type(raidConfig.Attribute) == "function",
                    "RaidAttemptsConfig API unavailable")

                assert(roomsNamespace.namespace
                    and type(roomsNamespace.namespace.getStore) == "function",
                    "ququeRoomStore namespace unavailable")

                for _, name in ipairs({
                    "createQuque",
                    "startQuqueNow",
                }) do
                    assert(packets[name]
                        and type(packets[name].fire) == "function",
                        name .. ".fire unavailable")
                end
            end

            local function Listen(name, callback)
                if not ZeroXContext.IsLobby() then
                    return
                end

                local packet = packets[name]

                assert(packet and type(packet.on) == "function",
                    name .. ".on unavailable")

                local handle = packet:on(function(...)
                    if alive then
                        callback(...)
                    end
                end)

                if typeof(handle) == "function" then
                    table.insert(cleanups, handle)
                elseif typeof(handle) == "RBXScriptConnection" then
                    table.insert(cleanups, function()
                        handle:Disconnect()
                    end)
                else
                    error("Unsupported listener handle: " .. name)
                end
            end

            local windowRoom = nil
            local queueStatus = nil

            Listen("toggleQuqueWindow", function(payload)
                if type(payload) ~= "table" then return end

                windowRoom = payload.open
                    and tonumber(payload.roomNumber) or nil
            end)

            Listen("updateClientQuqueStatus", function(status)
                if type(status) ~= "string" then return end

                queueStatus = status

                if pending then
                    if status == "inQuque" then
                        pending.Accepted = true
                    elseif status == "idle" and pending.Accepted then
                        pending.Finished = true
                    end
                end
            end)

            ------------------------------------------------------------------
            -- Runtime config: รองรับเฉพาะ Mode ที่ตรวจสอบ Schema แล้ว
            ------------------------------------------------------------------
            local supported = {
                Story = true,
                Infinite = true,
                Raid = true,
                Trials = true,
                Escape = true,
            }

            local modes = {}
            local modeIds = {}

            for _, definition in pairs(enum.Gamemode) do
                if type(definition) == "table"
                    and supported[definition.Id]
                    and type(definition.Maps) == "table" then

                    assert(not modes[definition.Id],
                        "Duplicate Mode ID: " .. definition.Id)

                    modes[definition.Id] = definition
                    table.insert(modeIds, definition.Id)
                end
            end

            table.sort(modeIds)
            assert(#modeIds > 0, "No supported Modes found")

            -- ใช้ DisplayName จาก Config จริงก่อน
            -- ชื่อสำรองใช้เมื่ออยู่นอก Lobby ตามรายงานที่ยืนยันแล้ว
            local verifiedModeNames = {
                Story = "Story",
                Infinite = "Infinite",
                Raid = "Raid",
                Trials = "Trials",
                Escape = "Tidal High Rise",
            }

            local verifiedMapNames = {
                Hxh = "Hxh",
                Zzz = "ZZZ World",
                BathTub = "Spirit's Bathtub",
                ShadowGate = "Shadow Gate",
                Fate = "Evil Reflection",
                Trials = "Trials",
                Flood = "Tidal High Rise",
            }

            local function DisplayName(definition, verified)
                local name = definition.DisplayName

                if type(name) == "string" and name ~= "" then
                    return name
                end

                return verified[definition.Id] or definition.Id
            end

            local modeLabels = {}
            local modeLabelById = {}

            for _, id in ipairs(modeIds) do
                local definition = modes[id]
                local label = DisplayName(
                    definition,
                    verifiedModeNames
                )

                assert(
                    not modes[label] or modes[label] == definition,
                    "Duplicate Mode display name: " .. label
                )

                -- รองรับทั้งชื่อที่แสดงและ ID ที่ระบบเดิมใช้อยู่
                modeLabelById[id] = label
                modes[label] = definition
                table.insert(modeLabels, label)
            end

            table.sort(modeLabels)

            -- Mapping ยืนยันจาก Handler ตามรายงานตรวจสอบ
            local difficultyNames = {
                "Easy", "Medium", "Hard", "Nightmare",
            }

            local modeControl
            local mapControl
            local chapterControl
            local chapterIdsByLabel = {}
            local difficultyControl
            local syncQueued = false
            local syncing = false

            local function GetMaps(mode)
                local ids = {}
                local lookup = {}

                for _, map in pairs(mode.Maps) do
                    if type(map) == "table"
                        and type(map.Id) == "string"
                        and map.Id ~= "" then

                        assert(
                            not lookup[map.Id],
                            "Duplicate Map ID: " .. map.Id
                        )

                        lookup[map.Id] = map
                        table.insert(ids, map.Id)
                    end
                end

                assert(#ids > 0, "No Maps: " .. mode.Id)

                local labels = {}

                for _, id in ipairs(ids) do
                    local map = lookup[id]
                    local label = DisplayName(
                        map,
                        verifiedMapNames
                    )

                    assert(
                        not lookup[label] or lookup[label] == map,
                        "Duplicate Map display name: " .. label
                    )

                    -- ชื่อใน Dropdown และ ID ชี้ไปที่ Map เดียวกัน
                    lookup[label] = map
                    table.insert(labels, label)
                end

                table.sort(labels)

                return labels, lookup
            end

            local function SetChoices(control, values)
                local previous = control.Value
                control:SetValues(values)

                local selected = table.find(values, previous)
                    and previous or values[1]

                if control.Value ~= selected then
                    control:SetValue(selected)
                end
            end

            local function SyncChoices()
                if not alive or not modeControl or not mapControl
                    or not chapterControl or not difficultyControl then
                    return
                end

                local mode = modes[modeControl.Value]
                assert(mode, "Selected Mode unavailable")

                local ids, lookup = GetMaps(mode)
                SetChoices(mapControl, ids)

                local map = lookup[mapControl.Value]
                assert(map, "Selected Map unavailable")

                local chapters = {}
                chapterIdsByLabel = {}

                if map.Floors == true then
                    -- เกมไม่มี Act list สำหรับ Trials
                    chapters = { "Floors" }
                    chapterIdsByLabel.Floors = 0
                else
                    -- ชื่อ fallback ตาม Handler ของเกม
                    local actTitles = {
                        Story = "Story",
                        Defend = "Defense",
                        Infinite = "Endless Waves",
                        Raid = "Raid",
                    }

                    for _, value in ipairs(map.Chapters or { 1 }) do
                        local chapter = tonumber(value)

                        assert(
                            chapter and chapter % 1 == 0
                                and chapter >= 1 and chapter <= 127,
                            "Invalid Chapter in config"
                        )

                        local title = type(map.ActNames) == "table"
                            and map.ActNames[chapter]

                        if type(title) ~= "string" or title == "" then
                            title = actTitles[mode.Id]
                                or mode.DisplayName
                                or verifiedModeNames[mode.Id]
                                or mode.Id
                        end

                        assert(
                            type(title) == "string" and title ~= "",
                            "Invalid Act title"
                        )

                        local label = ("Act %d - %s"):format(
                            chapter,
                            title
                        )

                        if chapterIdsByLabel[label] == nil then
                            chapterIdsByLabel[label] = chapter
                            table.insert(chapters, label)
                        end
                    end

                    assert(#chapters > 0, "Empty Chapters config")

                    table.sort(chapters, function(left, right)
                        return chapterIdsByLabel[left]
                            < chapterIdsByLabel[right]
                    end)
                end

                SetChoices(chapterControl, chapters)

                if map.Floors == true then
                    SetChoices(difficultyControl, { difficultyNames[1] })
                elseif mode.FixedDifficulty ~= nil then
                    local name = difficultyNames[mode.FixedDifficulty]
                    assert(name, "Unsupported FixedDifficulty")
                    SetChoices(difficultyControl, { name })
                else
                    SetChoices(difficultyControl, difficultyNames)
                end
            end

            local function ScheduleSync()
                if syncing or syncQueued or not alive then return end

                syncQueued = true

                task.defer(function()
                    if not alive then return end

                    syncing = true
                    local success, err = pcall(SyncChoices)
                    syncing = false
                    syncQueued = false

                    if not success then Report(err) end
                end)
            end

            modeControl = Section:AddDropdown("ZeroXLobbyMode", {
                Title = "Mode",
                Description = "เลือกประเภทการเล่น เช่น Story, Infinite, Raid หรือ Trials",
                Values = modeLabels,
                Default = modeLabelById.Story or modeLabels[1],
                Callback = ScheduleSync,
            })

            mapControl = Section:AddDropdown("ZeroXLobbyMap", {
                Title = "Map",
                Description = "เลือกแมปที่จะเข้า รายการเปลี่ยนตาม Mode ที่เลือก",
                Values = {},
                AllowNull = true,
                Callback = ScheduleSync,
            })

            chapterControl = Section:AddDropdown("ZeroXLobbyChapter", {
                Title = "Chapter",
                Description = "เลือก Act ตามชื่อที่เกมแสดง; Trials ใช้ Floors",
                Values = {},
                AllowNull = true,
            })

            difficultyControl = Section:AddDropdown("ZeroXLobbyDifficulty", {
                Title = "Difficulty",
                Description = "เลือกระดับความยาก โดย Raid ล็อกตามเกม และ Trials ใช้ Easy",
                Values = difficultyNames,
                Default = "Easy",
            })

            syncing = true
            SyncChoices()
            syncing = false

            ------------------------------------------------------------------
            -- Queue room discovery
            ------------------------------------------------------------------
            local function ReadRoom(number)
                local store = roomsNamespace.namespace:getStore(
                    "room " .. tostring(number)
                )

                assert(store and type(store.toTable) == "function",
                    "Room store unavailable: " .. tostring(number))

                local data = store:toTable()
                assert(type(data) == "table", "Invalid room snapshot")

                return data
            end

            local function FindEmptyRoom()
                local systems = workspace:FindFirstChild("Systems")
                local rooms = systems and systems:FindFirstChild("QuqueRooms")

                assert(rooms, "Workspace.Systems.QuqueRooms unavailable")

                local candidates = {}

                for _, room in ipairs(rooms:GetChildren()) do
                    local number = tonumber(room.Name)
                    local inside = room:FindFirstChild("Inside")
                    local hitbox = room:FindFirstChild("JoinHitbox")

                    if number and number % 1 == 0
                        and number >= 1 and number <= 8
                        and inside and inside:IsA("BasePart")
                        and hitbox and hitbox:IsA("BasePart") then

                        table.insert(candidates, {
                            Number = number,
                            Inside = inside,
                            Hitbox = hitbox,
                        })
                    end
                end

                table.sort(candidates, function(a, b)
                    return a.Number < b.Number
                end)

                for _, room in ipairs(candidates) do
                    if ReadRoom(room.Number).status == "idle" then
                        return room
                    end
                end

                return nil
            end

            local function Active(token)
                return alive
                    and enabled
                    and token == revision
                    and ZeroXContext.IsLobby()
                    and not ZeroXContext.DeliveryRequested()
            end

            local function BuildPayload(room)
                SyncChoices()

                local craft = ZeroXContext.EvolveRoute or ZeroXContext.CraftRoute

                local mode = modes[
                    craft and craft.Mode or modeControl.Value
                ]

                assert(mode, "Selected Mode unavailable")

                local _, lookup = GetMaps(mode)

                local map = lookup[
                    craft and craft.Map or mapControl.Value
                ]

                assert(map, "Selected Map unavailable")

                do
                    local raidKey = map.Mode or map.DropKey

                    if raidKey ~= nil then
                        assert(type(raidKey) == "string",
                            "Invalid Raid key")
                    end

                    if raidKey and raidConfig.IsLimited(raidKey) then
                        local attributeName = raidConfig.Attribute(
                            "Left", raidKey
                        )

                        assert(type(attributeName) == "string"
                            and attributeName ~= "",
                            "Invalid Raid attribute name")

                        local remaining = LocalPlayer:GetAttribute(
                            attributeName
                        )

                        -- ตาม Handler: Attribute ยังไม่มี = 0 รอบ
                        if remaining == nil then
                            remaining = 0
                        end

                        assert(type(remaining) == "number"
                            and remaining == remaining,
                            "Invalid Raid attempts: " .. attributeName)

                        assert(remaining > 0, string.format(
                            "Raid is on cooldown | Map=%s | %s=%s",
                            tostring(map.Id),
                            attributeName,
                            tostring(remaining)
                        ))
                    end
                end

                local difficulty = craft and craft.Difficulty
                    or map.Floors == true and 1
                    or mode.FixedDifficulty
                    or table.find(difficultyNames, difficultyControl.Value)

                assert(type(difficulty) == "number"
                    and difficulty % 1 == 0
                    and difficulty >= 1 and difficulty <= 4,
                    "Invalid Difficulty")

                local chapter = 0

                if map.Chapters then
                    if craft then
                        -- เส้นทาง Craft / Evolve ใช้ ID เดิม
                        chapter = tonumber(craft.Chapter)
                    else
                        chapter =
                            chapterIdsByLabel[chapterControl.Value]
                            or tonumber(chapterControl.Value)
                    end
                end

                assert(chapter and chapter % 1 == 0
                    and chapter >= 0 and chapter <= 127,
                    "Invalid Chapter")

                return {
                    gamemode = mode.Id,
                    map = map.Id,
                    chapter = chapter,
                    floor = map.Floors == true and 1 or 0,
                    difficulty = difficulty,
                    maxPlayers = 1,
                    friendsOnly = false,
                    roomNumber = room.Number,
                }
            end

            local function EnterAndCreate(room, token)
                local character = LocalPlayer.Character
                local humanoid = character
                    and character:FindFirstChildOfClass("Humanoid")
                local root = character
                    and character:FindFirstChild("HumanoidRootPart")

                if not humanoid or humanoid.Health <= 0
                    or not root or not root:IsA("BasePart") then
                    return
                end

                -- ตรวจ Payload ก่อนย้ายตัวละคร
                BuildPayload(room)

                if not Active(token)
                    or ReadRoom(room.Number).status ~= "idle" then
                    return
                end

                windowRoom = nil
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = CFrame.new(
                    room.Inside.Position + Vector3.new(0, 2, 0)
                ) * root.CFrame.Rotation

                local deadline = os.clock() + ENTRY_TIMEOUT
                local confirmed = false

                repeat
                    if not Active(token) then return end

                    assert(LocalPlayer.Character == character
                        and root.Parent and humanoid.Parent
                        and humanoid.Health > 0
                        and room.Inside.Parent and room.Hitbox.Parent,
                        "Character or queue room changed during entry")

                    local registered = tonumber(
                        LocalPlayer:GetAttribute("QueueRoom")
                    )

                    assert(registered == nil or registered == room.Number,
                        "Player entered a different queue room")

                    confirmed = registered == room.Number
                        or windowRoom == room.Number

                    if confirmed then break end

                    task.wait(0.1)
                until os.clock() >= deadline

                assert(confirmed,
                    "Room entry timeout: " .. tostring(room.Number))

                if not Active(token) then return end

                assert(not LocalPlayer:GetAttribute("MatchSearching"),
                    "MatchSearching is already active")

                -- อ่านค่าล่าสุดอีกครั้งหลังช่วงรอ
                local payload = BuildPayload(room)

                if not Active(token) then return end

                -- ล็อกก่อน fire: หากส่งแล้วเกิด Error จะไม่ยิงซ้ำอัตโนมัติ
                pending = {
                    Room = room.Number,
                    SentAt = os.clock(),
                    Accepted = false,
                    Finished = false,
                    StartSent = false,
                }

                packets.createQuque:fire(payload)

                print(string.format(
                    "[Zero X / Lobby] Create | %s / %s"
                        .. " | Chapter=%d Difficulty=%d Room=%d",
                    payload.gamemode,
                    payload.map,
                    payload.chapter,
                    payload.difficulty,
                    payload.roomNumber
                ))
            end

            ------------------------------------------------------------------
            -- มี Worker เดียว และยกเลิกงานเก่าด้วย revision
            ------------------------------------------------------------------
            local function Step(token)
                if pending then
                    if pending.Finished
                        and LocalPlayer:GetAttribute("QueueRoom") == nil
                        and not LocalPlayer:GetAttribute("MatchSearching") then

                        pending = nil
                        return
                    end

                    local registered = tonumber(
                        LocalPlayer:GetAttribute("QueueRoom")
                    )

                    if queueStatus == "inQuque"
                        and registered == pending.Room then

                        pending.Accepted = true

                        if not pending.StartSent
                            and LocalPlayer:GetAttribute("QueueLeader") == true
                            and not LocalPlayer:GetAttribute("MatchSearching")
                            and Active(token) then

                            pending.StartSent = true
                            packets.startQuqueNow:fire()

                            print("[Zero X / Lobby] Start | Room:",
                                pending.Room)
                        end
                    end

                    local timeout = pending.Accepted
                        and TELEPORT_TIMEOUT or REQUEST_TIMEOUT

                    assert(os.clock() - pending.SentAt < timeout,
                        "Queue response/teleport timeout; request not resent")

                    return
                end

                -- ไม่สร้างแทรกคิวที่ผู้เล่นเข้าร่วมอยู่แล้ว
                if LocalPlayer:GetAttribute("QueueRoom") ~= nil
                    or LocalPlayer:GetAttribute("QueueLeader") == true
                    or LocalPlayer:GetAttribute("MatchSearching") then
                    return
                end

                local room = FindEmptyRoom()

                if room then
                    EnterAndCreate(room, token)
                end
            end

            local function StartWorker()
                if running or not alive then return end
                running = true

                task.spawn(function()
                    task.wait()

                    while alive and enabled do
                        -- เปิด Toggle ค้างได้ แต่ไม่เริ่มงานนอก Lobby
                        if not ZeroXContext.IsLobby()
                            or ZeroXContext.DeliveryRequested()
                            or ZeroXContext.LobbyOwner ~= nil
                            or (
                                (
                                    ZeroXContext.CraftingRequested()
                                    or ZeroXContext.EvolvingRequested()
                                )
                                and not (
                                    ZeroXContext.EvolveRoute
                                    or ZeroXContext.CraftRoute
                                )
                                and not pending
                                and LocalPlayer:GetAttribute("QueueRoom") == nil
                            ) then

                            task.wait(POLL_SECONDS)
                            continue
                        end

                        local token = revision

                        ZeroXContext.LobbyOwner = "AutoJoin"
                        local success, err = pcall(Step, token)

                        if ZeroXContext.LobbyOwner == "AutoJoin" then
                            ZeroXContext.LobbyOwner = nil
                        end

                        if not success and Active(token) then
                            enabled = false
                            Report(err)

                            local toggle = Options.ZeroXLobbyAutoJoin

                            if toggle then
                                toggle:SetValue(false)
                            end
                        end

                        if alive and enabled then
                            task.wait(POLL_SECONDS)
                        end
                    end

                    running = false
                end)
            end

            Section:AddToggle("ZeroXLobbyAutoJoin", {
                Title = "Auto Join",
                Default = false,
                Callback = function(value)
                    if not alive then return end

                    enabled = value
                    revision = revision + 1

                    if enabled then
                        StartWorker()
                    end
                end,
            })
        end, function(err)
            return debug.traceback(tostring(err), 2)
        end)

        if not ok then
            enabled = false
            alive = false
            revision = revision + 1

            for _, cleanup in ipairs(cleanups) do
                local cleaned, cleanupError = pcall(cleanup)

                if not cleaned then
                    Report("Cleanup failed: " .. tostring(cleanupError))
                end
            end

            table.clear(cleanups)
            Report("Setup failed:\n" .. tostring(setupError))

            -- หยุดไฟล์รอบนี้ ป้องกัน Error ซ้ำจากการสร้าง UI ต่อ
            return
        end
    end
end
--------------------------------------------------------------------------------
-- LOBBY: Auto Delivery Quest
--------------------------------------------------------------------------------
do
    local Delivery = Tabs.Lobby:AddSection({
        Title = "Delivery Quest",
        Description = "รับพัสดุ ส่งให้ NPC เป้าหมาย "
            .. "และรับรางวัลอัตโนมัติจนถึงโควต้าประจำวัน",
        Icon = "package",
    })

    do
        local alive = true
        local enabled = false
        local running = false
        local revision = 0
        local requestId = 0

        local packets = nil
        local disconnectState = nil
        local state = nil
        local stateVersion = 0
        local stateError = nil

        -- เวลารอและระยะของสคริปต์ ไม่ใช่ค่ารัศมีตรวจส่งของของ Server
        local RESPONSE_TIMEOUT = 15
        local DELIVERY_TIMEOUT = 30
        local TARGET_OFFSET = 3
        local CHECK_INTERVAL = 0.25

        local knownStatus = {
            none = true,
            carrying = true,
            delivered = true,
            capped = true,
        }

        local function Report(message)
            warn("[Zero X / Delivery] " .. tostring(message))
        end

        local function Active(token)
            return alive
                and enabled
                and revision == token
                and ZeroXContext.IsLobby()
        end

        local function Stop(message)
            enabled = false
            revision = revision + 1

            if message then
                Report(message)
            end

            local toggle = Options.ZeroXAutoDeliveryQuest

            if alive and toggle and toggle.Value then
                toggle:SetValue(false)
            end
        end

        local function Initialize()
            if packets then return end

            local RS = game:GetService("ReplicatedStorage")
            local lobby = RS:FindFirstChild("lobby")
            local module = lobby and lobby:FindFirstChild("packets")

            assert(module and module:IsA("ModuleScript"),
                "ReplicatedStorage.lobby.packets unavailable")

            local api = require(module)

            assert(api and api.deliveryAction
                and type(api.deliveryAction.fire) == "function",
                "deliveryAction.fire unavailable")

            assert(api.deliveryState
                and type(api.deliveryState.on) == "function",
                "deliveryState.on unavailable")

            if not alive then return end

            local handle = api.deliveryState:on(function(payload)
                if not alive then return end

                if type(payload) ~= "table"
                    or not knownStatus[payload.status]
                    or type(payload.target) ~= "string"
                    or type(payload.dailyCount) ~= "number"
                    or type(payload.dailyLimit) ~= "number"
                    or payload.dailyCount < 0
                    or payload.dailyLimit < 0
                    or payload.dailyCount % 1 ~= 0
                    or payload.dailyLimit % 1 ~= 0 then

                    stateError = "Invalid deliveryState payload"
                    return
                end

                stateError = nil

                -- เก็บ Snapshot ไม่แก้ไขตารางที่ Packet ส่งมา
                state = {
                    status = payload.status,
                    target = payload.target,
                    targetLabel = payload.targetLabel,
                    dailyCount = payload.dailyCount,
                    dailyLimit = payload.dailyLimit,
                    reason = payload.reason,
                }

                stateVersion = stateVersion + 1
            end)

            if typeof(handle) == "function" then
                disconnectState = handle
            elseif typeof(handle) == "RBXScriptConnection" then
                disconnectState = function()
                    handle:Disconnect()
                end
            else
                error("Unsupported deliveryState listener handle")
            end

            packets = api
        end

        local function WaitUntil(token, timeout, predicate, label)
            local deadline = os.clock() + timeout

            repeat
                if not Active(token) then return false end

                assert(not stateError, stateError)

                if predicate() then
                    return true
                end

                task.wait(CHECK_INTERVAL)
            until os.clock() >= deadline

            if not Active(token) then return false end

            error(string.format(
                "%s timeout | Status=%s Target=%s Reason=%s",
                label,
                state and state.status or "unknown",
                state and state.target or "",
                state and tostring(state.reason) or ""
            ))
        end

        local function SendAction(action, token, accepted)
            if not Active(token) then return false end

            local previousVersion = stateVersion

            requestId = requestId % 65535 + 1

            -- ส่งครั้งเดียว แล้วรอ State ไม่ยิงซ้ำระหว่างรอ
            packets.deliveryAction:fire({
                action = action,
                requestId = requestId,
            })

            return WaitUntil(token, RESPONSE_TIMEOUT, function()
                return stateVersion > previousVersion
                    and state ~= nil
                    and accepted(state)
            end, "Action " .. action)
        end

        local function GetSystems()
            return workspace:FindFirstChild("Systems")
        end

        local function GetTargetRoot(targetName)
            local systems = GetSystems()
            if not systems then return nil end

            local npcs = systems:FindFirstChild("NPCS")
            local scattered = systems:FindFirstChild("ScatteredNPCS")

            local npc = npcs and npcs:FindFirstChild(targetName)

            if not npc and scattered then
                npc = scattered:FindFirstChild(targetName)
            end

            local root = npc and npc:FindFirstChild("HumanoidRootPart")

            if root and root:IsA("BasePart") then
                return root
            end

            return nil
        end

        local function GetQuestZone()
            local systems = GetSystems()
            local zones = systems and systems:FindFirstChild("Zones")
            local zone = zones and zones:FindFirstChild("Quest")

            if zone and zone:IsA("BasePart") then
                return zone
            end

            return nil
        end

        local function GetCharacterRoot()
            local character = LocalPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0
                and root and root:IsA("BasePart")
                and root.Parent and not root.Anchored then

                return root
            end

            return nil
        end

        local function MoveToPosition(position, token)
            if not Active(token) then return false end

            local root = GetCharacterRoot()
            if not root then return false end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(position) * root.CFrame.Rotation

            return true
        end

        local function VisitGiver(token)
            return WaitUntil(token, RESPONSE_TIMEOUT, function()
                local zone = GetQuestZone()
                local giver = GetTargetRoot("Heiyun")
                local root = GetCharacterRoot()

                if not zone or not giver or not root then
                    return false
                end

                -- ใช้กลางโซนจริง โดยอิงระดับความสูงจาก NPC
                local localGiver = zone.CFrame:PointToObjectSpace(
                    giver.Position
                )

                local halfHeight = zone.Size.Y * 0.5

                local position = zone.CFrame:PointToWorldSpace(
                    Vector3.new(
                        0,
                        math.clamp(localGiver.Y, -halfHeight, halfHeight),
                        0
                    )
                )

                return MoveToPosition(position, token)
            end, "Visit quest giver")
        end

        local function Deliver(token)
            local started = os.clock()

            while Active(token) do
                assert(not stateError, stateError)
                assert(state, "Delivery state unavailable")

                if state.status ~= "carrying" then
                    return true
                end

                assert(os.clock() - started < DELIVERY_TIMEOUT,
                    "Delivery timeout; target=" .. tostring(state.target))

                local target = GetTargetRoot(state.target)
                local root = GetCharacterRoot()

                -- ค้นใหม่เมื่อ NPC ยังไม่โหลดหรือถูกแทนที่
                if target and root then
                    local destination = (
                        target.CFrame * CFrame.new(TARGET_OFFSET, 0, 0)
                    ).Position

                    if (root.Position - destination).Magnitude > 1 then
                        MoveToPosition(destination, token)
                    end
                end

                -- สำเร็จจาก deliveryState ของ Server เท่านั้น
                task.wait(CHECK_INTERVAL)
            end

            return false
        end

        local function Run(token)
            Initialize()
            if not Active(token) then return end

            -- รับ State ล่าสุดทุกครั้งที่เปิด Toggle
            if not SendAction("refresh", token, function()
                return true
            end) then
                return
            end

            while Active(token) do
                assert(not stateError, stateError)
                assert(state, "Delivery state unavailable")

                if state.status == "delivered" then
                    if not VisitGiver(token) then return end

                    -- เวลาพักหลังย้ายตัวละคร ไม่ใช่การยืนยันตำแหน่งฝั่ง Server
                    task.wait(0.5)

                    if not Active(token) then return end

                    -- ขอ State ล่าสุดและรอคำตอบก่อน Claim
                    if not SendAction("refresh", token, function()
                        return true
                    end) then
                        return
                    end

                    if not Active(token) then return end
                    assert(state, "Delivery state unavailable after refresh")

                    -- ตรวจอีกครั้ง เผื่อมีการรับรางวัลไปแล้วระหว่างรอ
                    if state.status == "delivered" then
                        local previousCount = state.dailyCount

                        print(string.format(
                            "[Zero X / Delivery] Claim requested | Count=%d/%d",
                            state.dailyCount,
                            state.dailyLimit
                        ))

                        if not SendAction("claim", token, function(updated)
                            return updated.status == "none"
                                or updated.status == "capped"
                        end) then
                            return
                        end

                        print(string.format(
                            "[Zero X / Delivery] Claim acknowledged"
                                .. " | Status=%s | Count=%d -> %d",
                            state.status,
                            previousCount,
                            state.dailyCount
                        ))
                    end

                elseif state.status == "capped"
                    or state.dailyCount >= state.dailyLimit then

                    Stop(string.format(
                        "Daily limit reached: %d/%d",
                        state.dailyCount,
                        state.dailyLimit
                    ))
                    return

                elseif state.status == "none" then
                    if not VisitGiver(token) then return end

                    if not SendAction("request", token, function(updated)
                        return updated.status == "carrying"
                            or updated.status == "delivered"
                            or updated.status == "capped"
                    end) then
                        return
                    end

                elseif state.status == "carrying" then
                    if not Deliver(token) then return end
                end

                task.wait(CHECK_INTERVAL)
            end
        end

        local function StartWorker()
            if running or not alive then return end
            running = true

            task.spawn(function()
                task.wait()

                while alive and enabled do
                    -- รอพื้นที่ที่รองรับและไม่แย่งการเคลื่อนที่กับคิว
                    if not ZeroXContext.IsLobby()
                        or ZeroXContext.LobbyOwner ~= nil
                        or LocalPlayer:GetAttribute("QueueRoom") ~= nil
                        or LocalPlayer:GetAttribute("QueueLeader") == true
                        or LocalPlayer:GetAttribute("MatchSearching") then

                        task.wait(1)
                        continue
                    end

                    local token = revision

                    ZeroXContext.LobbyOwner = "Delivery"
                    local ok, err = pcall(Run, token)

                    if ZeroXContext.LobbyOwner == "Delivery" then
                        ZeroXContext.LobbyOwner = nil
                    end

                    if not ok and Active(token) then
                        Stop(err)
                    end

                    if alive and enabled then
                        task.wait(0.5)
                    end
                end

                running = false
            end)
        end

        Delivery:AddToggle("ZeroXAutoDeliveryQuest", {
            Title = "Auto Delivery Quest",
            Description = "รับงาน ย้ายไปส่งของ และรับรางวัลอัตโนมัติ",
            Default = false,
            Callback = function(value)
                if not alive then return end

                enabled = value
                revision = revision + 1

                if enabled then
                    StartWorker()
                end
            end,
        })

        MacUI:OnUnload(function()
            alive = false
            enabled = false
            revision = revision + 1

            if disconnectState then
                local ok, err = pcall(disconnectState)
                disconnectState = nil

                if not ok then
                    Report("Cleanup failed: " .. tostring(err))
                end
            end

            state = nil
        end)
    end
end

-- INSERT this complete block before:
-- -- Keep the original settings folders and custom theme loading.
-- Requires Tabs.InGame (add its tab in the existing Tabs table).
-- Combat code extracted from the supplied Anime Zero.lua.
do
    local FarmSection = Tabs.InGame:AddSection({
        Title = "Auto Farm",
        Description = "ฟาร์มมอน ใช้สกิล จัดการ Rubble และสถานะ Raid จากระบบเดิม",
        Icon = "swords",
    })

    local alive = true
    local generation = 0
    local stopCurrent = nil

    local function Report(message)
        warn("[Zero X / Auto Farm] " .. tostring(message))
    end

    local function StopCurrent()
        local cleanup = stopCurrent
        stopCurrent = nil
        if cleanup then cleanup() end
    end

    local function CreateFarm()
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        assert(PlayerGui, "PlayerGui unavailable")

        local AutoFarmSession = { Cancelled = false, Cleanups = {} }
        local RuntimeFix = { TravelSpeed = 60 }
        local StopAutoFarm
        local collisionSaved = {}
        local autoRotateSaved = {}

        -- Original source suppresses combat print output.
        local print = function() end
        local warningAt = {}
        local function warn(message, ...)
            local key = tostring(message)
            local now = os.clock()
            if now - (warningAt[key] or -math.huge) >= 5 then
                warningAt[key] = now
                warn("[Zero X / Auto Farm]", message, ...)
            end
        end

        local function RememberCharacter(character)
            if not character then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and autoRotateSaved[humanoid] == nil then
                autoRotateSaved[humanoid] = humanoid.AutoRotate
            end
            for _, object in ipairs(character:GetDescendants()) do
                if object:IsA("BasePart") and collisionSaved[object] == nil then
                    collisionSaved[object] = object.CanCollide
                end
            end
        end

        local function Cleanup()
            if AutoFarmSession.Cancelled then return end
            AutoFarmSession.Cancelled = true

            if StopAutoFarm then
                local ok, err = pcall(StopAutoFarm)
                if not ok then Report("Stop: " .. tostring(err)) end
            end

            for index = #AutoFarmSession.Cleanups, 1, -1 do
                local cleanup = AutoFarmSession.Cleanups[index]
                AutoFarmSession.Cleanups[index] = nil
                local ok, err = pcall(cleanup)
                if not ok then Report("Cleanup: " .. tostring(err)) end
            end

            for part, value in pairs(collisionSaved) do
                if part.Parent then
                    local ok, err = pcall(function() part.CanCollide = value end)
                    if not ok then Report(err) end
                end
            end
            for humanoid, value in pairs(autoRotateSaved) do
                if humanoid.Parent then
                    local ok, err = pcall(function() humanoid.AutoRotate = value end)
                    if not ok then Report(err) end
                end
            end
            table.clear(collisionSaved)
            table.clear(autoRotateSaved)
        end

        stopCurrent = Cleanup

        local function Spawn(callback)
            task.spawn(function()
                local ok, err = xpcall(callback, function(message)
                    return debug.traceback(tostring(message), 2)
                end)
                if not ok and not AutoFarmSession.Cancelled then
                    Cleanup()
                    Report(err)
                    task.defer(function()
                        if alive and stopCurrent == Cleanup then
                            local control = Options.ZeroXAutoFarm
                            if control then control:SetValue(false) end
                        end
                    end)
                end
            end)
        end

        function RuntimeFix.requireModule(root, path)
            local object = root
            for _, name in ipairs(path) do
                object = object and object:FindFirstChild(name)
                assert(object, "Module unavailable: " .. table.concat(path, "."))
            end
            assert(object:IsA("ModuleScript"), "Expected ModuleScript")
            return require(object)
        end

        local function AZEnabled(section, key)
            return section == "Combat" and key == "AutoSkills"
                and Options.ZeroXAutoFarmSkills ~= nil
                and Options.ZeroXAutoFarmSkills.Value == true
        end

        local ResolveGameplay

    local EnemyCountLabel = nil

    local RaidTag = PlayerGui:FindFirstChild("RunSide")
        and PlayerGui.RunSide:FindFirstChild("Container")
        and PlayerGui.RunSide.Container:FindFirstChild("Tag")

    local SkillsFolder = nil

    --// World
    local AreasFolder = nil
    local MapFolder = nil

    --// Attack
    local PerformM1 = nil

    --// Settings
    local BELOW_DEPTH = 6 -- อยู่ต่ำกว่า Root ของมอน 5 studs
    local ORBIT_RADIUS = 4
    local ORBIT_SECONDS_PER_REVOLUTION = 4
    -- ระยะจากผิว Rubble ถึง HumanoidRootPart
    local RUBBLE_BEHIND_GAP = 8

    -- ความสูง Y ของ HumanoidRootPart ในโลก
    local RUBBLE_ROOT_Y = 8
    local AREA_HEIGHT_OFFSET = 3

    local POSITION_RESPONSIVENESS = 80
    local ORIENTATION_RESPONSIVENESS = 80

    local TARGET_REFRESH_DELAY = 0.10
    local RUBBLE_ATTACK_DELAY = 0.12
    local ATTACK_DELAY = 0.12
    local NO_ENEMY_RETELEPORT_DELAY = 1.0
    local SKILL_ACTIVATION_RETRY_DELAY = 0.75
    local RAID_START_POSITION = Vector3.new(-136, 4, -48)

    local RAID_STATE_REFRESH_DELAY = 0.15
    local ELEVATOR_RETRY_DELAY = 0.75
    local RAID_RETELEPORT_DELAY = 1.0
    local HEAL_RETREAT_HEIGHT = 15
    local HEAL_START_PERCENT = 30
    local HEAL_RESUME_PERCENT = 70

    local AUTO_ROLL_RESULT_TIMEOUT = 30

    local AUTO_ROLL_TARGETS = {
        sukuna = "Cursed King",
        miyabi = "Cataclysm",
    }

    --// State
    local AutoFarmEnabled = false
    local CustomAutoRollEnabled = false
    local AutoRedeemCodesEnabled = false
    local AutoUnlockSlotsEnabled = false
    local AutoUpgradeSkillTreeEnabled = false
    local AutoEquipBestTitleEnabled = false
    local AutoCraftBlastArcherEnabled = false
    local BlastArcherCraftCompleted = false
    local UnlockCharacterSlotRequestId = 1
    local EquipCharacterSlotRequestId = 1
    local SukunaEvoFarmStarted = false
    local SukunaEvolveTriggered = false
    local PurchaseCharacterSkillRequestId = 0
    local CurrentTarget = nil
    local CurrentAreaName = nil
    local LastTeleportedArea = nil
    local LastLoggedStatus = nil
    local LastNoEnemyTeleport = 0
    local LastSkillActivation = {}
    local SkillAimState = nil

    local SKILL_AIM_NORMAL_TIME = 0.85
    local SKILL_AIM_DELAYED_TIME = 2.65
    local SKILL_AIM_REFRESH = 0.04
    local LastRaidStatus = nil
    local LastElevatorAction = 0
    local LastRaidStartTeleport = 0
    local isInRaid
    local IsHealing = false
    local CurrentRubble = nil
    local CurrentRubbleArea = nil
    local RubbleTeleported = false
    local RubbleModeActive = false

    local HoverConnection = nil
    local AlignPosition = nil
    local AlignOrientation = nil
    local RootAttachment = nil

    --==================================================
    -- Character
    --==================================================

    local function getCharacter()
        return LocalPlayer.Character
    end

    local function getCharacterRoot()
        local character = getCharacter()

        if not character then
            return nil
        end

        return character:FindFirstChild("HumanoidRootPart")
    end

    local function getHumanoid()
        local character = getCharacter()

        if not character then
            return nil
        end

        return character:FindFirstChildOfClass("Humanoid")
    end

    --==================================================
    -- Health
    --==================================================

    local function getHealthPercent()
        local humanoid = getHumanoid()

        if not humanoid or humanoid.MaxHealth <= 0 then
            return 0
        end

        return math.round(
            humanoid.Health / humanoid.MaxHealth * 100
        )
    end

    --==================================================
    -- Area
    --==================================================

    local function getSingleAreaPart()
        local activeArea = nil

        for _, candidate in ipairs(AreasFolder:GetChildren()) do
            if candidate:IsA("BasePart") then
                if activeArea then
                    return nil
                end

                activeArea = candidate
            end
        end

        return activeArea
    end

    local function getAreaByPosition(position)
        if not position then
            return nil
        end

        for _, area in ipairs(AreasFolder:GetChildren()) do
            if area:IsA("BasePart") then
                local point = area.CFrame:PointToObjectSpace(position)
                local halfSize = area.Size / 2

                if math.abs(point.X) <= halfSize.X
                    and math.abs(point.Y) <= halfSize.Y
                    and math.abs(point.Z) <= halfSize.Z
                then
                    if isInRaid
                        and isInRaid()
                        and CurrentAreaName
                        and getSingleAreaPart() == area
                    then
                        return {
                            Name = tostring(CurrentAreaName),
                            Position = area.Position,
                            Size = area.Size,
                            CFrame = area.CFrame,
                        }
                    end

                    return area
                end
            end
        end

        return nil
    end

    local function getCurrentArea()
        local root = getCharacterRoot()

        if not root then
            return nil
        end

        local area = getAreaByPosition(root.Position)

        return area and area.Name or nil
    end

    local function isShadowGateRaid()
        return workspace:GetAttribute("Mode") == "sololevelingraid"
            and isInRaid ~= nil
            and isInRaid() == true
    end

    local function isFateRaid()
        return workspace:GetAttribute("Mode") == "fateraid"
    end

    local function isRaidBossGuarded()
        return (isShadowGateRaid() or isFateRaid()) and (
            workspace:GetAttribute("RaidBossGuarded") == true
            or (
                tonumber(workspace:GetAttribute("RaidOathCount"))
                or 0
            ) > 0
        )
    end

    local farmRunStore = nil

    local function getLiveFarmArea()
        local ok, area = pcall(function()
            if not farmRunStore then
                farmRunStore = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    {"game", "stores", "runStore"}
                )
            end

            local state = farmRunStore
                and farmRunStore.store
                and farmRunStore.store.state

            if not state or not state.area then
                return nil
            end

            local value = state.area:get()

            if type(value) ~= "number"
                or value < 1
                or value % 1 ~= 0
            then
                return nil
            end

            return tostring(value)
        end)

        return ok and area or nil
    end

    local function getAreaFromStatus(text)
        if type(text) ~= "string" then
            return nil
        end

        local area = text:match("[Aa]rea%s*(%d+)%s*/%s*%d+")
        if area then
            -- HUD อาจยังแสดง Area เก่า ให้ใช้ Store สดก่อน
            return getLiveFarmArea() or area
        end

        if isShadowGateRaid() or isFateRaid() then
            return getLiveFarmArea() or "1"
        end

        return "Infinite"
    end

    local function getAreaPart(areaName)
        if not areaName
            or not AreasFolder
            or not AreasFolder.Parent
        then
            return nil
        end

        local area = AreasFolder:FindFirstChild(tostring(areaName))

        if area and area:IsA("BasePart") then
            return area
        end

        if not (isInRaid and isInRaid()) then
            return nil
        end

        -- Raid ที่มี Area Part เดียว:
        -- คืน Instance จริง เพื่อให้ตรวจ Parent ได้
        local activeArea = getSingleAreaPart()

        if activeArea and activeArea.Parent then
            return activeArea
        end

        return nil
    end

    --==================================================
    -- Enemy
    --==================================================

    local function isEnemyAlive(enemy)
        if not enemy or not enemy.Parent then
            return false
        end

        local humanoid = enemy:FindFirstChildOfClass("Humanoid")

        if humanoid then
            return humanoid.Health > 0
        end

        return true
    end

    local function getEnemyRoot(enemy)
        if not enemy or not enemy:IsA("Model") then
            return nil
        end

        local root = enemy:FindFirstChild("HumanoidRootPart")

        if not root or not root:IsA("BasePart") then
            return nil
        end

        return root
    end

    local fateEnemyModules

    local function readFateEnemy(enemy)
        if not enemy or not enemy:IsA("Model") then
            return nil
        end

        local id = tonumber(enemy.Name)

        if not id then
            return nil
        end

        if not fateEnemyModules then
            local store = RuntimeFix.requireModule(
                ReplicatedStorage,
                { "game", "stores", "enemyStore" }
            )

            local definitions = RuntimeFix.requireModule(
                ReplicatedStorage,
                { "global", "constants", "enemies" }
            )

            assert(
                store.store and store.store.state,
                "Fate enemyStore unavailable"
            )

            assert(
                type(definitions.enemiesByName) == "table",
                "Fate enemiesByName unavailable"
            )

            fateEnemyModules = {
                state = store.store.state,
                definitions = definitions.enemiesByName,
            }
        end

        local state = fateEnemyModules.state
        local entry

        if type(state.get) == "function" then
            entry = state:get(id)
        elseif state.entries then
            entry = state.entries[id]
        end

        if not entry or not entry.name
            or type(entry.name.get) ~= "function" then

            return nil
        end

        local key = entry.name:get()

        if type(key) ~= "string" then
            return nil
        end

        local definition = fateEnemyModules.definitions[key]

        if type(definition) ~= "table" then
            return nil
        end

        return key, definition.boss == true
    end

    local function getFateTarget(areaName)
        local enemies = workspace:FindFirstChild("enemies")
        local root = getCharacterRoot()

        if not enemies or not root
            or not getAreaPart(areaName) then

            return nil
        end

        local guarded = isRaidBossGuarded()

        local oath
        local minion
        local boss

        local oathDistance = math.huge
        local minionDistance = math.huge
        local bossDistance = math.huge

        for _, enemy in ipairs(enemies:GetChildren()) do
            if not enemy:IsA("Model")
                or not isEnemyAlive(enemy) then

                continue
            end

            local enemyRoot = getEnemyRoot(enemy)

            if not enemyRoot then
                continue
            end

            local area = getAreaByPosition(enemyRoot.Position)

            if not area
                or tostring(area.Name) ~= tostring(areaName) then

                continue
            end

            local key, isBoss = readFateEnemy(enemy)

            -- ข้อมูลยังไม่มา ให้รอ ไม่เดาจาก HP/Shield
            if not key then
                continue
            end

            local distance =
                (root.Position - enemyRoot.Position).Magnitude

            if guarded and key == "fateOath"
                and distance < oathDistance then

                oath = enemy
                oathDistance = distance
            end

            if isBoss then
                if distance < bossDistance then
                    boss = enemy
                    bossDistance = distance
                end
            elseif distance < minionDistance then
                minion = enemy
                minionDistance = distance
            end
        end

        if oath then
            return oath
        end

        if minion then
            return minion
        end

        if not guarded then
            return boss
        end

        return nil
    end

    local KnownBossNames = {
        spiritedkaonashi = true,
        spiritedkaonashi2 = true,
        kaonashi = true,
        ["no-face"] = true,
        noface = true,
        hisoka = true,
        meruem = true,
        pucci = true,
        chrollo = true,
        takamura = true,
        uzuki = true,
        gaku = true,
        shadowking = true,
    }

    local function isEnemyBoss(enemy: Instance): boolean
        if not enemy then return false end

        if isFateRaid() then
            local _, boss = readFateEnemy(enemy)
            return boss == true
        end

        -- 1. Check custom attributes or tags on Model
        if enemy:GetAttribute("Boss") == true or enemy:GetAttribute("IsBoss") == true then
            return true
        end

        -- 2. Check model name or child names (like Boss, BossHealth, etc.)
        local lowerModelName = string.lower(enemy.Name)
        if string.find(lowerModelName, "boss") then
            return true
        end
        for k in pairs(KnownBossNames) do
            if string.find(lowerModelName, k) then
                return true
            end
        end
        if enemy:FindFirstChild("Boss") or enemy:FindFirstChild("Shield") or enemy:FindFirstChild("ForceField") then
            return true
        end

        -- 3. Check enemyStore metadata
        local ok, isBoss = pcall(function()
            local enemyStore = require(ReplicatedStorage.game.stores.enemyStore)
            local enemyId = tonumber(enemy.Name)
            if enemyId and enemyStore and enemyStore.store and enemyStore.store.state and enemyStore.store.state.entries then
                local entry = enemyStore.store.state.entries[enemyId]
                if entry and entry.name then
                    local eName = string.lower(tostring(entry.name.get and entry.name:get() or entry.name))
                    if KnownBossNames[eName] or string.find(eName, "kaonashi") or string.find(eName, "boss") then
                        return true
                    end
                    -- Bosses typically have guardedAt or high maxHealth (>= 5000)
                    local mHp = entry.maxHealth and (entry.maxHealth.get and entry.maxHealth:get() or entry.maxHealth) or 0
                    if entry.guardedAt or (tonumber(mHp) or 0) >= 4000 then
                        return true
                    end
                end
            end
            return false
        end)

        if ok and isBoss then
            return true
        end

        return false
    end

    local function isShadowGateMainBoss(enemy)
        return enemy ~= nil
            and enemy:IsA("Model")
            and enemy.Name == "0"
    end

    local function hasMinionsAliveInArea(areaName): boolean
        local enemies = workspace:FindFirstChild("enemies")

        if not enemies then
            return false
        end

        local shadowGate = isShadowGateRaid()
        local isInfinite = areaName == "Infinite"

        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:IsA("Model") and isEnemyAlive(enemy) then
                local isBoss

                if shadowGate then
                    isBoss = isShadowGateMainBoss(enemy)
                else
                    isBoss = isEnemyBoss(enemy)
                end

                if not isBoss then
                    local root = getEnemyRoot(enemy)

                    if root then
                        if isInfinite then
                            return true
                        end

                        local area = getAreaByPosition(root.Position)

                        if area
                            and tostring(area.Name) == tostring(areaName)
                        then
                            return true
                        end
                    end
                end
            end
        end

        return false
    end

    local function getNearestEnemyInArea(areaName)
        if isFateRaid() then
            return getFateTarget(areaName)
        end

        local enemies = workspace:FindFirstChild("enemies")

        if not enemies then
            return nil
        end

        local characterRoot = getCharacterRoot()

        if not characterRoot then
            return nil
        end

        local isInfinite = (areaName == "Infinite")
        local targetArea = nil
        
        if not isInfinite then
            targetArea = getAreaPart(areaName)
            if not targetArea then
                return nil
            end
        end

        local validEnemies = {}
        local shadowGate = isShadowGateRaid()

        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:IsA("Model") and isEnemyAlive(enemy) then
                local enemyRoot = getEnemyRoot(enemy)

                if enemyRoot then
                    local isValid = false
                    
                    if isInfinite then
                        isValid = true
                    else
                        local enemyArea = getAreaByPosition(enemyRoot.Position)
                        if enemyArea and tostring(enemyArea.Name) == tostring(areaName) then
                            isValid = true
                        end
                    end

                    if isValid then
                        local distance =
                            (characterRoot.Position - enemyRoot.Position).Magnitude
                        local isBoss

                        if shadowGate then
                            isBoss = isShadowGateMainBoss(enemy)
                        else
                            isBoss = isEnemyBoss(enemy)
                        end

                        table.insert(validEnemies, {
                            model = enemy,
                            distance = distance,
                            isBoss = isBoss
                        })
                    end
                end
            end
        end

        if #validEnemies == 0 then
            print("[AutoFarm] No Enemy In Area:", areaName)
            return nil
        end

        -- Priority rule: If there are minions alive, target nearest minion first.
        -- Only attack boss when ALL minions are dead!
        local nearestMinion = nil
        local nearestMinionDist = math.huge
        local nearestBoss = nil
        local nearestBossDist = math.huge

        for _, data in ipairs(validEnemies) do
            if data.isBoss then
                if data.distance < nearestBossDist then
                    nearestBossDist = data.distance
                    nearestBoss = data.model
                end
            else
                if data.distance < nearestMinionDist then
                    nearestMinionDist = data.distance
                    nearestMinion = data.model
                end
            end
        end

        local bossGuarded = shadowGate and (
            workspace:GetAttribute("RaidBossGuarded") == true
            or (tonumber(workspace:GetAttribute("RaidOathCount")) or 0) > 0
        )

        local chosenEnemy = nearestMinion

        if not chosenEnemy and not bossGuarded then
            chosenEnemy = nearestBoss
        end

        local targetType = nearestMinion and "Minion" or "Boss"

        if chosenEnemy then
            print(string.format("[AutoFarm] Enemy Found -> Area %s | Type: %s | Target: %s",
                tostring(areaName), targetType, chosenEnemy:GetFullName()
            ))
        end

        return chosenEnemy
    end

    --==================================================
    -- Root Tween Helper
    --==================================================

    RuntimeFix.TravelSpeed = 80 -- studs ต่อวินาที

    function RuntimeFix.tweenRootTo(targetCFrame, canContinue)
        local character = getCharacter()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()

        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or not character
            or not root
            or not root.Parent
            or not humanoid
            or humanoid.Health <= 0
        then
            return false
        end

        if canContinue and not canContinue() then
            return false
        end

        -- จบงานเดิมพร้อมคืนค่าก่อนเริ่มงานใหม่
        if RuntimeFix.RootTweenCleanup then
            RuntimeFix.RootTweenCleanup()
        end

        local previous = RuntimeFix.ActiveRootTween
        RuntimeFix.ActiveRootTween = nil

        if previous then
            previous:Cancel()
        end

        local originalAutoRotate = humanoid.AutoRotate
        local rubbleForce = RuntimeFix.RubbleFloatForce
        local originalForceEnabled = nil

        if rubbleForce and rubbleForce.Parent then
            originalForceEnabled = rubbleForce.Enabled
            rubbleForce.Enabled = false
        end

        root.Anchored = false
        humanoid.AutoRotate = false
        humanoid:Move(Vector3.zero, false)

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        -- ชดเชยแรงโน้มถ่วงเฉพาะระหว่างเดินทาง
        local attachment = Instance.new("Attachment")
        attachment.Name = "AutoTravelAttachment"
        attachment.Parent = root

        local lift = Instance.new("VectorForce")
        lift.Name = "AutoTravelLift"
        lift.Attachment0 = attachment
        lift.RelativeTo = Enum.ActuatorRelativeTo.World
        lift.ApplyAtCenterOfMass = true
        lift.Parent = root

        local distance =
            (root.Position - targetCFrame.Position).Magnitude

        local speed = math.max(RuntimeFix.TravelSpeed, 1)
        local duration = distance / speed

        local tween = game:GetService("TweenService"):Create(
            root,
            TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.InOut
            ),
            { CFrame = targetCFrame }
        )

        local cleaned = false
        local cleanup

        cleanup = function()
            if cleaned then
                return
            end

            cleaned = true

            if RuntimeFix.RootTweenCleanup == cleanup then
                RuntimeFix.RootTweenCleanup = nil
            end

            if RuntimeFix.ActiveRootTween == tween then
                RuntimeFix.ActiveRootTween = nil
            end

            tween:Cancel()
            tween:Destroy()
            lift:Destroy()
            attachment:Destroy()

            if rubbleForce
                and rubbleForce.Parent
                and RuntimeFix.RubbleFloatForce == rubbleForce
                and originalForceEnabled ~= nil
            then
                rubbleForce.Enabled = originalForceEnabled
            end

            if getCharacter() == character and humanoid.Parent then
                humanoid.AutoRotate = originalAutoRotate
            end
        end

        RuntimeFix.RootTweenCleanup = cleanup
        RuntimeFix.ActiveRootTween = tween

        local arrived = false

        local ok, err = pcall(function()
            local function updateLift()
                local mass = root.AssemblyMass

                if root.Anchored or mass <= 0 or mass == math.huge then
                    error("Travel assembly is anchored or has invalid mass")
                end

                lift.Force = Vector3.new(
                    0,
                    mass * workspace.Gravity,
                    0
                )
            end

            updateLift()
            tween:Play()

            local deadline = os.clock() + duration + 2

            while not cleaned
                and RuntimeFix.ActiveRootTween == tween
                and not AutoFarmSession.Cancelled
                and AutoFarmEnabled
                and not RuntimeFix.EndRoundPaused
                and getCharacter() == character
                and root.Parent
                and humanoid.Parent
                and humanoid.Health > 0
                and os.clock() < deadline
            do
                if canContinue and not canContinue() then
                    break
                end

                if tween.PlaybackState == Enum.PlaybackState.Completed then
                    arrived =
                        (root.Position - targetCFrame.Position).Magnitude <= 3
                    break
                end

                if tween.PlaybackState == Enum.PlaybackState.Cancelled then
                    break
                end

                updateLift()
                task.wait(0.05)
            end
        end)

        cleanup()

        if not ok then
            warn("[AutoTween] Failed:", err)
            return false
        end

        return arrived
    end

    --==================================================
    -- Cleanup Hover
    --==================================================

    -- โหมดทดลอง: ร่างจริงอยู่เหนือมอน ร่างปลอมอยู่ใกล้มอน
    local function stopHover()
        RuntimeFix.FloodGroundStand = nil
        RuntimeFix.FloodHolding = nil

        if RuntimeFix.FloodPrompt then
            pcall(function()
                RuntimeFix.FloodPrompt:InputHoldEnd()
            end)

            RuntimeFix.FloodPrompt = nil
        end

        if RuntimeFix.RootTweenCleanup then
            RuntimeFix.RootTweenCleanup()
        end

        local activeTween = RuntimeFix.ActiveRootTween
        RuntimeFix.ActiveRootTween = nil

        if activeTween then
            activeTween:Cancel()
        end

        RuntimeFix.RubbleRepeatToken = nil

        local rubbleForce = RuntimeFix.RubbleFloatForce
        RuntimeFix.RubbleFloatForce = nil

        if rubbleForce then
            rubbleForce:Destroy()
        end

        local rubbleAttachment = RuntimeFix.RubbleFloatAttachment
        RuntimeFix.RubbleFloatAttachment = nil

        if rubbleAttachment then
            rubbleAttachment:Destroy()
        end

        local waiting = RuntimeFix.WaitingStand
        RuntimeFix.WaitingStand = nil

        if waiting and waiting.Root and waiting.Root.Parent then
            waiting.Root.CanCollide = waiting.WasCanCollide
        end

        local idleHold = RuntimeFix.IdleHold
        RuntimeFix.IdleHold = nil

        if idleHold then
            local heldRoot = idleHold.Root

            if heldRoot and heldRoot.Parent then
                heldRoot.Anchored = idleHold.WasAnchored
                heldRoot.AssemblyLinearVelocity = Vector3.zero
                heldRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end

        if HoverConnection then
            HoverConnection:Disconnect()
            HoverConnection = nil
        end

        if AlignPosition then
            AlignPosition:Destroy()
            AlignPosition = nil
        end

        if AlignOrientation then
            AlignOrientation:Destroy()
            AlignOrientation = nil
        end

        if RootAttachment then
            RootAttachment:Destroy()
            RootAttachment = nil
        end

        CurrentTarget = nil

        local humanoid = getHumanoid()

        if humanoid then
            humanoid.AutoRotate = true
        end
    end

    local function holdStillWhileWaiting(areaName)
        if AutoFarmSession.Cancelled or not AutoFarmEnabled then
            return false
        end

        local character = getCharacter()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()

        if not character
            or not root
            or not root.Parent
            or not humanoid
            or humanoid.Health <= 0
            or not AreasFolder
            or not AreasFolder.Parent
        then
            return false
        end

        local areaKey = tostring(areaName)

        if getNearestEnemyInArea(areaKey) then
            stopHover()
            return false
        end

        local areaPart = getAreaPart(areaName)

        if not areaPart then
            -- แจ้งโดยไม่พิมพ์ซ้ำทุก Tick
            if RuntimeFix.WaitingAreaMissing ~= areaKey then
                RuntimeFix.WaitingAreaMissing = areaKey
                warn("[AutoFarm] Waiting area unavailable:", areaKey)
            end
            return false
        end

        RuntimeFix.WaitingAreaMissing = nil

        local now = os.clock()
        local waiting = RuntimeFix.WaitingStand

        local repeatTeleportSeconds = 1

        if waiting
            and waiting.Root == root
            and waiting.Area == areaKey
            and now - waiting.LastTeleportAt < repeatTeleportSeconds
        then
            return true
        end

        -- ครบเวลาแล้วทำขั้นตอนวาร์ปกลาง Area ด้านล่างอีกครั้ง

        stopHover()

        local wasCanCollide = root.CanCollide
        local targetPosition =
            areaPart.Position + Vector3.new(0, AREA_HEIGHT_OFFSET, 0)

        humanoid:Move(Vector3.zero, false)
        humanoid.AutoRotate = true
        root.CanCollide = true

        local arrived = RuntimeFix.tweenRootTo(
            CFrame.new(targetPosition),
            function()
                local correctArea =
                    areaKey == "Infinite"
                    or getLiveFarmArea() == areaKey

                return areaPart.Parent ~= nil
                    and correctArea
                    and tostring(CurrentAreaName) == areaKey
                    and not RuntimeFix.EndRoundPaused
                    and getNearestEnemyInArea(areaKey) == nil
            end
        )

        if not arrived then
            if root.Parent then
                root.CanCollide = wasCanCollide
            end

            return false
        end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        RuntimeFix.WaitingStand = {
            Root = root,
            Area = areaKey,
            WasCanCollide = wasCanCollide,
            LastTeleportAt = os.clock(),
        }

        print(
            "[AutoFarm] Waiting Stand -> Area:",
            areaKey,
            "| Target:",
            targetPosition,
            "| Actual:",
            root.Position
        )

        return true
    end

    --==================================================
    -- Create Smooth Hover
    --==================================================

    local function startHover(enemy, hoverHeight, retreatMode)
        local character = getCharacter()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()
        local enemyRoot = getEnemyRoot(enemy)

        if AutoFarmSession.Cancelled
            or not character
            or not root
            or not humanoid
            or not enemyRoot
            or not isEnemyAlive(enemy)
        then
            return false
        end

        -- ค่าตำแหน่งตอนใช้สกิล
        local SKILL_BEHIND_GAP = 6
        local SKILL_BEHIND_Y = 0
        local SKILL_MOVE_DEBUG = true

        local skillState

        do
            local ok, result = pcall(function()
                local store = RuntimeFix.requireModule(
                    LocalPlayer,
                    {
                        "PlayerScripts",
                        "global",
                        "stores",
                        "localPlayerStore",
                    }
                )

                local state = store and store.state
                local skill = state and state.skill

                if not skill
                    or not skill.pending
                    or not skill.till
                    or not skill.slot
                then
                    error("localPlayerStore.state.skill unavailable")
                end

                -- ตรวจว่าอ่านได้ก่อนสร้าง Hover
                local pending = skill.pending:get()
                local till = skill.till:get()

                if type(pending) ~= "boolean"
                    or type(till) ~= "number"
                then
                    error("Invalid skill pending/till")
                end

                return skill
            end)

            if not ok then
                warn("[AutoFarm] Skill state unavailable:", result)
                return false
            end

            if AutoFarmSession.Cancelled or not AutoFarmEnabled then
                return false
            end

            skillState = result
        end

        local lastSkillMode = nil

        local function isUsingSkill()
            return skillState ~= nil
                and (
                    skillState.pending:get() == true
                    or skillState.till:get() > workspace:GetServerTimeNow()
                )
        end

        -- ไม่เริ่ม Tween / Pivot / เปลี่ยนเป้าหมายระหว่างร่ายสกิล
        if isUsingSkill() then
            return false
        end

        local floodContext =
            RuntimeFix.isFlood() and RuntimeFix.floodKey()

        -- ค่าตำแหน่งตอนใช้สกิล
        local TARGET_TWEEN_DISTANCE = 100
        local useBathTween =
            workspace:GetAttribute("Mode") == "spiritedawayraid"
            or RuntimeFix.isFlood()

        -- เก็บก่อน stopHover ล้าง CurrentTarget
        local changingTarget =
            not retreatMode and CurrentTarget ~= enemy

        stopHover()

        CurrentTarget = enemy

        local height = hoverHeight or BELOW_DEPTH
        local radius = retreatMode and 0 or math.max(0, ORBIT_RADIUS)

        local angularSpeed =
            (math.pi * 2) / math.max(0.5, ORBIT_SECONDS_PER_REVOLUTION)

        -- เริ่มวงโคจรจากด้านที่ตัวละครอยู่
        local offset = root.Position - enemyRoot.Position
        local angle = math.atan2(offset.Z, offset.X)

        local function getRawPosition(targetRoot, usingSkill)
            local center = targetRoot.Position

            -- คงตำแหน่งถอยฟื้นเลือดเดิม
            if retreatMode then
                return center + Vector3.new(
                    math.cos(angle) * radius,
                    height,
                    math.sin(angle) * radius
                )
            end

            -- คงตำแหน่งด้านหลังขณะใช้สกิลตามระบบเดิม
            if usingSkill then
                local forward = targetRoot.CFrame.LookVector
                    * Vector3.new(1, 0, 1)

                if forward.Magnitude < 0.001 then
                    forward = Vector3.new(0, 0, -1)
                else
                    forward = forward.Unit
                end

                return center
                    - forward * SKILL_BEHIND_GAP
                    + Vector3.new(0, SKILL_BEHIND_Y, 0)
            end

            local positionOption = Options.ZeroXFarmPosition
            local heightOption = Options.ZeroXFarmHeight
            local distanceOption = Options.ZeroXFarmDistance

            local mode = positionOption and positionOption.Value or "Orbit"

            local selectedHeight = math.clamp(
                tonumber(heightOption and heightOption.Value)
                    or math.abs(BELOW_DEPTH),
                1,
                30
            )

            if mode == "Below" then
                return center + Vector3.new(0, -selectedHeight, 0)
            elseif mode == "Above" then
                return center + Vector3.new(0, selectedHeight, 0)
            end

            local selectedRadius = math.clamp(
                tonumber(distanceOption and distanceOption.Value)
                    or ORBIT_RADIUS,
                0,
                30
            )

            return center + Vector3.new(
                math.cos(angle) * selectedRadius,
                selectedHeight,
                math.sin(angle) * selectedRadius
            )
        end

        local function getPosition(targetRoot, usingSkill)
            local position = RuntimeFix.floodSafe(
                getRawPosition(targetRoot, usingSkill)
            )

            local gate = RuntimeFix.FloodCombatGate

            if gate and gate.Parent then
                return RuntimeFix.floodGatePosition(position, gate)
                    or RuntimeFix.floodSafe(gate.Position)
            end

            return position
        end

        local function getFacing(position, center)
            local direction = center - position

            if direction.Magnitude < 0.001 then
                return root.CFrame.Rotation
            end

            -- เลี่ยง up vector ขนานกับทิศมองตอนลอยตรงเหนือเป้าหมาย
            local up = Vector3.yAxis
            if math.abs(direction.Unit:Dot(up)) > 0.98 then
                up = Vector3.zAxis
            end

            return CFrame.lookAt(Vector3.zero, direction.Unit, up)
        end

        local initialPosition = getPosition(enemyRoot, isUsingSkill())
        local initialFacing = getFacing(
            initialPosition,
            enemyRoot.Position
        )

        if changingTarget or useBathTween then
            -- ถ้ามอนเคลื่อนหนีไกลระหว่างทาง ให้คำนวณจุดใหม่
            while (
                useBathTween
                and (root.Position - initialPosition).Magnitude > 3
            ) or (
                not useBathTween
                and (root.Position - enemyRoot.Position).Magnitude
                    > TARGET_TWEEN_DISTANCE
            ) do
                print(
                    "[AutoFarm] Target far -> Tween:",
                    enemy:GetFullName(),
                    "| Distance:",
                    math.floor((root.Position - enemyRoot.Position).Magnitude)
                )

                local arrived = RuntimeFix.tweenRootTo(
                    CFrame.new(initialPosition) * initialFacing,
                    function()
                        local targetRoot = getEnemyRoot(enemy)

                        if (
                            floodContext
                            and RuntimeFix.floodKey() ~= floodContext
                        )
                            or CurrentTarget ~= enemy
                            or not isEnemyAlive(enemy)
                            or not targetRoot
                            or not targetRoot.Parent
                        then
                            return false
                        end

                        -- ตรวจระหว่าง Tween ไปหาบอส Shadow Gate หรือ Fate
                        if not retreatMode
                            and (
                                (
                                    isShadowGateRaid()
                                    and isShadowGateMainBoss(enemy)
                                )
                                or (
                                    isFateRaid()
                                    and isEnemyBoss(enemy)
                                )
                            )
                        then
                            local hasMinions = CurrentAreaName ~= nil
                                and hasMinionsAliveInArea(CurrentAreaName)

                            local bossGuarded =
                                workspace:GetAttribute("RaidBossGuarded") == true
                                or (
                                    tonumber(workspace:GetAttribute("RaidOathCount"))
                                    or 0
                                ) > 0

                            if hasMinions or bossGuarded then
                                print(
                                    "[AutoFarm] Cancel boss Tween ->",
                                    hasMinions
                                        and "Minions detected: switching target"
                                        or "Boss guarded: waiting for minions"
                                )

                                return false
                            end
                        end

                        return true
                    end
                )

                if not arrived then
                    if CurrentTarget == enemy then
                        stopHover()
                    end
                    return false
                end

                enemyRoot = getEnemyRoot(enemy)

                if AutoFarmSession.Cancelled
                    or getCharacter() ~= character
                    or not root.Parent
                    or not humanoid.Parent
                    or humanoid.Health <= 0
                    or CurrentTarget ~= enemy
                    or not enemyRoot
                    or not enemyRoot.Parent
                    or not isEnemyAlive(enemy)
                then
                    if CurrentTarget == enemy then
                        stopHover()
                    end
                    return false
                end

                initialPosition = getPosition(enemyRoot, isUsingSkill())
                initialFacing = getFacing(
                    initialPosition,
                    enemyRoot.Position
                )
            end
        end

        if not useBathTween then
            local pivotOffset =
                root.CFrame:ToObjectSpace(character:GetPivot())

            character:PivotTo(
                CFrame.new(initialPosition) * initialFacing * pivotOffset
            )
        end

        humanoid.AutoRotate = false

        RootAttachment = Instance.new("Attachment")
        RootAttachment.Name = "AutoFarmHoverAttachment"
        RootAttachment.Parent = root

        AlignPosition = Instance.new("AlignPosition")
        AlignPosition.Name = "AutoFarmHoverPosition"
        AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPosition.Attachment0 = RootAttachment
        AlignPosition.Position = initialPosition
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = POSITION_RESPONSIVENESS
        AlignPosition.RigidityEnabled = false
        AlignPosition.Parent = root

        AlignOrientation = Instance.new("AlignOrientation")
        AlignOrientation.Name = "AutoFarmHoverOrientation"
        AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        AlignOrientation.Attachment0 = RootAttachment
        AlignOrientation.CFrame = initialFacing
        AlignOrientation.MaxTorque = math.huge
        AlignOrientation.Responsiveness = ORIENTATION_RESPONSIVENESS
        AlignOrientation.RigidityEnabled = false
        AlignOrientation.Parent = root

        local positionAlign = AlignPosition
        local orientationAlign = AlignOrientation
        local connection

        connection = RunService.Heartbeat:Connect(function(deltaTime)
            if HoverConnection ~= connection then
                connection:Disconnect()
                return
            end

            -- ปล่อยให้สกิลควบคุมการเคลื่อนที่และทิศทาง
            -- รวมถึงข้ามการดึงกลับเข้าเขต Gate ระหว่างสกิล
            if not AutoFarmSession.Cancelled
                and AutoFarmEnabled
                and getCharacter() == character
                and root.Parent
                and humanoid.Parent
                and humanoid.Health > 0
                and RuntimeFix.pauseFarmForSkill()
            then
                return
            end

            if (
                floodContext
                and RuntimeFix.floodKey() ~= floodContext
            )
                or AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or getCharacter() ~= character
                or not root.Parent
                or not humanoid.Parent
                or humanoid.Health <= 0
                or CurrentTarget ~= enemy
                or not isEnemyAlive(enemy)
                or not positionAlign.Parent
                or not orientationAlign.Parent
            then
                stopHover()
                return
            end

            local currentEnemyRoot = getEnemyRoot(enemy)

            if not currentEnemyRoot or not currentEnemyRoot.Parent then
                stopHover()
                return
            end

            local aimLocked =
                SkillAimState ~= nil
                and SkillAimState.target == enemy
                and os.clock() < SkillAimState.expires

            local usingSkill = not retreatMode and isUsingSkill()

            local positionOption = Options.ZeroXFarmPosition
            local positionMode = positionOption
                and positionOption.Value or "Orbit"

            if not retreatMode
                and not usingSkill
                and not aimLocked
                and positionMode == "Orbit" then

                local speedOption = Options.ZeroXFarmOrbitSpeed
                local degreesPerSecond = math.clamp(
                    tonumber(speedOption and speedOption.Value)
                        or (360 / math.max(0.5, ORBIT_SECONDS_PER_REVOLUTION)),
                    0,
                    360
                )

                angularSpeed = math.rad(degreesPerSecond)

                angle = (
                    angle + angularSpeed * math.min(deltaTime, 0.1)
                ) % (math.pi * 2)
            end

            local center = currentEnemyRoot.Position
            local targetPosition = getPosition(currentEnemyRoot, usingSkill)

            -- ดึงกลับเข้าเขตเฉพาะเมื่อถูกผลักหรือสกิลพาออกไป
            local gate = RuntimeFix.FloodCombatGate

            if gate and gate.Parent
                and (root.Position - gate.Position).Magnitude > 18 then

                local bounded = RuntimeFix.floodGatePosition(
                    root.Position,
                    gate
                )

                if bounded then
                    root.CFrame =
                        CFrame.new(bounded) * root.CFrame.Rotation

                    root.AssemblyLinearVelocity = Vector3.zero
                end
            end

            local facing = getFacing(root.Position, center)
            local trackingStationary = false

            if usingSkill then
                local movementLock =
                    root:FindFirstChild("SkillMovementLock")

                if movementLock and movementLock:IsA("Attachment") then
                    local gamePosition =
                        movementLock:FindFirstChildOfClass("AlignPosition")

                    -- ใช้เฉพาะแรงตรึงตำแหน่งของสกิลตามโครงสร้างที่ตรวจพบ
                    if gamePosition
                        and gamePosition.Enabled
                        and gamePosition.Mode
                            == Enum.PositionAlignmentMode.OneAttachment
                        and gamePosition.Attachment0 == movementLock
                    then
                        -- ให้แรงของเกมและ Auto Farm ไปยังจุดเดียวกัน
                        gamePosition.Position = targetPosition
                        trackingStationary = true

                        local gameOrientation =
                            movementLock:FindFirstChildOfClass(
                                "AlignOrientation"
                            )

                        if gameOrientation
                            and gameOrientation.Enabled
                            and gameOrientation.Mode
                                == Enum.OrientationAlignmentMode.OneAttachment
                            and gameOrientation.Attachment0 == movementLock
                        then
                            gameOrientation.CFrame = facing
                        end
                    end
                end
            end

            positionAlign.Position = targetPosition
            positionAlign.Enabled = true

            -- สกิลอยู่กับที่ให้หันตามมอนด้วย
            -- ส่วนช่วงพุ่งถูกพักโดย pauseFarmForSkill() ก่อนถึงบล็อกนี้
            orientationAlign.Enabled =
                trackingStationary or not aimLocked

            if orientationAlign.Enabled then
                orientationAlign.CFrame = facing
            end

            root.AssemblyAngularVelocity = Vector3.zero

            if not retreatMode and lastSkillMode ~= usingSkill then
                lastSkillMode = usingSkill

                if SKILL_MOVE_DEBUG then
                    print(string.format(
                        "[AutoFarm] Position: %s | Skill: %s",
                        usingSkill and "Behind" or "Below",
                        tostring(skillState.slot:get())
                    ))
                end
            end
        end)

        HoverConnection = connection

        print(
            retreatMode and "[AutoFarm] Retreat Hover ->"
                or "[AutoFarm] Orbit ->",
            enemy:GetFullName()
        )

        return true
    end



    --==================================================
    -- Teleport Area
    --==================================================

    local function teleportToArea(areaName)
        local area = getAreaPart(areaName)
        local character = getCharacter()

        if not area or not character then
            return false
        end

        local areaKey = tostring(area.Name)

        local function hasEnemy()
            return getNearestEnemyInArea(areaKey) ~= nil
        end

        stopHover()
        CurrentAreaName = area.Name

        -- มีมอนแล้ว ให้ลูปหลักเข้าต่อสู้ทันที
        if hasEnemy() then
            LastTeleportedArea = area.Name
            print("[AutoFarm] Enemy available -> skip Area center")
            return true
        end

        local targetPosition =
            area.Position + Vector3.new(0, AREA_HEIGHT_OFFSET, 0)

        local arrived = RuntimeFix.tweenRootTo(
            CFrame.new(targetPosition),
            function()
                return area.Parent ~= nil
                    and getLiveFarmArea() == areaKey
                    and not RuntimeFix.EndRoundPaused
                    and not hasEnemy()
            end
        )

        if AutoFarmSession.Cancelled or not AutoFarmEnabled then
            return false
        end

        -- ห้ามบันทึกว่าเดินทางถึง Area เก่า หลัง Store เปลี่ยนแล้ว
        local liveArea = getLiveFarmArea()

        if liveArea ~= areaKey then
            print(
                "[AutoFarm] Cancel old Area travel:",
                areaKey,
                "->",
                tostring(liveArea)
            )

            return false
        end

        -- มอนเกิดระหว่างทาง: Tween ถูกยกเลิกแล้ว
        if hasEnemy() then
            LastTeleportedArea = area.Name

            print(
                "[AutoFarm] Enemy spawned -> cancel center travel | Area:",
                areaKey
            )

            return true
        end

        if not arrived then
            return false
        end

        LastTeleportedArea = area.Name
        print("[AutoFarm] Area center reached:", areaKey)

        return true
    end

    --==================================================
    -- Rubble
    --==================================================

    local function getRubbleForArea(areaName)
        if not areaName then
            return nil
        end

        local borderName = "Border" .. tostring(areaName)

        local border = MapFolder:FindFirstChild(borderName)

        if not border then
            warn(
                "[AutoFarm] Border not found:",
                borderName
            )
            return nil
        end

        local rubble = border:FindFirstChild("Rubble")

        if not rubble or not rubble:IsA("Model") then
            warn(
                "[AutoFarm] Rubble not found:",
                border:GetFullName() .. ".Rubble"
            )
            return nil
        end

        print(
            "[AutoFarm] REAL Rubble:",
            rubble:GetFullName()
        )

        return rubble
    end

    --==================================================
    -- Rubble Behind Position
    --==================================================

    RuntimeFix.RubbleFrontPositions = {
        ["1"] = Vector3.new(-19, 3, 150),
        ["2"] = Vector3.new(-13, 3, -94),
        ["3"] = Vector3.new(283, 3, -204),
        ["4"] = Vector3.new(582, 3, -198),
    }

    local function getRubbleBehindCFrame(rubble, areaName)
        if not rubble
            or not rubble:IsA("Model")
            or not rubble.Parent
            or not AreasFolder
            or not AreasFolder.Parent
            or areaName == nil
        then
            return nil
        end

        local border = rubble.Parent
        local blocker = border:FindFirstChild("Blocker")
        local currentArea =
            AreasFolder:FindFirstChild(tostring(areaName))

        if not blocker
            or not blocker:IsA("BasePart")
            or not currentArea
            or not currentArea:IsA("BasePart")
        then
            return nil
        end

        -- เลือกหน้าของ Blocker ที่หันหา Area ปัจจุบันโดยตรง
        local areaLocalPosition =
            blocker.CFrame:PointToObjectSpace(currentArea.Position)

        if math.abs(areaLocalPosition.Z) < 0.001 then
            -- ไม่มีข้อมูลพอแยกสองด้าน ไม่เลือกด้านโดยเดา
            return nil
        end

        local side = areaLocalPosition.Z > 0 and 1 or -1
        local halfDepth = blocker.Size.Z / 2

        local surfacePosition =
            blocker.CFrame:PointToWorldSpace(
                Vector3.new(0, 0, side * halfDepth)
            )

        local outsidePosition =
            blocker.CFrame:PointToWorldSpace(
                Vector3.new(
                    0,
                    0,
                    side * (
                        halfDepth + math.max(0.1, RUBBLE_BEHIND_GAP)
                    )
                )
            )

        local standPosition = Vector3.new(
            outsidePosition.X,
            RUBBLE_ROOT_Y,
            outsidePosition.Z
        )

        -- ตรวจว่าเป็นแผนที่ตำแหน่งเดียวกับที่ผู้ใช้ทดสอบ
        local firstBorder = MapFolder
            and MapFolder:FindFirstChild("Border1")

        local firstBlocker = firstBorder
            and firstBorder:FindFirstChild("Blocker")

        local matchesTestedMap = firstBlocker
            and firstBlocker:IsA("BasePart")
            and (
                firstBlocker.Position
                - Vector3.new(-14.9699593, 26.0142117, 117.136414)
            ).Magnitude < 0.1

        local frontPosition =
            RuntimeFix.RubbleFrontPositions[tostring(areaName)]

        if matchesTestedMap and frontPosition then
            standPosition = frontPosition
        end

        local rubbleBar = blocker:FindFirstChild("RubbleBar")
        local aimY = blocker.Position.Y

        if rubbleBar and rubbleBar:IsA("Attachment") then
            aimY = rubbleBar.WorldPosition.Y
        end

        local aimPosition = Vector3.new(
            surfacePosition.X,
            aimY,
            surfacePosition.Z
        )

        local facePosition = Vector3.new(
            aimPosition.X,
            standPosition.Y,
            aimPosition.Z
        )

        if (facePosition - standPosition).Magnitude < 0.001 then
            return nil
        end

        return CFrame.lookAt(
            standPosition,
            facePosition,
            Vector3.yAxis
        ), aimPosition
    end

    local function getRubbleAttackPosition(rubble, areaName)
        local _, aimPosition =
            getRubbleBehindCFrame(rubble, areaName)

        return aimPosition
    end

    function RuntimeFix.isRubbleBroken(rubble)
        if not rubble or not rubble.Parent then
            return true
        end

        local health =
            tonumber(rubble.Parent:GetAttribute("RubbleHealth"))

        -- ถ้าข้อมูลยังไม่มา ไม่ถือว่าพัง
        return health ~= nil and health <= 0
    end

    local function startRubbleHover(rubble, areaName)
        local character = getCharacter()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()

        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or not character
            or not root
            or not root.Parent
            or not humanoid
            or humanoid.Health <= 0
            or RuntimeFix.isRubbleBroken(rubble)
        then
            return false
        end

        local targetCFrame =
            getRubbleBehindCFrame(rubble, areaName)

        if not targetCFrame then
            warn("[AutoFarm] Rubble FRONT position unavailable")
            return false
        end

        stopHover()

        local UPDATE_INTERVAL = 0.1
        local MAX_DRIFT = 3
        local HEIGHT_STRENGTH = 16
        local HEIGHT_DAMPING = 8

        root.Anchored = false
        humanoid.AutoRotate = false

        local targetPosition = targetCFrame.Position

        local arrived = RuntimeFix.tweenRootTo(
            targetCFrame,
            function()
                return RubbleModeActive
                    and not RuntimeFix.isRubbleBroken(rubble)
            end
        )

        if not arrived then
            return false
        end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        local attachment = Instance.new("Attachment")
        attachment.Name = "AutoRubbleFloatAttachment"
        attachment.Parent = root

        local force = Instance.new("VectorForce")
        force.Name = "AutoRubbleFloatForce"
        force.Attachment0 = attachment
        force.RelativeTo = Enum.ActuatorRelativeTo.World
        force.ApplyAtCenterOfMass = true
        force.Parent = root

        RuntimeFix.RubbleFloatAttachment = attachment
        RuntimeFix.RubbleFloatForce = force

        local token = {}
        RuntimeFix.RubbleRepeatToken = token

        Spawn(function()
            local ok, err = pcall(function()
                while RuntimeFix.RubbleRepeatToken == token
                    and not AutoFarmSession.Cancelled
                    and AutoFarmEnabled
                    and RubbleModeActive
                    and not RuntimeFix.EndRoundPaused
                    and getCharacter() == character
                    and character.Parent
                    and root.Parent
                    and humanoid.Parent
                    and humanoid.Health > 0
                    and force.Parent
                    and attachment.Parent
                    and not RuntimeFix.isRubbleBroken(rubble)
                do
                    local mass = root.AssemblyMass

                    if root.Anchored
                        or mass <= 0
                        or mass == math.huge
                    then
                        error("Character assembly is anchored or has invalid mass")
                    end

                    -- พยุงเฉพาะแนวตั้ง พร้อมลดการแกว่ง
                    local heightError =
                        targetPosition.Y - root.Position.Y

                    local verticalSpeed =
                        root.AssemblyLinearVelocity.Y

                    local correction = math.clamp(
                        heightError * HEIGHT_STRENGTH
                            - verticalSpeed * HEIGHT_DAMPING,
                        -workspace.Gravity,
                        workspace.Gravity
                    )

                    force.Force = Vector3.new(
                        0,
                        mass * (workspace.Gravity + correction),
                        0
                    )

                    -- ไม่วาร์ปซ้ำถ้ายังอยู่ใกล้จุดตี
                    if (root.Position - targetPosition).Magnitude > MAX_DRIFT then
                        local returned = RuntimeFix.tweenRootTo(
                            targetCFrame,
                            function()
                                return RuntimeFix.RubbleRepeatToken == token
                                    and RubbleModeActive
                                    and not RuntimeFix.isRubbleBroken(rubble)
                            end
                        )

                        if not returned then
                            -- หยุดเฉพาะเมื่อเป้าหมายหรืองานเดิมสิ้นสุดแล้ว
                            if RuntimeFix.RubbleRepeatToken ~= token
                                or AutoFarmSession.Cancelled
                                or not AutoFarmEnabled
                                or not RubbleModeActive
                                or RuntimeFix.EndRoundPaused
                                or getCharacter() ~= character
                                or not root.Parent
                                or not humanoid.Parent
                                or humanoid.Health <= 0
                                or RuntimeFix.isRubbleBroken(rubble)
                            then
                                break
                            end

                            -- หินยังไม่พัง: พักแล้วลอง Tween กลับจุดเดิมอีกครั้ง
                            warn("[AutoFarm] Rubble return incomplete -> retry")
                            task.wait(0.5)
                        end
                    end

                    task.wait(UPDATE_INTERVAL)
                end
            end)

            -- Cleanup เฉพาะลูปที่ยังเป็นเจ้าของงาน
            if RuntimeFix.RubbleRepeatToken == token then
                stopHover()

                -- เปิดทางให้ลูปฟาร์มเริ่ม Hover ใหม่เมื่อระบบพยุงหยุด
                if CurrentRubble == rubble
                    and CurrentRubbleArea == tostring(areaName)
                then
                    RubbleTeleported = false
                end
            end

            if not ok then
                warn("[AutoFarm] Rubble float failed:", err)
            end
        end)

        print(
            "[AutoFarm] Rubble smooth float started | Area:",
            tostring(areaName)
        )

        return true
    end

    local function teleportToRubble(areaName, rubble)
        rubble = rubble or getRubbleForArea(areaName)

        if not rubble then
            return false
        end

        if not startRubbleHover(rubble, areaName) then
            return false
        end

        CurrentRubble = rubble
        CurrentRubbleArea = tostring(areaName)
        RubbleTeleported = true

        print(
            "[AutoFarm] Teleport + Hover REAL Rubble ->",
            rubble:GetFullName()
        )

        return true
    end

    local function attackRubble()
        if not PerformM1:IsA("RemoteEvent") then
            error("ReplicatedStorage.performM1 must be a RemoteEvent")
        end

        PerformM1:FireServer(nil)
    end

    local function attackEnemy()
        if not CurrentTarget then
            return
        end

        if not isEnemyAlive(CurrentTarget) then
            return
        end

        if not PerformM1:IsA("RemoteEvent") then
            warn("[AutoFarm] performM1 is not RemoteEvent")
            return
        end

        local ok, err = pcall(function()
            PerformM1:FireServer(nil)
        end)

        if not ok then
            warn("[AutoFarm] Attack failed:", err)
        end
    end

    --==================================================
    -- Aim Mouse At Current Target
    --==================================================

    local function getAimPart(enemy)
        if not enemy then
            return nil
        end

        local head = enemy:FindFirstChild("Head")

        if head and head:IsA("BasePart") then
            return head
        end

        return getEnemyRoot(enemy)
    end

    local function aimMouseAtWorldPosition(worldPosition)
        if not worldPosition then
            return false
        end

        local camera = workspace.CurrentCamera

        if not camera then
            return false
        end

        local screenPosition, onScreen =
            camera:WorldToScreenPoint(worldPosition)

        if not onScreen or screenPosition.Z <= 0 then
            local offset = worldPosition - camera.CFrame.Position

            if offset.Magnitude < 0.1 then
                return false
            end

            -- หมุนกล้องเฉพาะตอนเป้าหมายอยู่นอกมุมมอง
            camera.CFrame = CFrame.lookAt(
                camera.CFrame.Position,
                worldPosition
            )

            screenPosition, onScreen =
                camera:WorldToScreenPoint(worldPosition)
        end

        if not onScreen or screenPosition.Z <= 0 then
            return false
        end

        local ok, virtualInputManager =
            pcall(function()
                return game:GetService(
                    "VirtualInputManager"
                )
            end)

        if not ok
            or not virtualInputManager
        then
            warn(
                "[AutoFarm] VirtualInputManager unavailable"
            )

            return false
        end

        local success, err =
            pcall(function()
                virtualInputManager:SendMouseMoveEvent(
                    screenPosition.X,
                    screenPosition.Y,
                    game:GetService("CoreGui")
                )
            end)

        if not success then
            warn(
                "[AutoFarm] Virtual Aim failed:",
                err
            )

            return false
        end

        return true
    end

    local function aimMouseAtTarget()
        if not CurrentTarget
            or not isEnemyAlive(CurrentTarget)
        then
            return false
        end

        local aimPart =
            getAimPart(CurrentTarget)

        if not aimPart then
            return false
        end

        return aimMouseAtWorldPosition(
            aimPart.Position
        )
    end

    --==================================================
    -- Skill Aim Tracking
    --==================================================

    local function getTrackedAimPosition(state)
        if not state then
            return nil
        end

        if state.worldPosition then
            return typeof(state.worldPosition) == "Vector3"
                and state.worldPosition
                or nil
        end

        local enemy = state.target

        if not enemy
            or not enemy.Parent
            or enemy ~= CurrentTarget
            or not isEnemyAlive(enemy)
        then
            return nil
        end

        local enemyRoot = getEnemyRoot(enemy)

        if not enemyRoot or not enemyRoot.Parent then
            return nil
        end

        -- 0 = เล็งตำแหน่งจริง
        -- เพิ่มได้เมื่อทดสอบแล้วว่าสกิลยิงตามหลังมอนที่กำลังเดิน
        local LEAD_SECONDS = 0
        local MAX_LEAD_DISTANCE = 1.5

        local velocity = enemyRoot.AssemblyLinearVelocity
        local lead = Vector3.new(
            velocity.X,
            0,
            velocity.Z
        ) * LEAD_SECONDS

        if lead.Magnitude > MAX_LEAD_DISTANCE then
            lead = lead.Unit * MAX_LEAD_DISTANCE
        end

        local position = enemyRoot.Position + lead

        -- คงพฤติกรรมเล็งพื้นของ Skill 2 ตามโค้ดเดิม
        if state.skillKey == "2" then
            local character = LocalPlayer.Character
            local enemies = workspace:FindFirstChild("enemies")
            local effects = workspace:FindFirstChild("effects")

            -- สร้างใหม่เฉพาะเมื่อ Instance ที่ต้องยกเว้นเปลี่ยน
            if not state.floorRayParams
                or state.floorCharacter ~= character
                or state.floorEnemies ~= enemies
                or state.floorEffects ~= effects
            then
                local filter = {enemy}

                if character then
                    table.insert(filter, character)
                end

                if enemies then
                    table.insert(filter, enemies)
                end

                if effects then
                    table.insert(filter, effects)
                end

                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = filter

                state.floorRayParams = params
                state.floorCharacter = character
                state.floorEnemies = enemies
                state.floorEffects = effects
            end

            local result = workspace:Raycast(
                position + Vector3.new(0, 6, 0),
                Vector3.new(0, -100, 0),
                state.floorRayParams
            )

            if result then
                position = result.Position
            end
        end

        return position
    end

    function RuntimeFix.skillIssue(reason, detail)
        RuntimeFix.AutoSkillLastIssue =
            reason .. " | " .. tostring(detail or "")

        if not AUTO_SKILL_DEBUG then return end

        RuntimeFix.SkillWarningAt =
            RuntimeFix.SkillWarningAt or {}

        local now = os.clock()

        if now - (
            RuntimeFix.SkillWarningAt[reason] or -math.huge
        ) < 5 then
            return
        end

        RuntimeFix.SkillWarningAt[reason] = now

        AutoSkillWarn(
            "[Zero X / Auto Skill] "
                .. RuntimeFix.AutoSkillLastIssue
        )
    end

    function RuntimeFix.requireNativeSkillModule(module)
        assert(
            typeof(module) == "Instance"
                and module:IsA("ModuleScript"),
            "Native skill loader expects a ModuleScript"
        )

        assert(type(getrenv) == "function", "getrenv unavailable")

        local environment = getrenv()
        local nativeRequire = environment and environment.require

        assert(
            type(nativeRequire) == "function",
            "Native require unavailable"
        )

        assert(
            type(getthreadidentity) == "function"
                and type(setthreadidentity) == "function",
            "Thread identity API unavailable"
        )

        local previousIdentity = getthreadidentity()

        assert(
            type(previousIdentity) == "number",
            "Cannot read thread identity"
        )

        local ok, result = xpcall(function()
            setthreadidentity(2)
            return nativeRequire(module)
        end, function(err)
            return debug.traceback(tostring(err), 2)
        end)

        local restored, restoreError = pcall(
            setthreadidentity,
            previousIdentity
        )

        if not restored then
            error(
                "Native skill loader cannot restore identity: "
                    .. tostring(restoreError),
                0
            )
        end

        if not ok then
            error(result, 0)
        end

        return result
    end

    local function isGameSkillBusy()
        local ok, busy = pcall(function()
            local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local global = scripts and scripts:FindFirstChild("global")
            local stores = global and global:FindFirstChild("stores")
            local module = stores and stores:FindFirstChild("localPlayerStore")

            if not module or not module:IsA("ModuleScript") then
                return false
            end

            local playerStore =
                RuntimeFix.requireNativeSkillModule(module)
            local skill = playerStore.state.skill

            if not skill then
                return false
            end

            local pending = skill.pending and skill.pending:get()
            local tillTime = skill.till and skill.till:get()

            return pending == true
                or (
                    tonumber(tillTime) ~= nil
                    and workspace:GetServerTimeNow() < tonumber(tillTime)
                )
        end)

        return ok and busy == true
    end

    function RuntimeFix.pauseFarmForSkill()
        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or not isGameSkillBusy()
        then
            return false
        end

        local character = getCharacter()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()

        if not character
            or not root
            or not humanoid
            or humanoid.Health <= 0
        then
            return false
        end

        local movementLock = root:FindFirstChild("SkillMovementLock")

        if not movementLock
            or not movementLock:IsA("Attachment")
        then
            return false
        end

        -- สกิลอยู่กับที่: เกมมีแรงตรึงตำแหน่งของตัวเอง
        local stationaryHold =
            movementLock:FindFirstChildOfClass("AlignPosition")

        if stationaryHold and stationaryHold.Enabled then
            return false
        end

        local moving = false

        -- ตรวจเฉพาะลูกโดยตรงของ Root ระหว่างใช้สกิล
        for _, object in ipairs(root:GetChildren()) do
            if object:IsA("AlignPosition")
                and object.Enabled
                and object ~= AlignPosition
            then
                local attachment = object.Attachment0

                -- แยกแรงของ Auto Farm ด้วย Instance จริง
                -- ครอบคลุมทั้ง Hover และ Flood Hold
                if attachment
                    and attachment ~= RootAttachment
                    and attachment:IsDescendantOf(character)
                then
                    moving = true
                    break
                end
            end
        end

        if not moving then
            return false
        end

        if AlignPosition and AlignPosition.Parent then
            AlignPosition.Enabled = false
        end

        if AlignOrientation and AlignOrientation.Parent then
            AlignOrientation.Enabled = false
        end

        return true
    end

    --==================================================
    -- Mouse-Free Skill Controller
    --==================================================

    local DirectCharacterController = nil
    local PatchedInputController = nil
    local OriginalGetAimPoint = nil
    local AimPointReplacement = nil
    local NextSkillAPICheck = 0

    function RuntimeFix.fixSkillRequire(controller)
        assert(
            type(getfenv) == "function"
                and type(setfenv) == "function",
            "Skill environment API unavailable"
        )

        local fn = controller.performSkill
        assert(type(fn) == "function", "performSkill unavailable")

        local previous = RuntimeFix.SkillRequirePatch

        if previous
            and previous.Function == fn
            and getfenv(fn) == previous.Environment then
            return
        end

        if previous then
            previous.Restore()
            RuntimeFix.SkillRequirePatch = nil
        end

        local global = ReplicatedStorage:FindFirstChild("global")
        local module = global and global:FindFirstChild("Flags")

        assert(
            module and module:IsA("ModuleScript"),
            "ReplicatedStorage.global.Flags unavailable"
        )

        local flags = RuntimeFix.requireNativeSkillModule(module)

        assert(
            type(flags) == "table"
                and type(flags.IsOn) == "function"
                and type(flags.Skill) == "function",
            "Flags API unavailable"
        )

        local original = getfenv(fn)
        local originalRequire = original.require

        assert(
            type(originalRequire) == "function",
            "performSkill require unavailable"
        )

        -- สร้าง environment แยก ไม่เขียนทับตารางเดิมของเกม
        local environment = {}

        for key, value in pairs(original) do
            environment[key] = value
        end

        setmetatable(environment, { __index = original })

        environment.require = function(target, ...)
            if target == "@game/ReplicatedStorage/global/Flags" then
                return flags
            end

            return originalRequire(target, ...)
        end

        local function restore()
            if getfenv(fn) == environment then
                setfenv(fn, original)
            end
        end

        setfenv(fn, environment)

        RuntimeFix.SkillRequirePatch = {
            Function = fn,
            Environment = environment,
            Restore = restore,
        }

        if not RuntimeFix.SkillRequireCleanupRegistered then
            RuntimeFix.SkillRequireCleanupRegistered = true

            table.insert(AutoFarmSession.Cleanups, function()
                local record = RuntimeFix.SkillRequirePatch
                RuntimeFix.SkillRequirePatch = nil

                if record then
                    record.Restore()
                end
            end)
        end
    end

    local function ensureMouseFreeSkillAPI()
        if DirectCharacterController
            and PatchedInputController
            and PatchedInputController.getAimPoint
                == AimPointReplacement
        then
            return DirectCharacterController
        end

        -- Reference เปลี่ยน: โหลดและผูกใหม่ผ่าน retry เดิม
        if PatchedInputController then
            DirectCharacterController = nil
            PatchedInputController = nil
            OriginalGetAimPoint = nil
            AimPointReplacement = nil
        end

        if os.clock() < NextSkillAPICheck then
            return nil
        end

        NextSkillAPICheck = os.clock() + 2

        local scripts =
            LocalPlayer:FindFirstChild("PlayerScripts")

        local gameFolder =
            scripts and scripts:FindFirstChild("game")

        local gameControllers =
            gameFolder
            and gameFolder:FindFirstChild("controllers")

        local characterModule =
            gameControllers
            and gameControllers:FindFirstChild("characterController")

        local global =
            scripts and scripts:FindFirstChild("global")

        local globalControllers =
            global and global:FindFirstChild("controllers")

        local inputModule =
            globalControllers
            and globalControllers:FindFirstChild("inputController")

        if not characterModule
            or not characterModule:IsA("ModuleScript")
            or not inputModule
            or not inputModule:IsA("ModuleScript")
        then
            RuntimeFix.skillIssue("Controller modules unavailable")
            return nil
        end

        local ok, characterController, inputController =
            pcall(function()
                return RuntimeFix.requireNativeSkillModule(
                    characterModule
                ), RuntimeFix.requireNativeSkillModule(
                    inputModule
                )
            end)

        if not ok
            or type(characterController) ~= "table"
            or type(characterController.performSkill) ~= "function"
            or type(inputController) ~= "table"
            or type(inputController.getAimPoint) ~= "function"
        then
            RuntimeFix.skillIssue(
                "Direct Skill API unavailable",
                not ok and characterController
                    or "ตรวจ performSkill / getAimPoint"
            )
            return nil
        end

        local requireReady, requireError = pcall(
            RuntimeFix.fixSkillRequire,
            characterController
        )

        if not requireReady then
            RuntimeFix.skillIssue(
                "Skill require setup failed",
                requireError
            )
            return nil
        end

        local originalAim = inputController.getAimPoint

        local replacement = function(...)
            RuntimeFix.AutoAimReadCount =
                (RuntimeFix.AutoAimReadCount or 0) + 1

            if not AutoFarmSession.Cancelled and AutoFarmEnabled then
                local state = SkillAimState

                if state then
                    local useState =
                        (
                            state.worldPosition ~= nil
                            and RubbleModeActive
                        )
                        or (
                            state.target ~= nil
                            and state.target == CurrentTarget
                            and isEnemyAlive(state.target)
                        )

                    if useState then
                        local position = getTrackedAimPosition(state)

                        if position then
                            state.lastValidAim = position
                            return position
                        end
                    end

                    -- เป้าหมายหายระหว่างร่าย:
                    -- คงจุดสุดท้ายจนสกิลจบ ไม่กระโดดกลับไปหาเมาส์
                    if isGameSkillBusy()
                        and typeof(state.lastValidAim) == "Vector3"
                    then
                        return state.lastValidAim
                    end
                end

                -- แม้เวลาติดตามสำรองหมดแล้ว ยังเล็ง CurrentTarget
                if CurrentTarget and isEnemyAlive(CurrentTarget) then
                    local targetRoot = getEnemyRoot(CurrentTarget)

                    if targetRoot and targetRoot.Parent then
                        return targetRoot.Position
                    end
                end
            end

            -- ใช้เมาส์จริงเมื่อไม่มีเป้าหมาย หรือปิด Auto Farm
            return originalAim(...)
        end

        local patched, patchError = pcall(function()
            inputController.getAimPoint = replacement
        end)

        if not patched then
            RuntimeFix.skillIssue(
                "Aim API patch failed",
                patchError
            )
            return nil
        end

        DirectCharacterController = characterController
        PatchedInputController = inputController
        OriginalGetAimPoint = originalAim
        AimPointReplacement = replacement

        print("[AutoSkill] Mouse-Free Skill API READY")

        task.delay(10, function()
            if AutoFarmSession.Cancelled then
                return
            end

            warn(
                "[AutoAimCheck] getAimPoint calls:",
                RuntimeFix.AutoAimReadCount or 0
            )
        end)

        return DirectCharacterController
    end

    -- คืนฟังก์ชันเดิมเมื่อจบ Session
    table.insert(AutoFarmSession.Cleanups, function()
        SkillAimState = nil

        if PatchedInputController
            and AimPointReplacement
            and OriginalGetAimPoint
        then
            pcall(function()
                if PatchedInputController.getAimPoint
                    == AimPointReplacement
                then
                    PatchedInputController.getAimPoint =
                        OriginalGetAimPoint
                end
            end)
        end

        DirectCharacterController = nil
        PatchedInputController = nil
        OriginalGetAimPoint = nil
        AimPointReplacement = nil
    end)

    --==================================================
    -- Direct Skill Activation (No Keyboard Focus)
    --==================================================

    function RuntimeFix.ensureMouseAimAPI()
        local patch = RuntimeFix.MouseAimPatch

        if not patch then
            patch = {
                NextAttempt = 0,
            }

            RuntimeFix.MouseAimPatch = patch
        end

        if patch.Module
            and patch.Module.Get == patch.Replacement then
            return true
        end

        -- หาก reference เปลี่ยน ให้ลองผูกใหม่ผ่าน NextAttempt

        if AutoFarmSession.Cancelled
            or os.clock() < patch.NextAttempt
        then
            return false
        end

        patch.NextAttempt = os.clock() + 2

        local scripts =
            LocalPlayer:FindFirstChild("PlayerScripts")

        local gameFolder =
            scripts and scripts:FindFirstChild("game")

        local controllers =
            gameFolder and gameFolder:FindFirstChild("controllers")

        local module =
            controllers and controllers:FindFirstChild("MouseAim")

        if not module or not module:IsA("ModuleScript") then
            return false
        end

        local ok, mouseAim = pcall(
            RuntimeFix.requireNativeSkillModule,
            module
        )

        if not ok
            or type(mouseAim) ~= "table"
            or type(mouseAim.Get) ~= "function"
        then
            return false
        end

        if AutoFarmSession.Cancelled then return false end

        local original = mouseAim.Get

        local function replacement(...)
            local state = SkillAimState
            local root = select(1, ...)

            -- ใช้เฉพาะสกิลช่อง 2 ที่ Auto Farm กำลังควบคุม
            if AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or not state
                or (
                    state.skillKey ~= "2"
                    and not game:GetService("UserInputService").TouchEnabled
                )
                or root ~= getCharacterRoot()
            then
                return original(...)
            end

            if os.clock() >= state.expires
                and not isGameSkillBusy()
            then
                return original(...)
            end

            local position = getTrackedAimPosition(state)

            -- เป้าหมายหายระหว่างร่าย ให้คงจุดเล็งล่าสุด
            if typeof(position) ~= "Vector3" then
                position = state.lastValidAim
            end

            if typeof(position) ~= "Vector3" then
                return original(...)
            end

            -- รักษาโครงสร้างผลลัพธ์จริงและค่าที่ส่งคืนเพิ่มเติม
            local results = table.pack(original(...))
            local result = results[1]

            if typeof(result) == "Vector3" then
                results[1] = position
                state.lastValidAim = position

                return table.unpack(results, 1, results.n)
            end

            if type(result) ~= "table" then
                if not patch.InvalidResultLogged then
                    patch.InvalidResultLogged = true

                    local logger = warn

                    if type(logger) == "function" then
                        logger(
                            "[AutoAim] Unexpected MouseAim.Get result:",
                            typeof(result)
                        )
                    end
                end

                return table.unpack(results, 1, results.n)
            end

            -- ไม่แก้ตารางต้นฉบับ และไม่สร้าง Hit/Origin ขึ้นมาเอง
            local aimed = table.clone(result)
            aimed.Point = position
            results[1] = aimed

            state.lastValidAim = position
            state.MouseAimReads = (state.MouseAimReads or 0) + 1

            if not state.MouseAimLogged then
                state.MouseAimLogged = true

                local logger = warn

                if type(logger) == "function" then
                    logger(
                        "[AutoAim] Skill 2 -> target:",
                        position
                    )
                end
            end

            return table.unpack(results, 1, results.n)
        end

        local assigned, assignError = pcall(function()
            mouseAim.Get = replacement
        end)

        if not assigned then
            local logger = warn

            if type(logger) == "function" then
                logger(
                    "[AutoAim] MouseAim patch failed:",
                    assignError
                )
            end

            return false
        end

        patch.Module = mouseAim
        patch.Original = original
        patch.Replacement = replacement

        -- ลงทะเบียนครั้งเดียว แม้มีการผูก API ใหม่
        if not patch.CleanupRegistered then
            patch.CleanupRegistered = true

            table.insert(AutoFarmSession.Cleanups, function()
                if patch.Module
                    and patch.Module.Get == patch.Replacement then

                    patch.Module.Get = patch.Original
                end

                if RuntimeFix.MouseAimPatch == patch then
                    RuntimeFix.MouseAimPatch = nil
                end
            end)
        end

        local logger = warn

        if type(logger) == "function" then
            logger("[AutoAim] MouseAim.Get READY")
        end

        return true
    end

    local ultimateBossModules = nil

    local function isUltimateBoss(target)
        if not target
            or not target.Parent
            or not target:IsA("Model") then
            return false
        end

        local id = tonumber(target.Name)
        if not id then return false end

        local ok, result = pcall(function()
            if not ultimateBossModules then
                local enemies = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    { "global", "constants", "enemies" }
                )

                local maps = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    { "global", "constants", "maps" }
                )

                local enemyStore = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    { "game", "stores", "enemyStore" }
                )

                assert(type(enemies.enemiesByName) == "table",
                    "enemiesByName unavailable")

                assert(type(maps.mapsByName) == "table",
                    "mapsByName unavailable")

                assert(enemyStore.store
                    and enemyStore.store.state
                    and type(enemyStore.store.state.get) == "function",
                    "enemyStore.state:get unavailable")

                ultimateBossModules = {
                    Enemies = enemies,
                    Maps = maps,
                    Store = enemyStore,
                }
            end

            if AutoFarmSession.Cancelled
                or target ~= CurrentTarget
                or not target.Parent then
                return false
            end

            local modules = ultimateBossModules
            local entry = modules.Store.store.state:get(id)

            if not entry or not entry.name
                or type(entry.name.get) ~= "function" then
                return false
            end

            local enemyKey = entry.name:get()

            if type(enemyKey) ~= "string" or enemyKey == "" then
                return false
            end

            -- เกณฑ์ที่ 1: Definition ของศัตรูระบุ boss จริง
            local definition = modules.Enemies.enemiesByName[enemyKey]

            if definition and definition.boss == true then
                return true
            end

            -- เกณฑ์ที่ 2: แมปปัจจุบันระบุเป็นบอสของ Chapter/Defense
            local maps = modules.Maps
            local map = maps.mapsByName[maps.currentMap]

            if type(map) ~= "table" then
                return false
            end

            if type(map.chapters) == "table" then
                for _, chapter in pairs(map.chapters) do
                    if type(chapter) == "table"
                        and chapter.boss == enemyKey then
                        return true
                    end
                end
            end

            local defense = map.defense

            if type(defense) == "table"
                and type(defense.bosses) == "table" then

                for _, bossKey in pairs(defense.bosses) do
                    if bossKey == enemyKey then
                        return true
                    end
                end
            end

            return false
        end)

        if not ok then
            warn("[AutoUltimate] Boss lookup failed:", result)
            return false
        end

        return result == true
    end

    local ultimateNamespace = nil

    local function canUseUltimate()
        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or LocalPlayer:GetAttribute("UltimateLocked")
            or isGameSkillBusy() then
            return false
        end

        local onlyBoss = Options.ZeroXUltimateOnlyBoss

        if onlyBoss and onlyBoss.Value == true then
            local target = CurrentTarget

            -- ไม่ใช้ Ultimate กับ Rubble หรือเมื่อไม่มีเป้าหมายที่มีชีวิต
            if RubbleModeActive
                or not target
                or not target.Parent
                or not target:IsA("Model")
                or not isEnemyAlive(target)
                or not getEnemyRoot(target) then
                return false
            end

            if not isUltimateBoss(target) then
                return false
            end
        end

        local humanoid = getHumanoid()

        if not humanoid or humanoid.Health <= 0 then
            return false
        end

        local ok, ready = pcall(function()
            if not ultimateNamespace then
                ultimateNamespace = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    { "game", "stores", "playerNamespace" }
                )
            end

            if AutoFarmSession.Cancelled then return false end

            assert(type(ultimateNamespace.getLocalPlayerStore) == "function"
                and type(ultimateNamespace.skillCooldownKey) == "function",
                "Ultimate playerNamespace API unavailable")

            local store = ultimateNamespace.getLocalPlayerStore()
            local state = store and store.state

            if not state or not state.ultProgress
                or not state.character or not state.cooldowns then
                return false
            end

            local progress = state.ultProgress:get()
            local characterName = state.character:get()

            if type(progress) ~= "number"
                or progress ~= progress
                or progress < 100
                or type(characterName) ~= "string"
                or characterName == "" then
                return false
            end

            local key = ultimateNamespace.skillCooldownKey(
                characterName, 4
            )

            local cooldown = state.cooldowns:get(key)
            local cooldownTill = cooldown and cooldown:get() or 0

            if type(cooldownTill) ~= "number"
                or cooldownTill ~= cooldownTill then
                return false
            end

            return workspace:GetServerTimeNow() >= cooldownTill
        end)

        if not ok then
            warn("[AutoUltimate] Readiness check failed:", ready)
            return false
        end

        return ready == true
    end

    function RuntimeFix.skillReady(slot)
        if AutoFarmSession.Cancelled or not AutoFarmEnabled then
            return false
        end

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if not playerGui
            or playerGui:GetAttribute("MobileLayoutEditing") == true
        then
            return false
        end

        local humanoid = getHumanoid()

        if not humanoid or humanoid.Health <= 0 or isGameSkillBusy() then
            return false
        end

        local ok, ready = pcall(function()
            if not ultimateNamespace then
                ultimateNamespace = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    { "game", "stores", "playerNamespace" }
                )
            end

            assert(
                ultimateNamespace
                    and type(ultimateNamespace.getLocalPlayerStore) == "function"
                    and type(ultimateNamespace.skillCooldownKey) == "function",
                "Skill playerNamespace API unavailable"
            )

            local store = ultimateNamespace.getLocalPlayerStore()
            local state = store and store.state

            if not state or not state.character or not state.cooldowns then
                return false
            end

            local characterName = state.character:get()

            if type(characterName) ~= "string" or characterName == "" then
                return false
            end

            local key = ultimateNamespace.skillCooldownKey(
                characterName,
                slot
            )

            local entry = state.cooldowns:get(key)
            local cooldownTill = entry and entry:get() or 0

            if type(cooldownTill) ~= "number"
                or cooldownTill ~= cooldownTill
            then
                error("Invalid cooldown value: " .. tostring(key))
            end

            return workspace:GetServerTimeNow() >= cooldownTill
        end)

        if not ok then
            RuntimeFix.skillIssue("Skill readiness read failed", ready)
            return false
        end

        return ready == true
    end

    function RuntimeFix.invokeAutoSkill(controller, slot, touchInput)
        if not touchInput then
            return controller.performSkill(slot)
        end

        local patch = RuntimeFix.MouseAimPatch
        local aim = patch and patch.Module

        assert(
            type(aim) == "table"
                and type(aim.IsAiming) == "function"
                and type(aim.AimingSlot) == "function",
            "Touch MouseAim state API unavailable"
        )

        assert(
            type(controller.touchSkillDown) == "function"
                and type(controller.touchSkillUp) == "function",
            "Touch skill down/up API unavailable"
        )

        local character = getCharacter()

        local function cooldown()
            if not ultimateNamespace then
                ultimateNamespace = RuntimeFix.requireModule(
                    ReplicatedStorage,
                    { "game", "stores", "playerNamespace" }
                )
            end

            assert(
                type(ultimateNamespace.getLocalPlayerStore) == "function"
                    and type(ultimateNamespace.skillCooldownKey) == "function",
                "Touch cooldown API unavailable"
            )

            local store = ultimateNamespace.getLocalPlayerStore()
            local state = store and store.state

            assert(
                state and state.character and state.cooldowns,
                "Touch cooldown state unavailable"
            )

            local name = state.character:get()

            assert(
                type(name) == "string" and name ~= "",
                "Touch character state unavailable"
            )

            local key = ultimateNamespace.skillCooldownKey(name, slot)
            local entry = state.cooldowns:get(key)
            local till = entry and entry:get() or 0

            assert(
                type(till) == "number" and till == till,
                "Invalid Touch skill cooldown"
            )

            return till
        end

        local before = cooldown()

        -- รอ Cooldown จริง ไม่ใช้เพียงเวลาหน่วงของ Auto Skill
        if before > workspace:GetServerTimeNow() then
            return false
        end

        -- ไม่แทรกระหว่างที่มีการเล็งอยู่แล้ว
        if aim.IsAiming() then
            return false
        end

        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or getCharacter() ~= character then
            return false
        end

        assert(
            type(aim.TouchHolds) == "function",
            "MouseAim.TouchHolds unavailable"
        )

        local heldMode = aim.TouchHolds() == true

        local downOK, downError = pcall(function()
            if heldMode then
                return controller.touchSkillDown(slot)
            end

            return controller.performSkill(slot)
        end)

        local upOK, upError = pcall(function()
            if heldMode then
                controller.touchSkillUp(slot)
            end

            if not downOK
                or AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or getCharacter() ~= character
            then
                return
            end

            if aim.IsAiming() and aim.AimingSlot() == slot then
                assert(
                    type(aim.Source) == "function",
                    "MouseAim.Source unavailable"
                )

                if aim.Source() == "Tap" then
                    assert(
                        type(aim.Press) == "function",
                        "MouseAim.Press unavailable"
                    )

                    aim.Press(slot)
                else
                    assert(
                        type(aim.Release) == "function",
                        "MouseAim.Release unavailable"
                    )

                    aim.Release(slot)
                end
            end
        end)

        if not downOK then
            if not upOK then
                error(
                    "Touch Down failed: " .. tostring(downError)
                        .. " | Touch Up failed: " .. tostring(upError),
                    0
                )
            end

            error("Touch Down failed: " .. tostring(downError), 0)
        end

        if not upOK then
            error("Touch Up failed: " .. tostring(upError), 0)
        end

        -- ไม่ถือว่า Begin/Release สำเร็จเท่ากับเริ่มร่ายสำเร็จ
        local deadline = os.clock() + 0.6

        repeat
            if AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or getCharacter() ~= character
            then
                return false
            end

            if isGameSkillBusy() or cooldown() > before then
                return true
            end

            if not aim.IsAiming() then
                task.wait(0.05)
            else
                task.wait(0.1)
            end
        until os.clock() >= deadline

        RuntimeFix.skillIssue(
            "Touch release not confirmed",
            "Slot=" .. slot
        )

        return false
    end

    local function pressSkillKey(keyCode, worldPosition)
        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or RuntimeFix.SkillInvokeBusy
            or isGameSkillBusy()
        then
            return false
        end

        local slot =
            keyCode == Enum.KeyCode.One and 1
            or keyCode == Enum.KeyCode.Two and 2
            or keyCode == Enum.KeyCode.Three and 3
            or keyCode == Enum.KeyCode.G and 4

        if not slot then
            return false
        end

        if not RuntimeFix.skillReady(slot) then
            return false
        end

        if slot == 4 and not canUseUltimate() then
            return false
        end

        local touchInput =
            game:GetService("UserInputService").TouchEnabled

        if (slot == 2 or touchInput)
            and not RuntimeFix.ensureMouseAimAPI()
        then
            RuntimeFix.skillIssue(
                "MouseAim API unavailable",
                "Slot=" .. slot
            )
            return false
        end

        -- เตรียม Controller ที่ไม่ต้องใช้คีย์บอร์ด
        local controller = ensureMouseFreeSkillAPI()

        if not controller then
            RuntimeFix.skillIssue(
                "Skill controller not ready",
                "Slot=" .. slot
            )
            return false
        end

        local state = {
            skillKey = tostring(slot),
            target = CurrentTarget,
            worldPosition = worldPosition,
            expires = os.clock() + (
                slot == 2
                    and SKILL_AIM_DELAYED_TIME
                    or SKILL_AIM_NORMAL_TIME
            ),
        }

        if worldPosition ~= nil then
            state.target = nil
        end

        local position = getTrackedAimPosition(state)

        if not position then
            RuntimeFix.skillIssue(
                "No valid skill target",
                "Slot=" .. slot
            )
            return false
        end

        local root = getCharacterRoot()

        if not root then
            return false
        end

        state.lastValidAim = position
        SkillAimState = state

        -- หันตัวละครให้ตรงมอนสำหรับ Directional Skills
        if state.target then
            if AlignOrientation and AlignOrientation.Parent then
                AlignOrientation.Enabled = false
            end

            local facePosition = Vector3.new(
                position.X,
                root.Position.Y,
                position.Z
            )

            if (facePosition - root.Position).Magnitude > 0.1 then
                root.CFrame = CFrame.lookAt(
                    root.Position,
                    facePosition
                )
            end
        end

        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
        then
            SkillAimState = nil
            return false
        end

        -- ตรวจซ้ำก่อนเรียก Controller เผื่อเป้าหมายเปลี่ยนระหว่างเตรียมสกิล
        if slot == 4 and not canUseUltimate() then
            SkillAimState = nil
            return false
        end

        -- เรียก Skill ผ่านระบบเกมโดยตรง
        -- ไม่ใช้ keypress / SendKeyEvent
        local readIdentity = getthreadidentity
        local changeIdentity = setthreadidentity

        if type(readIdentity) ~= "function"
            or type(changeIdentity) ~= "function" then

            SkillAimState = nil

            RuntimeFix.skillIssue(
                "Thread identity API unavailable",
                "ต้องมี getthreadidentity และ setthreadidentity"
            )

            return false
        end

        local identityOK, previousIdentity = pcall(readIdentity)

        if not identityOK
            or type(previousIdentity) ~= "number" then

            SkillAimState = nil

            RuntimeFix.skillIssue(
                "Cannot read thread identity",
                previousIdentity
            )

            return false
        end

        RuntimeFix.SkillInvokeBusy = true

        local success, result = xpcall(function()
            changeIdentity(2)

            return RuntimeFix.invokeAutoSkill(
                controller,
                slot,
                touchInput
            )
        end, function(err)
            return debug.traceback(tostring(err), 2)
        end)

        -- คืนค่าเดิมทั้งกรณีสำเร็จและเกิด Error
        local restored, restoreError = pcall(
            changeIdentity,
            previousIdentity
        )

        RuntimeFix.SkillInvokeBusy = nil

        if not restored then
            SkillAimState = nil

            error(
                "Auto Skill: cannot restore thread identity: "
                    .. tostring(restoreError),
                0
            )
        end

        if not success then
            SkillAimState = nil

            RuntimeFix.skillIssue(
                "performSkill exception: Slot=" .. slot,
                result
            )

            return false
        end

        if result ~= true then
            SkillAimState = nil

            RuntimeFix.skillIssue(
                "performSkill not accepted: Slot=" .. slot,
                result
            )

            return false
        end

        print(
            "[AutoSkill] Skill requested directly | Slot:",
            slot,
            "| Target:",
            position
        )

        return true
    end

    local SkillComboOrders = {
        ["1-2-3"] = { 1, 2, 3 },
        ["1-3-2"] = { 1, 3, 2 },
        ["2-1-3"] = { 2, 1, 3 },
        ["2-3-1"] = { 2, 3, 1 },
        ["3-1-2"] = { 3, 1, 2 },
        ["3-2-1"] = { 3, 2, 1 },
    }

    local function useReadySkills(worldPosition)
        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or not AZEnabled("Combat", "AutoSkills")
            or isGameSkillBusy() then
            return
        end

        if SkillAimState
            and os.clock() < SkillAimState.expires then
            return
        end

        -- Multi Dropdown ของ MacUI เก็บค่าเป็น { [ชื่อรายการ] = true }
        local selectedOption = Options.ZeroXSelectedSkills
        local selected = selectedOption and selectedOption.Value

        if type(selected) ~= "table" then
            return
        end

        local now = os.clock()
        local retryDelay = math.max(
            0.75,
            SKILL_ACTIVATION_RETRY_DELAY
        )

        -- Ultimate มีความสำคัญก่อน Combo เมื่อเลือกไว้และพร้อมใช้
        if selected["Ultimate (G)"] == true then
            local lastAttempt = LastSkillActivation["4"] or 0

            if now - lastAttempt >= retryDelay
                and canUseUltimate() then

                LastSkillActivation["4"] = now

                if pressSkillKey(Enum.KeyCode.G, worldPosition) then
                    return
                end

                if isGameSkillBusy() then
                    return
                end
            end
        end

        local comboToggle = Options.ZeroXEnableSkillCombo
        local comboEnabled = comboToggle
            and comboToggle.Value == true

        local comboOption = Options.ZeroXSkillCombo
        local selectedCombo = comboEnabled
            and comboOption and comboOption.Value or "1-2-3"

        local order = SkillComboOrders[selectedCombo]
        if not order then return end

        local orderKey = (comboEnabled and "Combo:" or "Default:")
            .. selectedCombo

        -- เปลี่ยนลำดับหรือเปิด/ปิด Combo ให้เริ่มลำดับใหม่
        if RuntimeFix.ActiveSkillCombo ~= orderKey then
            RuntimeFix.ActiveSkillCombo = orderKey
            RuntimeFix.NextAutoSkillSlot = 1
        end

        local keyCodes = {
            Enum.KeyCode.One,
            Enum.KeyCode.Two,
            Enum.KeyCode.Three,
        }

        local firstIndex = RuntimeFix.NextAutoSkillSlot or 1

        for offset = 0, #order - 1 do
            local index = ((firstIndex - 1 + offset) % #order) + 1
            local slot = order[index]

            if selected["Skill " .. tostring(slot)] == true then
                local skillKey = tostring(slot)
                local lastAttempt = LastSkillActivation[skillKey] or 0

                if now - lastAttempt >= retryDelay
                    and RuntimeFix.skillReady(slot)
                then
                    LastSkillActivation[skillKey] = now

                    if pressSkillKey(keyCodes[slot], worldPosition) then
                        RuntimeFix.NextAutoSkillSlot = (index % #order) + 1
                        return
                    end

                    if isGameSkillBusy() then
                        return
                    end
                end
            end
        end
    end

    local function useReadySkillsDuringHeal()
        if not CurrentTarget
            or not isEnemyAlive(CurrentTarget)
        then
            return
        end

        -- ใช้เป้าหมายเดิมตลอดช่วง Heal
        useReadySkills()
    end

    --==================================================
    -- Raid State
    --==================================================

    local function getRaidStatus()
        if not RaidTag or not RaidTag.Parent then
            local runSide = PlayerGui:FindFirstChild("RunSide")
            local container = runSide and runSide:FindFirstChild("Container")
            RaidTag = container and container:FindFirstChild("Tag")
        end

        if not RaidTag or RaidTag.Text ~= "Raid" then
            return ""
        end

        local ok, text = pcall(function()
            return EnemyCountLabel.Text
        end)

        if not ok or type(text) ~= "string" then
            return ""
        end

        return text
    end

    isInRaid = function()
        if not RaidTag or not RaidTag.Parent then
            local runSide = PlayerGui:FindFirstChild("RunSide")
            local container = runSide and runSide:FindFirstChild("Container")
            RaidTag = container and container:FindFirstChild("Tag")
        end

        return RaidTag
            and RaidTag.Parent
            and RaidTag.Text == "Raid"
    end

    local function getExitPrompt()
        local world = workspace:FindFirstChild("World")
        local markers = world and world:FindFirstChild("Markers")
        local exit = markers and markers:FindFirstChild("Exit")

        if not exit then
            warn("[AutoFarm] Workspace.World.Markers.Exit not found")
            return nil
        end

        local prompt = exit:FindFirstChild("ExitPrompt")

        if not prompt or not prompt:IsA("ProximityPrompt") then
            warn("[AutoFarm] ExitPrompt not found under", exit:GetFullName())
            return nil
        end

        return prompt
    end

    local function getExitPosition()
        local world = workspace:FindFirstChild("World")
        local markers = world and world:FindFirstChild("Markers")
        local exit = markers and markers:FindFirstChild("Exit")

        if not exit then
            warn("[AutoFarm] Workspace.World.Markers.Exit not found")
            return nil
        end

        if exit:IsA("BasePart") then
            return exit.Position
        end

        if exit:IsA("Model") then
            return exit:GetPivot().Position
        end

        warn("[AutoFarm] Exit has unsupported class:", exit.ClassName)
        return nil
    end

    local function teleportToExit()
        local character = getCharacter()
        local exitPosition = getExitPosition()

        if not character or not exitPosition then
            return false
        end

        stopHover()

        local targetPosition = exitPosition + Vector3.new(0, 2, 0)

        if workspace:GetAttribute("Mode") == "spiritedawayraid" then
            local arrived = RuntimeFix.tweenRootTo(
                CFrame.new(targetPosition),
                function()
                    return workspace:GetAttribute("Mode")
                        == "spiritedawayraid"
                end
            )

            if not arrived then
                return false
            end

            print("[AutoFarm] BathTub Tween -> Exit", targetPosition)
        else
            character:PivotTo(CFrame.new(targetPosition))
        end

        return true
    end

    local function pressE()
        local prompt = getExitPrompt()

        if not prompt or not prompt.Enabled then
            warn("[AutoFarm] Exit prompt is unavailable or disabled")
            return false
        end

        local ok, err = pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration, 0.05))
            prompt:InputHoldEnd()
        end)

        if not ok then
            warn("[AutoFarm] Exit prompt activation failed:", err)
            return false
        end

        print("[AutoFarm] Activated elevator prompt")
        return true
    end

    local function handleRaidState()
        -- Fate: วาร์ปเข้าจุดเริ่มต่อสู้ครั้งเดียวเมื่อพบมอน
        if isFateRaid() then
            local character = getCharacter()
            local root = getCharacterRoot()
            local humanoid = getHumanoid()

            if not character
                or not root
                or not humanoid
                or humanoid.Health <= 0 then
                return true
            end

            if RuntimeFix.FateArenaCharacter == character then
                return false
            end

            local enemies = workspace:FindFirstChild("enemies")
            local foundEnemy = false

            for _, enemy in ipairs(
                enemies and enemies:GetChildren() or {}
            ) do
                if enemy:IsA("Model")
                    and isEnemyAlive(enemy)
                    and getEnemyRoot(enemy) then

                    foundEnemy = true
                    break
                end
            end

            local statusText = EnemyCountLabel
                and EnemyCountLabel.Parent
                and EnemyCountLabel.Text or ""

            local starting = string.find(
                string.lower(statusText),
                "starting",
                1,
                true
            ) ~= nil

            -- วาร์ปได้ตั้งแต่เริ่มนับถอยหลัง หรือเมื่อพบมอน
            if not starting and not foundEnemy then
                return true
            end

            if AutoFarmSession.Cancelled
                or not AutoFarmEnabled then
                return true
            end

            stopHover()

            local arrived = RuntimeFix.tweenRootTo(
                CFrame.new(66, 282, -234) * root.CFrame.Rotation,
                function()
                    return isFateRaid()
                        and getCharacter() == character
                        and getCharacterRoot() == root
                        and root.Parent ~= nil
                        and humanoid.Parent ~= nil
                        and humanoid.Health > 0
                        and not RuntimeFix.EndRoundPaused
                        and PlayerGui:GetAttribute("EndScreenActive") ~= true
                end
            )

            if not arrived then
                -- ยังไม่ถึง ห้ามบันทึกว่าเข้า Arena สำเร็จ
                return true
            end

            RuntimeFix.FateArenaCharacter = character
            CurrentAreaName = getLiveFarmArea() or "1"

            -- จบรอบลูปนี้ก่อน เพื่อไม่ให้คำสั่งตามมอน
            -- ย้ายตัวออกจากจุดวาร์ปในรอบเดียวกัน
            return true
        end

        local status = getRaidStatus()

        if status == "" then
            return false
        end

        if status ~= LastRaidStatus then
            print("[AutoFarm] Raid Status:", status)
            LastRaidStatus = status
        end

        local lowerStatus = string.lower(status)

        if string.find(lowerStatus, "head to the elevator", 1, true) then
            if os.clock() - LastElevatorAction >= ELEVATOR_RETRY_DELAY then
                LastElevatorAction = os.clock()

                if teleportToExit() then
                    task.wait(0.15)
                    pressE()
                end
            end

            return true
        end

        if string.find(lowerStatus, "starting nightmare", 1, true) then
            if os.clock() - LastRaidStartTeleport >= RAID_RETELEPORT_DELAY then
                LastRaidStartTeleport = os.clock()

                local character = getCharacter()

                if character then
                    -- ตรวจว่าพิกัดวาร์ปอยู่ใน Area จริงของด่าน
                    local destinationArea =
                        AreasFolder
                        and getAreaByPosition(RAID_START_POSITION)

                    if destinationArea then
                        -- ใช้พิกัดเดิมเฉพาะเมื่ออยู่ในแมพ
                        stopHover()

                        if workspace:GetAttribute("Mode") == "spiritedawayraid" then
                            local arrived = RuntimeFix.tweenRootTo(
                                CFrame.new(RAID_START_POSITION),
                                function()
                                    local raidStatus = string.lower(getRaidStatus())

                                    return workspace:GetAttribute("Mode")
                                        == "spiritedawayraid"
                                        and string.find(
                                            raidStatus,
                                            "starting nightmare",
                                            1,
                                            true
                                        ) ~= nil
                                end
                            )

                            if arrived then
                                print(
                                    "[AutoFarm] BathTub Tween -> Nightmare Start",
                                    RAID_START_POSITION
                                )
                            end
                        else
                            character:PivotTo(CFrame.new(RAID_START_POSITION))

                            print(
                                "[AutoFarm] Nightmare Start Teleport ->",
                                RAID_START_POSITION
                            )
                        end
                    else
                        -- ป้องกันวาร์ปออกนอกด่าน เช่น Shadow Gate
                        print(
                            "[AutoFarm] Skip unsafe Nightmare teleport",
                            "| Destination:",
                            RAID_START_POSITION
                        )
                    end
                end
            end

            return true
        end

        return false
    end

    local function resetRubbleState()
        RuntimeFix.RubbleRepeatToken = nil

        RubbleModeActive = false
        CurrentRubble = nil
        CurrentRubbleArea = nil
        RubbleTeleported = false
    end

    local function handleRubbleStatus(areaName)
        if not areaName then
            return
        end

        areaName = tostring(areaName)

        if not RubbleModeActive then
            RubbleModeActive = true
            RubbleTeleported = false
            CurrentRubble = nil
            CurrentRubbleArea = areaName

            print(
                "[AutoFarm] Enter Rubble Mode | Area:",
                areaName
            )
        end

        if CurrentRubbleArea ~= areaName then
            resetRubbleState()

            RubbleModeActive = true
            CurrentRubbleArea = tostring(areaName)

            print(
                "[AutoFarm] Rubble Area Changed ->",
                areaName
            )
        end

        if not CurrentRubble then
            CurrentRubble = getRubbleForArea(areaName)

            if not CurrentRubble then
                return
            end

            print(
                "[AutoFarm] Rubble Target:",
                CurrentRubble:GetFullName()
            )
        end

        -- เคยไปถึงแล้ว แต่ลูปพยุงหรืออุปกรณ์พยุงหายไป:
        -- ให้เริ่ม Tween + Hover ใหม่
        if RubbleTeleported
            and CurrentRubble
            and not RuntimeFix.isRubbleBroken(CurrentRubble)
            and (
                RuntimeFix.RubbleRepeatToken == nil
                or not RuntimeFix.RubbleFloatForce
                or not RuntimeFix.RubbleFloatForce.Parent
                or not RuntimeFix.RubbleFloatAttachment
                or not RuntimeFix.RubbleFloatAttachment.Parent
            )
        then
            RubbleTeleported = false
        end

        if CurrentRubble
            and CurrentRubble.Parent
            and not RubbleTeleported
        then
            local success =
                teleportToRubble(
                    areaName,
                    CurrentRubble
                )

            if success then
                task.wait(0.20)
            end
        end

        if CurrentRubble and CurrentRubble.Parent then
            attackRubble()
        end
    end

    local SHADOW_ARISE_SCAN_DELAY = 0.5
    local SHADOW_ARISE_RETRY_DELAY = 3
    local SHADOW_ARISE_MAX_DISTANCE = 100

    local LastShadowAriseScan = 0
    local LastAriseDebug = 0
    local ShadowAriseAttemptAt = setmetatable({}, {
        __mode = "k",
    })

    local function tryShadowGateArise()
        if os.clock() - LastAriseDebug >= 5 then
            LastAriseDebug = os.clock()

            local folder = workspace:FindFirstChild("AriseShadows")
            local spots = 0
            local eligible = 0

            if folder then
                for _, spot in ipairs(folder:GetChildren()) do
                    if spot:IsA("BasePart") then
                        spots += 1

                        local prompt =
                            spot:FindFirstChildOfClass("ProximityPrompt")

                        if spot:GetAttribute("RaisedBy") == nil
                            and prompt
                            and prompt.Enabled
                        then
                            eligible += 1
                        end
                    end
                end
            end

            print(
                "[AriseDebug]",
                "Mode:", workspace:GetAttribute("Mode"),
                "| Raid:", tostring(isInRaid()),
                "| AutoFarm:", AutoFarmEnabled,
                "| Slots:", LocalPlayer:GetAttribute("AriseSlots"),
                "| Shadows:", LocalPlayer:GetAttribute("AriseShadows"),
                "| Spots:", spots,
                "| Eligible:", eligible,
                "| PromptAPI:", typeof(fireproximityprompt)
            )
        end

        if AutoFarmSession.Cancelled
            or not AutoFarmEnabled
            or not isShadowGateRaid()
        then
            return false
        end

        local now = os.clock()

        if now - LastShadowAriseScan < SHADOW_ARISE_SCAN_DELAY then
            return false
        end

        LastShadowAriseScan = now

        local maxSlots = tonumber(
            LocalPlayer:GetAttribute("AriseSlots")
        )

        local currentShadows = tonumber(
            LocalPlayer:GetAttribute("AriseShadows")
        )

        -- Nil means slot data is unavailable, not necessarily full.
        -- Let the server validate whether Arise is allowed.
        if maxSlots ~= nil then
            if maxSlots <= 0 then
                return false
            end

            if currentShadows ~= nil
                and currentShadows >= maxSlots
            then
                return false
            end
        end

        local folder = workspace:FindFirstChild("AriseShadows")

        if not folder or not folder:IsA("Folder") then
            return false
        end

        local character = getCharacter()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()

        if not character
            or not root
            or not root.Parent
            or not humanoid
            or humanoid.Health <= 0
        then
            return false
        end

        local bestSpot = nil
        local bestPrompt = nil
        local bestDistance = math.huge

        for _, spot in ipairs(folder:GetChildren()) do
            if spot:IsA("BasePart")
                and spot:GetAttribute("RaisedBy") == nil
                and now >= (ShadowAriseAttemptAt[spot] or 0)
            then
                local prompt =
                    spot:FindFirstChildOfClass("ProximityPrompt")

                if prompt and prompt.Enabled then
                    local distance =
                        (root.Position - spot.Position).Magnitude

                    if distance <= SHADOW_ARISE_MAX_DISTANCE
                        and distance < bestDistance
                    then
                        bestDistance = distance
                        bestSpot = spot
                        bestPrompt = prompt
                    end
                end
            end
        end

        if not bestSpot or not bestPrompt then
            return false
        end

        print(
            "[ShadowGate Arise] Attempt ->",
            bestSpot:GetFullName(),
            "| Distance:", math.floor(bestDistance),
            "| MaxDistance:", bestPrompt.MaxActivationDistance
        )

        ShadowAriseAttemptAt[bestSpot] =
            now + SHADOW_ARISE_RETRY_DELAY

        -- Pause combat movement before using Arise.
        stopHover()

        if bestDistance > math.max(
            0.5,
            bestPrompt.MaxActivationDistance - 1
        ) then
            local pivotOffset =
                root.CFrame:ToObjectSpace(character:GetPivot())

            local yOffset = math.min(
                2,
                math.max(0, bestPrompt.MaxActivationDistance - 1)
            )

            local destination =
                bestSpot.Position + Vector3.new(0, yOffset, 0)

            character:PivotTo(
                CFrame.new(destination)
                    * root.CFrame.Rotation
                    * pivotOffset
            )

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            task.wait(0.1)
        end

        if AutoFarmSession.Cancelled
            or not isShadowGateRaid()
            or not bestPrompt.Parent
            or not bestPrompt.Enabled
        then
            return false
        end

        local ok, err

        if typeof(fireproximityprompt) == "function" then
            ok, err = pcall(function()
                fireproximityprompt(bestPrompt)
            end)
        else
            ok, err = pcall(function()
                bestPrompt:InputHoldBegin()

                task.wait(
                    math.max(bestPrompt.HoldDuration, 0.1)
                )

                bestPrompt:InputHoldEnd()
            end)

            if not ok then
                pcall(function()
                    bestPrompt:InputHoldEnd()
                end)
            end
        end

        if not ok then
            warn("[ShadowGate Arise] Prompt failed:", err)
            return true
        end

        -- Verify Arise without comparing numbers against nil.
        local confirmed = false
        local deadline = os.clock() + 1.5

        repeat
            if AutoFarmSession.Cancelled then
                break
            end

            local raisedBy = bestSpot:GetAttribute("RaisedBy")

            local newShadowCount = tonumber(
                LocalPlayer:GetAttribute("AriseShadows")
            )

            confirmed =
                raisedBy == LocalPlayer.UserId
                or (
                    currentShadows ~= nil
                    and newShadowCount ~= nil
                    and newShadowCount > currentShadows
                )

            if confirmed then
                break
            end

            task.wait(0.1)
        until os.clock() >= deadline

        if confirmed then
            print("[ShadowGate Arise] SUCCESS")
        elseif not AutoFarmSession.Cancelled then
            warn("[ShadowGate Arise] Not confirmed")
        end

        return true
    end

    local function handleRetreatHeal()
        if AutoFarmSession.Cancelled or not AutoFarmEnabled then
            return false
        end

        local toggle = Options.ZeroXRetreatHeal
        local startOption = Options.ZeroXHealStartPercent
        local resumeOption = Options.ZeroXHealResumePercent

        local startPercent = tonumber(
            startOption and startOption.Value
        ) or HEAL_START_PERCENT

        local resumePercent = tonumber(
            resumeOption and resumeOption.Value
        ) or HEAL_RESUME_PERCENT

        local function ResumeCombat()
            local target = CurrentTarget
            IsHealing = false
            stopHover()

            if target and target.Parent
                and isEnemyAlive(target)
                and getEnemyRoot(target) then
                startHover(target)
            end
        end

        if not toggle or toggle.Value ~= true then
            if IsHealing then
                ResumeCombat()
            end
            return false
        end

        assert(startPercent == startPercent
            and resumePercent == resumePercent
            and startPercent >= 1
            and resumePercent <= 100
            and startPercent < resumePercent,
            "Retreat Heal: Retreat Below must be lower than Resume At")

        local humanoid = getHumanoid()
        local root = getCharacterRoot()
        local target = CurrentTarget

        if not humanoid
            or humanoid.Health <= 0
            or humanoid.MaxHealth <= 0
            or not root
            or not root.Parent
            or not target
            or not target.Parent
            or not isEnemyAlive(target)
            or not getEnemyRoot(target) then

            if IsHealing then
                IsHealing = false
                stopHover()
            end
            return false
        end

        -- ใช้เปอร์เซ็นต์จริง ไม่ปัดเศษก่อนเปรียบเทียบ
        local healthPercent =
            humanoid.Health / humanoid.MaxHealth * 100

        if IsHealing then
            if healthPercent >= resumePercent then
                ResumeCombat()
                return false
            end

            -- สร้างตำแหน่งถอยใหม่หากอุปกรณ์พยุงถูกลบ
            if not HoverConnection
                or not AlignPosition
                or not AlignPosition.Parent
                or not AlignOrientation
                or not AlignOrientation.Parent then

                if not startHover(target, HEAL_RETREAT_HEIGHT, true) then
                    IsHealing = false
                    return false
                end
            end

            -- คงพฤติกรรมใช้สกิลระหว่างถอยของระบบเดิม
            useReadySkillsDuringHeal()
            return true
        end

        if healthPercent < startPercent then
            if startHover(target, HEAL_RETREAT_HEIGHT, true) then
                IsHealing = true
                return true
            end
        end

        return false
    end

    --==================================================
    -- Start Auto Farm
    --==================================================

    function RuntimeFix.floodStatus(message)
        -- เก็บสถานะภายใน โดยไม่แสดงใน UI
        RuntimeFix.FloodMessage = message
    end

    function RuntimeFix.isFlood()
        return workspace:GetAttribute("Mode") == "floodescape"
    end

    function RuntimeFix.floodKey()
        return tostring(workspace:GetAttribute("FloodFloor")) .. ":"
            .. tostring(workspace:GetAttribute("FloodRoof")) .. ":"
            .. tostring(workspace:GetAttribute("FloodPhase"))
    end

    function RuntimeFix.floodSafe(position)
        local water = workspace:GetAttribute("FloodLevel")

        if RuntimeFix.isFlood() and type(water) == "number" then
            return Vector3.new(
                position.X,
                math.max(position.Y, water + 8),
                position.Z
            )
        end

        return position
    end

    function RuntimeFix.floodPoint(object)
        if not object then return nil end

        if object:IsA("BasePart") then
            return object.Position
        elseif object:IsA("Attachment") then
            return object.WorldPosition
        elseif object:IsA("Model") then
            return object:GetPivot().Position
        end

        return nil
    end

    function RuntimeFix.floodGatePosition(position, gate)
        if not gate
            or not gate.Parent
            or not gate:IsA("BasePart")
            or not RuntimeFix.isFlood()
            or workspace:GetAttribute("FloodPhase") ~= "block" then
            return position
        end

        local center = gate.Position
        local radius = 17 -- เว้นขอบจากรัศมีจริง 18 studs
        local water = workspace:GetAttribute("FloodLevel")
        local minY = center.Y - radius

        if type(water) == "number" then
            minY = math.max(minY, water + 8)
        end

        if minY > center.Y + radius then
            return nil
        end

        local y = math.clamp(
            position.Y,
            minY,
            center.Y + radius
        )

        local dy = y - center.Y
        local horizontalLimit = math.sqrt(
            math.max(0, radius * radius - dy * dy)
        )

        local offset = Vector3.new(
            position.X - center.X,
            0,
            position.Z - center.Z
        )

        if offset.Magnitude > horizontalLimit then
            offset = offset.Unit * horizontalLimit
        end

        return Vector3.new(
            center.X + offset.X,
            y,
            center.Z + offset.Z
        )
    end

    function RuntimeFix.floodStandOnGround(gate)
        local root = getCharacterRoot()
        local humanoid = getHumanoid()
        local character = getCharacter()
        local world = workspace:FindFirstChild("World")

        if not root or not humanoid or not character
            or humanoid.Health <= 0
            or not world
            or not gate or not gate.Parent
            or not gate:IsA("BasePart")
            or not AutoFarmEnabled
            or AutoFarmSession.Cancelled
            or not RuntimeFix.isFlood()
            or workspace:GetAttribute("FloodPhase") ~= "block" then
            return false
        end

        local water = workspace:GetAttribute("FloodLevel")
        if type(water) ~= "number" then return false end

        local previous = RuntimeFix.FloodGroundStand

        if previous
            and previous.Root == root
            and previous.Gate == gate
            and previous.Support.Parent
            and previous.FloorY > water
            and (root.Position - previous.Position).Magnitude < 3
            and (root.Position - gate.Position).Magnitude <= 18 then

            humanoid:Move(Vector3.zero, false)
            return true
        end

        stopHover()

        -- คืนการชนพื้นจริง แทนการตรึงตัวด้วย AlignPosition
        RememberCharacter(character)

        for part, original in pairs(collisionSaved) do
            if part.Parent and part:IsDescendantOf(character) then
                part.CanCollide = original
            end
        end

        if os.clock() < (RuntimeFix.FloodGroundRetryAt or 0) then
            return false
        end

        RuntimeFix.FloodGroundRetryAt = os.clock() + 0.5

        local clearance = humanoid.HipHeight + root.Size.Y * 0.5

        -- สูตรความสูงของ Humanoid แบบ R6 ต้องรวมความยาวขา
        if humanoid.RigType == Enum.HumanoidRigType.R6 then
            local leg = character:FindFirstChild("Left Leg")
            if not leg or not leg:IsA("BasePart") then
                return false
            end
            clearance += leg.Size.Y
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = { world }
        params.RespectCanCollide = true
        params.IgnoreWater = true

        local center = gate.Position

        -- ลองจุดใต้ตัวก่อน แล้วจึงหาพื้นรอบศูนย์กลาง Gate
        local candidates = {
            root.Position,
            center,
            center + Vector3.new(8, 0, 0),
            center + Vector3.new(-8, 0, 0),
            center + Vector3.new(0, 0, 8),
            center + Vector3.new(0, 0, -8),
        }

        for _, candidate in ipairs(candidates) do
            local hit = workspace:Raycast(
                Vector3.new(candidate.X, center.Y + 18, candidate.Z),
                Vector3.new(0, -(36 + clearance), 0),
                params
            )

            if hit
                and hit.Position.Y > water
                and hit.Normal.Y > 0
                and hit.Normal.Y >= math.cos(
                    math.rad(humanoid.MaxSlopeAngle)
                ) then

                local position = hit.Position
                    + Vector3.new(0, clearance + 0.05, 0)

                if (position - center).Magnitude <= 17 then
                    local landing = {
                        Root = root,
                        Gate = gate,
                        Support = hit.Instance,
                        FloorY = hit.Position.Y,
                        Position = position,
                        Landing = true,
                    }

                    RuntimeFix.FloodGroundStand = landing
                    local key = RuntimeFix.floodKey()

                    local ok, arrived = pcall(
                        RuntimeFix.tweenRootTo,
                        CFrame.new(position) * root.CFrame.Rotation,
                        function()
                            local currentWater =
                                workspace:GetAttribute("FloodLevel")

                            return RuntimeFix.FloodGroundStand == landing
                                and RuntimeFix.floodKey() == key
                                and getCharacter() == character
                                and getCharacterRoot() == root
                                and gate.Parent ~= nil
                                and hit.Instance.Parent ~= nil
                                and workspace:GetAttribute("FloodLeverAt") == nil
                                and type(currentWater) == "number"
                                and hit.Position.Y > currentWater
                                and root.Position.Y > currentWater
                                and (position - gate.Position).Magnitude <= 17
                        end
                    )

                    if RuntimeFix.FloodGroundStand ~= landing then
                        return false
                    end

                    if not ok or not arrived then
                        RuntimeFix.FloodGroundStand = nil

                        RuntimeFix.floodStatus(
                            "Hold Gate: Tween ไม่สำเร็จ / สถานะเปลี่ยน"
                        )
                        return false
                    end

                    landing.Landing = nil

                    -- ถึงปลายทางแล้วจึงคืนการชนพื้น
                    for part, original in pairs(collisionSaved) do
                        if part.Parent
                            and part:IsDescendantOf(character) then
                            part.CanCollide = original
                        end
                    end

                    humanoid.AutoRotate = true
                    humanoid:Move(Vector3.zero, false)

                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero

                    return true
                end
            end
        end

        RuntimeFix.floodStatus(
            "Hold Gate: ยังไม่พบพื้นแห้งที่ยืนได้ภายในเขต"
        )

        return false
    end

    function RuntimeFix.floodHold(position)
        local root = getCharacterRoot()
        if not root then return false end

        position = RuntimeFix.floodSafe(position)

        local holding = RuntimeFix.FloodHolding

        if holding
            and holding.Root == root
            and HoverConnection
            and (holding.Position - position).Magnitude < 1 then

            holding.Position = position
            return true
        end

        stopHover()

        local key = RuntimeFix.floodKey()

        if (root.Position - position).Magnitude > 3 then
            local arrived = RuntimeFix.tweenRootTo(
                CFrame.new(position),
                function()
                    return RuntimeFix.isFlood()
                        and RuntimeFix.floodKey() == key
                end
            )

            if not arrived then return false end
        end

        if not AutoFarmEnabled
            or AutoFarmSession.Cancelled
            or not root.Parent
            or RuntimeFix.floodKey() ~= key then
            return false
        end

        holding = {
            Root = root,
            Position = position,
        }

        RuntimeFix.FloodHolding = holding

        RootAttachment = Instance.new("Attachment")
        RootAttachment.Parent = root

        AlignPosition = Instance.new("AlignPosition")
        AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPosition.Attachment0 = RootAttachment
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = POSITION_RESPONSIVENESS
        AlignPosition.Position = position
        AlignPosition.Parent = root

        HoverConnection = RunService.Heartbeat:Connect(function()
            local humanoid = getHumanoid()

            if AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or RuntimeFix.EndRoundPaused
                or getCharacterRoot() ~= root
                or not root.Parent
                or not humanoid
                or humanoid.Health <= 0
                or not RuntimeFix.isFlood()
                or RuntimeFix.floodKey() ~= key then

                stopHover()
                return
            end

            AlignPosition.Position =
                RuntimeFix.floodSafe(holding.Position)

            root.AssemblyAngularVelocity = Vector3.zero
        end)

        return true
    end

    function RuntimeFix.floodLever(map)
        -- สแกนครั้งแรกเมื่อ Map เปลี่ยน แล้วติดตามของที่เพิ่มใหม่
        if RuntimeFix.FloodMap ~= map then
            if RuntimeFix.FloodMapConnection then
                RuntimeFix.FloodMapConnection:Disconnect()
                RuntimeFix.FloodMapConnection = nil
            end

            RuntimeFix.FloodMap = map
            RuntimeFix.FloodPrompts = {}

            if map then
                local function add(object)
                    if object:IsA("ProximityPrompt")
                        and object.Name == "FloodLeverPrompt" then

                        RuntimeFix.FloodPrompts[object] = true
                    end
                end

                for _, object in ipairs(map:GetDescendants()) do
                    add(object)
                end

                RuntimeFix.FloodMapConnection =
                    map.DescendantAdded:Connect(add)
            end
        end

        local raw = workspace:GetAttribute("FloodLeverAt")
        local target

        if typeof(raw) == "Vector3" then
            target = raw
        elseif type(raw) == "string" then
            local parts = string.split(raw, ",")

            if #parts == 3 then
                local x, y, z =
                    tonumber(parts[1]),
                    tonumber(parts[2]),
                    tonumber(parts[3])

                if x and y and z then
                    target = Vector3.new(x, y, z)
                end
            end
        end

        if not map or not target
            or target.X ~= target.X
            or target.Y ~= target.Y
            or target.Z ~= target.Z
            or math.abs(target.X) == math.huge
            or math.abs(target.Y) == math.huge
            or math.abs(target.Z) == math.huge
        then
            return nil
        end

        local best, bestPosition
        local bestDistance = 3 -- ค่าคลาดเคลื่อนของพิกัด ไม่ใช่ระยะกด

        for prompt in pairs(RuntimeFix.FloodPrompts or {}) do
            if not prompt:IsDescendantOf(map) then
                RuntimeFix.FloodPrompts[prompt] = nil
            elseif prompt.Enabled then
                local position = RuntimeFix.floodPoint(prompt.Parent)
                local distance = position
                    and (position - target).Magnitude

                if distance and distance <= bestDistance then
                    best = prompt
                    bestPosition = position
                    bestDistance = distance
                end
            end
        end

        return best, raw, bestPosition
    end

    table.insert(AutoFarmSession.Cleanups, function()
        if RuntimeFix.FloodMapConnection then
            RuntimeFix.FloodMapConnection:Disconnect()
            RuntimeFix.FloodMapConnection = nil
        end

        RuntimeFix.floodStatus("หยุด Auto Farm")
    end)

    function RuntimeFix.floodStep()
        local root = getCharacterRoot()
        local humanoid = getHumanoid()

        if not root or not humanoid or humanoid.Health <= 0 then
            stopHover()
            return
        end

        local floor = workspace:GetAttribute("FloodFloor")
        local water = workspace:GetAttribute("FloodLevel")
        local phase = workspace:GetAttribute("FloodPhase")
        local roof = workspace:GetAttribute("FloodRoof") == true

        if type(floor) ~= "number"
            or type(water) ~= "number"
            or (
                phase ~= "fight"
                and phase ~= "block"
                and phase ~= "drain"
            ) then

            stopHover()
            RuntimeFix.floodStatus("รอ Flood State จาก Server")
            return
        end

        local key = RuntimeFix.floodKey()

        if RuntimeFix.FloodState ~= key then
            RuntimeFix.FloodCombatGate = nil
            stopHover()
            IsHealing = false
            SkillAimState = nil
            RuntimeFix.FloodState = key
        end

        local world = workspace:FindFirstChild("World")
        local markers = world and world:FindFirstChild("Markers")

        local marker = markers and markers:FindFirstChild(
            roof and "Roof"
                or (floor == 0 and "Parking" or "Floor" .. floor)
        )

        local origin = RuntimeFix.floodPoint(
            marker and marker:FindFirstChild("Respawn")
        ) or RuntimeFix.floodPoint(marker)

        if roof and not origin then
            origin = RuntimeFix.floodPoint(
                markers and markers:FindFirstChild("BossSpawn")
            )
        end

        if floor > 0 and not origin then
            stopHover()
            RuntimeFix.floodStatus("รอ Marker ของชั้นปัจจุบัน")
            return
        end

        -- พิกัดที่ผู้ใช้ยืนยันสำหรับชั้น 10
        local floor10ClearPoint = floor == 10 and not roof
            and Vector3.new(-191, 549, -19) or nil

        local function inFloor10Zone(part)
            return floor10ClearPoint ~= nil
                and part ~= nil
                and math.abs(
                    part.Position.Y - floor10ClearPoint.Y
                ) < 30
        end

        -- ย้ายตามชั้นที่ Server เปิดแล้วเท่านั้น
        local floorToken = tostring(floor) .. ":" .. tostring(roof)

        if RuntimeFix.FloodFloorToken ~= floorToken then
            local entryPoint = floor10ClearPoint
                or (origin and origin + Vector3.new(0, 3, 0))

            if entryPoint
                and not RuntimeFix.floodHold(entryPoint) then
                return
            end

            RuntimeFix.FloodFloorToken = floorToken
        end

        local label = roof and "Roof" or ("Floor " .. floor)

        local contested =
            workspace:GetAttribute("FloodGateContested") == true

        -- ตรวจมอนในชั้นปัจจุบันก่อนเข้า Hold Gate
        local enemies = workspace:FindFirstChild("enemies")

        if not enemies then
            stopHover()
            RuntimeFix.floodStatus(label .. " | รอ enemies")
            return
        end

        local best, distance
        local priorityEnemy, priorityDistance

        local gateObjects = world
            and world:FindFirstChild("MapObjects")

        local activeGate = gateObjects
            and gateObjects:FindFirstChild("FloodGateZone")

        local gateStage = phase == "block"
            and not roof
            and workspace:GetAttribute("FloodLeverAt") == nil
            and activeGate ~= nil
            and activeGate:IsA("BasePart")

        local gateBoss, gateBossDistance
        local gateEnemy, gateEnemyDistance
        local hasLivingEnemy = false

        for _, enemy in ipairs(enemies:GetChildren()) do
            local alive = isEnemyAlive(enemy)

            if alive then
                hasLivingEnemy = true
            end

            local part = getEnemyRoot(enemy)

            if part
                and alive
                and part.Position.Y > water
                and (
                    not origin
                    or floor == 0
                    or math.abs(part.Position.Y - origin.Y) < 30
                    or inFloor10Zone(part)
                ) then

                local d = (part.Position - root.Position).Magnitude

                if gateStage then
                    -- ฟังก์ชันเดิมอ่าน enemyStore และ enemiesByName
                    local _, boss = readFateEnemy(enemy)

                    if boss == true then
                        if not gateBoss
                            or enemy == CurrentTarget
                            or (
                                gateBoss ~= CurrentTarget
                                and d < gateBossDistance
                            ) then

                            gateBoss = enemy
                            gateBossDistance = d
                        end

                    elseif boss == false
                        and (
                            part.Position - activeGate.Position
                        ).Magnitude <= 18 then

                        if not gateEnemy
                            or enemy == CurrentTarget
                            or (
                                gateEnemy ~= CurrentTarget
                                and d < gateEnemyDistance
                            ) then

                            gateEnemy = enemy
                            gateEnemyDistance = d
                        end
                    end
                end

                if not distance or d < distance then
                    best = enemy
                    distance = d
                end

                -- เคลียร์มอนระดับล่างก่อน เริ่มจากตัวใกล้พิกัด
                if inFloor10Zone(part) then
                    local clearDistance = (
                        part.Position - floor10ClearPoint
                    ).Magnitude

                    if not priorityDistance
                        or clearDistance < priorityDistance then

                        priorityEnemy = enemy
                        priorityDistance = clearDistance
                    end
                end
            end
        end

        if hasLivingEnemy then
            RuntimeFix.FloodEmptySpawnVisit = nil

        elseif phase == "fight" and not roof then
            if AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or RuntimeFix.EndRoundPaused
                or RuntimeFix.floodKey() ~= key
                or RuntimeFix.pauseFarmForSkill()
            then
                return
            end

            local spawns = marker
                and marker:FindFirstChild("EnemySpawns")

            local visit = RuntimeFix.FloodEmptySpawnVisit

            if visit
                and visit.Key == key
                and visit.Root == root
                and visit.Spawns == spawns
                and visit.Spawn.Parent == spawns
            then
                RuntimeFix.floodStatus(
                    label .. " | ไม่มีมอน: รอที่ EnemySpawns"
                )
                RuntimeFix.floodHold(visit.Position)
                return
            end

            RuntimeFix.FloodEmptySpawnVisit = nil

            local spawnPart

            if spawns then
                for _, candidate in ipairs(spawns:GetChildren()) do
                    if candidate:IsA("BasePart")
                        and candidate.Position.Y > water
                    then
                        spawnPart = candidate
                        break
                    end
                end
            end

            if not spawnPart then
                stopHover()
                RuntimeFix.floodStatus(
                    label .. " | รอ EnemySpawns ที่อยู่เหนือน้ำโหลด"
                )
                return
            end

            local character = getCharacter()

            if not character
                or not character:IsA("Model")
                or getCharacterRoot() ~= root
                or not root:IsDescendantOf(character)
                or not humanoid.Parent
                or humanoid.Health <= 0
            then
                return
            end

            stopHover()

            local destination =
                spawnPart.Position + Vector3.new(0, 3, 0)

            -- รักษาระยะระหว่าง Model Pivot กับ Root ของตัวละคร
            local pivotOffset =
                root.CFrame:ToObjectSpace(character:GetPivot())

            character:PivotTo(
                CFrame.new(destination)
                    * root.CFrame.Rotation
                    * pivotOffset
            )

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            RuntimeFix.FloodEmptySpawnVisit = {
                Key = key,
                Root = root,
                Spawns = spawns,
                Spawn = spawnPart,
                Position = destination,
            }

            RuntimeFix.floodStatus(
                label .. " | ไม่มีมอน: วาปไป EnemySpawns"
            )

            RuntimeFix.floodHold(destination)
            return
        end

        -- มอนทั่วไปลอยตีภายใน Gate; บอสออกไปไล่ได้
        if gateStage then
            if RuntimeFix.floodKey() ~= key then return end

            if gateBoss then
                RuntimeFix.FloodCombatGate = nil

                if CurrentTarget ~= gateBoss
                    or RuntimeFix.FloodHolding
                    or not HoverConnection then

                    if not startHover(gateBoss) then return end
                end

                if CurrentTarget == gateBoss
                    and isEnemyAlive(gateBoss) then

                    if not handleRetreatHeal() then
                        attackEnemy()
                        useReadySkills()
                    end
                end

                return
            end

            local targetRoot = gateEnemy
                and getEnemyRoot(gateEnemy)

            local currentWater =
                workspace:GetAttribute("FloodLevel")

            IsHealing = false

            if gateEnemy
                and gateEnemy.Parent == enemies
                and targetRoot
                and isEnemyAlive(gateEnemy)
                and type(currentWater) == "number"
                and targetRoot.Position.Y > currentWater
                and (
                    targetRoot.Position - activeGate.Position
                ).Magnitude <= 18 then

                RuntimeFix.FloodCombatGate = activeGate

                if CurrentTarget ~= gateEnemy
                    or RuntimeFix.FloodHolding
                    or not HoverConnection then

                    if not startHover(gateEnemy) then return end
                end

                if RuntimeFix.floodKey() ~= key then return end

                if CurrentTarget == gateEnemy
                    and isEnemyAlive(gateEnemy) then

                    RuntimeFix.floodStatus(
                        label .. " | ลอยตีมอนภายใน Gate"
                    )

                    attackEnemy()
                    useReadySkills()
                end
            else
                RuntimeFix.FloodCombatGate = nil

                if RuntimeFix.floodStandOnGround(activeGate) then
                    RuntimeFix.floodStatus(
                        label .. " | Hold Gate: ยืนบนพื้น"
                    )
                end
            end

            return
        end

        -- ชั้น 10: ยืนจุดเดิมตลอดช่วงเคลียร์มอน
        if floor10ClearPoint
            and (
                phase == "fight"
                or (
                    phase == "block"
                    and (best ~= nil or contested)
                )
            ) then

            IsHealing = false

            if not RuntimeFix.floodHold(floor10ClearPoint) then
                return
            end

            if AutoFarmSession.Cancelled
                or not AutoFarmEnabled
                or RuntimeFix.floodKey() ~= key then
                return
            end

            local targetRoot = CurrentTarget
                and getEnemyRoot(CurrentTarget)

            local keepTarget = CurrentTarget ~= nil
                and CurrentTarget.Parent == enemies
                and isEnemyAlive(CurrentTarget)
                and targetRoot ~= nil
                and targetRoot.Position.Y > water
                and (
                    inFloor10Zone(targetRoot)
                    or (
                        origin
                        and math.abs(
                            targetRoot.Position.Y - origin.Y
                        ) < 30
                    )
                )

            if not keepTarget
                or (
                    priorityEnemy
                    and not inFloor10Zone(targetRoot)
                ) then

                CurrentTarget = priorityEnemy or best
            end

            if CurrentTarget then
                RuntimeFix.floodStatus(
                    label .. " | ยืนเคลียร์มอนที่ -191, 549, -19"
                )

                attackEnemy()
                useReadySkills()
            else
                RuntimeFix.floodStatus(
                    label .. " | ยืนรอมอน / รอ Server เปลี่ยน Phase"
                )
            end

            return
        end

        if phase == "fight"
            or (
                phase == "block"
                and (best ~= nil or contested)
            )
            or roof then

            -- เก็บเป้าหมายเดิมไว้ หากยังอยู่ในช่วงความสูงที่ถูกต้อง
            if CurrentTarget then
                local part = getEnemyRoot(CurrentTarget)

                if not part
                    or not isEnemyAlive(CurrentTarget)
                    or part.Position.Y <= water
                    or (
                        origin
                        and floor ~= 0
                        and math.abs(part.Position.Y - origin.Y) >= 30
                        and not inFloor10Zone(part)
                    ) then

                    stopHover()
                end
            end

            -- เปลี่ยนจากมอนระดับบนไปเคลียร์ระดับล่างก่อน
            if priorityEnemy
                and CurrentTarget
                and not inFloor10Zone(
                    getEnemyRoot(CurrentTarget)
                ) then

                stopHover()
            end

            if not CurrentTarget and (priorityEnemy or best) then
                startHover(priorityEnemy or best)
            end

            if CurrentTarget then
                RuntimeFix.floodStatus(
                    label .. (
                        priorityEnemy
                            and " | เคลียร์มอนบริเวณ -191, 549, -19"
                            or (
                                phase == "block"
                                    and " | เคลียร์มอนก่อน Hold Gate"
                                    or " | ต่อสู้"
                            )
                    )
                )

                if not handleRetreatHeal() then
                    attackEnemy()
                    useReadySkills()
                end
            else
                RuntimeFix.floodStatus(
                    label .. " | รอศัตรู / รอ Server"
                )

                RuntimeFix.floodHold(
                    origin and origin + Vector3.new(0, 3, 0)
                        or root.Position
                )
            end

            return
        end

        if phase == "drain" then
            if floor == 0 and not roof then
                local nextMarker = markers
                    and markers:FindFirstChild("Floor1")

                local nextRespawn = nextMarker
                    and nextMarker:FindFirstChild("Respawn")

                if not nextRespawn
                    or not nextRespawn:IsA("BasePart")
                then
                    stopHover()
                    RuntimeFix.floodStatus(
                        "Parking | Drain: รอ Floor1.Respawn โหลด"
                    )
                    return
                end

                RuntimeFix.floodStatus(
                    "Parking | Drain: Tween ขึ้นชั้น 1"
                )

                -- ใช้ Tween และระบบ Hold/Cleanup เดิม
                local arrived = RuntimeFix.floodHold(
                    nextRespawn.Position
                )

                -- ระหว่าง Tween อาจเปลี่ยน Phase หรือ Respawn
                if not arrived
                    or getCharacterRoot() ~= root
                    or not root.Parent
                    or not humanoid.Parent
                    or humanoid.Health <= 0
                    or RuntimeFix.floodKey() ~= key
                then
                    return
                end

                RuntimeFix.floodStatus(
                    "Parking | ถึงจุดชั้น 1 รอ Server เปลี่ยน State"
                )
                return
            end

            RuntimeFix.floodStatus(
                label .. " | Drain: รอ Server เปิดชั้นถัดไป"
            )

            RuntimeFix.floodHold(root.Position)
            return
        end

        if workspace:GetAttribute("FloodLeverAt") ~= nil then
            local map = world and world:FindFirstChild("Map")
            local prompt, leverAt, position = RuntimeFix.floodLever(map)

            if not prompt or not position then
                RuntimeFix.floodStatus(
                    label .. " | รอคันโยกที่ตรงกับ FloodLeverAt"
                )
                stopHover()
                return
            end

            local function isCurrentLever()
                if AutoFarmSession.Cancelled
                    or not AutoFarmEnabled
                    or RuntimeFix.EndRoundPaused
                    or getCharacterRoot() ~= root
                    or not root.Parent
                    or not humanoid.Parent
                    or humanoid.Health <= 0
                    or RuntimeFix.floodKey() ~= key
                    or workspace:GetAttribute("FloodLeverAt") ~= leverAt
                    or not map
                    or not prompt:IsDescendantOf(map)
                    or not prompt.Enabled
                then
                    return false
                end

                local currentPosition =
                    RuntimeFix.floodPoint(prompt.Parent)

                return currentPosition ~= nil
                    and (currentPosition - position).Magnitude <= 0.5
            end

            local destination = RuntimeFix.floodSafe(
                position + Vector3.new(0, 2, 0)
            )

            if (destination - position).Magnitude
                >= prompt.MaxActivationDistance
            then
                RuntimeFix.floodStatus(
                    label .. " | Lever อยู่ต่ำกว่าระยะปลอดภัยเหนือน้ำ"
                )
                stopHover()
                return
            end

            RuntimeFix.floodStatus(
                label .. " | ไปยังคันโยกเป้าหมาย"
            )

            -- ยกเลิก Tween ทันทีเมื่อเป้าหมายหรือชั้นเปลี่ยน
            if (root.Position - destination).Magnitude > 3 then
                stopHover()

                if not RuntimeFix.tweenRootTo(
                    CFrame.new(destination),
                    isCurrentLever
                ) then
                    return
                end
            end

            if not isCurrentLever() then
                stopHover()
                return
            end

            if not RuntimeFix.floodHold(destination) then
                return
            end

            if not isCurrentLever()
                or (root.Position - position).Magnitude
                    > prompt.MaxActivationDistance
            then
                stopHover()
                return
            end

            -- เป้าหมายใหม่ไม่ต้องรอ Retry ของคันโยกเก่า
            if RuntimeFix.FloodLeverRetryTarget ~= leverAt then
                RuntimeFix.FloodLeverRetryTarget = leverAt
                RuntimeFix.FloodLeverRetryAt = 0
            end

            if os.clock() < (RuntimeFix.FloodLeverRetryAt or 0) then
                return
            end

            RuntimeFix.FloodLeverRetryAt =
                os.clock() + prompt.HoldDuration + 2

            RuntimeFix.FloodPrompt = prompt

            local usedNativeHold = false

            local ok, err = pcall(function()
                if not isCurrentLever() then
                    return
                end

                if type(fireproximityprompt) == "function" then
                    fireproximityprompt(prompt)
                    return
                end

                usedNativeHold = true
                prompt:InputHoldBegin()

                local deadline =
                    os.clock() + prompt.HoldDuration + 0.1

                while os.clock() < deadline
                    and isCurrentLever()
                    and (root.Position - position).Magnitude
                        <= prompt.MaxActivationDistance
                do
                    task.wait(0.05)
                end
            end)

            if usedNativeHold then
                pcall(function()
                    prompt:InputHoldEnd()
                end)
            end

            RuntimeFix.FloodPrompt = nil

            if not ok then
                RuntimeFix.floodStatus(
                    "Lever input failed: " .. tostring(err)
                )
            elseif not isCurrentLever() then
                stopHover()
            end

            -- รอ Server เปลี่ยนหรือลบ FloodLeverAt เพื่อยืนยันผล
            return
        end

        local objects = world
            and world:FindFirstChild("MapObjects")

        local gate = objects
            and objects:FindFirstChild("FloodGateZone")

        if not gate or not gate:IsA("BasePart") then
            RuntimeFix.floodStatus(label .. " | รอ GateZone")
            RuntimeFix.floodHold(root.Position)
            return
        end

        local destination = RuntimeFix.floodSafe(gate.Position)

        -- GateRadius = 18 ตามรายงาน เว้นขอบไว้ 1 stud
        if (destination - gate.Position).Magnitude > 17 then
            RuntimeFix.floodStatus(
                label .. " | Gate อยู่ต่ำกว่าระยะปลอดภัยเหนือน้ำ"
            )

            RuntimeFix.floodHold(root.Position)
            return
        end

        local progress = tonumber(
            workspace:GetAttribute("FloodGate")
        ) or 0

        RuntimeFix.floodStatus(
            ("%s | Hold Gate %.0f%% | Crowd %s"):format(
                label,
                math.clamp(progress, 0, 1) * 100,
                tostring(workspace:GetAttribute("FloodGateCrowd"))
            )
        )

        RuntimeFix.floodHold(destination)
    end

    function RuntimeFix.repairFarmCamera()
        if not AutoFarmEnabled
            or AutoFarmSession.Cancelled
            or RuntimeFix.EndRoundPaused
            or PlayerGui:GetAttribute("EndScreenActive") == true
        then
            return
        end

        local camera = workspace.CurrentCamera
        local character = getCharacter()
        local humanoid = getHumanoid()

        if not camera
            or not character
            or not humanoid
            or humanoid.Parent ~= character
            or humanoid.Health <= 0
        then
            return
        end

        -- ปล่อยกล้องสกิล / คัตซีนให้ระบบเกมควบคุม
        if camera.CameraType ~= Enum.CameraType.Custom then
            return
        end

        local subject = camera.CameraSubject
        local previousHumanoid = RuntimeFix.CameraHumanoid

        -- ซ่อมเฉพาะเป้าหมายที่หายไป หรือ Humanoid เก่า
        local needsRepair = not subject
            or not subject.Parent
            or (
                subject ~= humanoid
                and (
                    subject == previousHumanoid
                    or (
                        subject:IsA("Humanoid")
                        and subject.Health <= 0
                    )
                )
            )

        RuntimeFix.CameraHumanoid = humanoid

        if needsRepair then
            camera.CameraSubject = humanoid
        end
    end

    local function StartAutoFarm()
        if AutoFarmEnabled then
            return
        end

        AutoFarmEnabled = true

        local noclipConnection = nil
        table.insert(AutoFarmSession.Cleanups, function()
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
        end)
        noclipConnection = RunService.Stepped:Connect(function()
            if not AutoFarmEnabled or AutoFarmSession.Cancelled then
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                return
            end
            local char = getCharacter()

            RuntimeFix.repairFarmCamera()

            -- ตรวจน้ำระหว่างเดินทางด้วย ไม่ใช่เฉพาะปลายทาง
            if RuntimeFix.isFlood()
                and not RuntimeFix.FloodGroundStand
                and not RuntimeFix.EndRoundPaused
                and PlayerGui:GetAttribute("EndScreenActive") ~= true then

                local root = getCharacterRoot()
                local humanoid = getHumanoid()

                if root and humanoid and humanoid.Health > 0 then
                    local safe = RuntimeFix.floodSafe(root.Position)

                    if safe.Y > root.Position.Y then
                        if RuntimeFix.RootTweenCleanup then
                            RuntimeFix.RootTweenCleanup()
                        end

                        root.CFrame =
                            CFrame.new(safe) * root.CFrame.Rotation

                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                end
            end

            RememberCharacter(char)
            if char then
                local waiting = RuntimeFix.WaitingStand

                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        if RuntimeFix.FloodGroundStand
                            and not RuntimeFix.FloodGroundStand.Landing then
                            local original = collisionSaved[v]

                            if original ~= nil then
                                v.CanCollide = original
                            end
                        elseif waiting and v == waiting.Root then
                            v.CanCollide = true
                        elseif v.CanCollide then
                            v.CanCollide = false
                        end
                    end
                end
            end
        end)
        Spawn(function()
            while AutoFarmEnabled
                and not AutoFarmSession.Cancelled
            do
                if not ResolveGameplay() then
                    stopHover()
                    task.wait(0.5)
                    continue
                end

                local endScreen = PlayerGui:FindFirstChild("EndScreen")

                if RuntimeFix.EndRoundPaused
                    or PlayerGui:GetAttribute("EndScreenActive") == true
                    or (
                        endScreen
                        and endScreen:IsA("ScreenGui")
                        and endScreen.Enabled
                    ) then

                    stopHover()
                    resetRubbleState()
                    RuntimeFix.FateArenaCharacter = nil

                    IsHealing = false
                    SkillAimState = nil
                    CurrentAreaName = nil
                    LastTeleportedArea = nil

                    task.wait(0.2)
                    continue
                end

                -- รอให้สกิลจบก่อนเปลี่ยนเป้าหมายหรือเดินทางต่อ
                if isGameSkillBusy() then
                    task.wait(0.05)
                    continue
                end

                if RuntimeFix.isFlood() then
                    RuntimeFix.floodStep()
                    task.wait(0.15)
                    continue
                end

                if handleRaidState() then
                    task.wait(RAID_STATE_REFRESH_DELAY)
                    continue
                end

                if handleRetreatHeal() then
                    task.wait(0.1)
                    continue
                end

                -- Auto Arise only in Shadow Gate.
                if tryShadowGateArise() then
                    task.wait(0.1)
                    continue
                end

                local status = EnemyCountLabel.Text

                if status ~= LastLoggedStatus then
                    print(
                        "[AutoFarm] HUD Status:",
                        status,
                        "Parsed Area:",
                        tostring(getAreaFromStatus(status))
                    )
                    LastLoggedStatus = status
                end

                if status == "Break the rubble to continue!" then
                    local areaName =
                        CurrentAreaName or getCurrentArea()

                    local rubble = CurrentRubble

                    if areaName and (
                        not rubble
                        or not rubble.Parent
                        or tostring(CurrentRubbleArea) ~= tostring(areaName)
                    ) then
                        rubble = getRubbleForArea(areaName)
                    end

                    -- HP หมดแล้ว ห้ามเริ่มลูปใหม่แม้ข้อความ HUD ยังไม่เปลี่ยน
                    if rubble and RuntimeFix.isRubbleBroken(rubble) then
                        if RubbleModeActive or RuntimeFix.RubbleRepeatToken then
                            stopHover()
                            resetRubbleState()
                            print("[AutoFarm] Rubble destroyed -> repeat stopped")
                        end

                        task.wait(RUBBLE_ATTACK_DELAY)
                        continue
                    end

                    if areaName then
                        handleRubbleStatus(areaName)
                    end

                    if CurrentRubble
                        and CurrentRubble.Parent
                        and not RuntimeFix.isRubbleBroken(CurrentRubble)
                    then
                        local rubblePosition =
                            getRubbleAttackPosition(
                                CurrentRubble,
                                CurrentRubbleArea
                            )

                        useReadySkills(rubblePosition)
                    end

                    task.wait(RUBBLE_ATTACK_DELAY)
                    continue
                end

                -- HUD ออกจากสถานะ Rubble แล้ว หยุดก่อนเข้าระบบตีมอน
                -- ไม่ต้องรอให้หมายเลข Area เปลี่ยน
                if RubbleModeActive or RuntimeFix.RubbleRepeatToken then
                    stopHover()
                    resetRubbleState()
                    print("[AutoFarm] Rubble mode ended -> enemy farm resumed")
                end

                local areaName = getAreaFromStatus(status)

                if areaName then
                    areaName = tostring(areaName)

                    if RubbleModeActive
                        and CurrentRubbleArea
                        and CurrentRubbleArea ~= areaName
                    then
                        print(
                            "[AutoFarm] Rubble Completed ->",
                            CurrentRubbleArea,
                            "Next Area:",
                            areaName
                        )

                        stopHover()
                        resetRubbleState()
                    end

                    local areaChanged =
                        areaName ~= tostring(CurrentAreaName)

                    if areaChanged then
                        print(
                            "[AutoFarm] Area Changed:",
                            tostring(CurrentAreaName),
                            "->",
                            areaName
                        )

                        CurrentAreaName = areaName
                    end

                    if not isInRaid()
                        and LastTeleportedArea ~= areaName
                    then
                        local success = teleportToArea(areaName)

                        if success then
                            print(
                                "[AutoFarm] Teleport SUCCESS -> Area",
                                areaName
                            )
                        else
                            warn(
                                "[AutoFarm] Teleport FAILED -> Area",
                                areaName
                            )
                        end
                    end
                end

                if CurrentAreaName then
                    --==================================================
                    -- Find Enemy
                    --==================================================

                    -- ตรวจว่าเป้าหมายเดิมยังอยู่ใน Area ปัจจุบัน
                    if CurrentTarget
                        and tostring(CurrentAreaName) ~= "Infinite"
                    then
                        local targetRoot = getEnemyRoot(CurrentTarget)
                        local targetArea = targetRoot
                            and getAreaByPosition(targetRoot.Position)

                        if not targetArea
                            or tostring(targetArea.Name)
                                ~= tostring(CurrentAreaName)
                        then
                            stopHover()
                        end
                    end

                    local needSwitchFromBoss = false

                    if CurrentTarget and isEnemyAlive(CurrentTarget) then
                        if isFateRaid() then
                            local key, boss = readFateEnemy(CurrentTarget)

                            if not key then
                                needSwitchFromBoss = true

                            elseif boss then
                                needSwitchFromBoss =
                                    isRaidBossGuarded()
                                    or hasMinionsAliveInArea(CurrentAreaName)

                            elseif isRaidBossGuarded()
                                and key ~= "fateOath" then

                                local priority =
                                    getNearestEnemyInArea(CurrentAreaName)

                                needSwitchFromBoss = priority ~= nil
                                    and readFateEnemy(priority) == "fateOath"
                            end

                        elseif isShadowGateRaid() then
                            if isShadowGateMainBoss(CurrentTarget) then
                                needSwitchFromBoss =
                                    isRaidBossGuarded()
                                    or hasMinionsAliveInArea(CurrentAreaName)
                            end

                        elseif isEnemyBoss(CurrentTarget) then
                            needSwitchFromBoss =
                                hasMinionsAliveInArea(CurrentAreaName)
                        end
                    end

                    if not CurrentTarget
                        or not isEnemyAlive(CurrentTarget)
                        or not getEnemyRoot(CurrentTarget)
                        or needSwitchFromBoss
                    then
                        local enemy =
                            getNearestEnemyInArea(CurrentAreaName)

                        if enemy then
                            print(
                                "[AutoFarm] Enemy Found -> Area",
                                CurrentAreaName,
                                enemy:GetFullName()
                            )

                            -- startHover เรียก stopHover เพื่อปลดจุดรอก่อน Orbit
                            if not startHover(enemy) then
                                if isShadowGateRaid() or isFateRaid() then
                                    stopHover()
                                else
                                    holdStillWhileWaiting(CurrentAreaName)
                                end
                            end
                        else
                            if isShadowGateRaid() or isFateRaid() then
                                stopHover()
                            else
                                holdStillWhileWaiting(CurrentAreaName)
                            end
                        end
                    end

                    --==================================================
                    -- Validate Current Target
                    --==================================================

                    if CurrentTarget then
                        local enemies = workspace:FindFirstChild("enemies")

                        if not enemies or CurrentTarget.Parent ~= enemies then
                            stopHover()

                        elseif not isEnemyAlive(CurrentTarget) then
                            stopHover()

                        else
                            attackEnemy()
                            useReadySkills()
                        end
                    end
                end

                task.wait(ATTACK_DELAY)
            end

            if AutoFarmSession.Cancelled then
                AutoFarmEnabled = false
                stopHover()
                return
            end
        end)

        print("[AutoFarm] START")
    end

    --==================================================
    -- Stop
    --==================================================

    StopAutoFarm = function()
        AutoFarmEnabled = false
        IsHealing = false
        stopHover()

        CurrentAreaName = nil
        LastTeleportedArea = nil
        resetRubbleState()

        print("[AutoFarm] STOP")
    end


        -- Runtime paths are copied from the original gameplay loader.
        ResolveGameplay = function()
            local roundHUD = PlayerGui:FindFirstChild("RoundHUD")
            local container = roundHUD and roundHUD:FindFirstChild("Container")
            local top = container and container:FindFirstChild("TopPart")
            local remaining = top and top:FindFirstChild("RemainingFrame")
            local label = remaining and remaining:FindFirstChild("EnemyCount")

            local hud = PlayerGui:FindFirstChild("HUD")
            local hudRoot = hud and hud:FindFirstChild("HUD")
            local bottom = hudRoot and hudRoot:FindFirstChild("BottomLeftHolder")
            local main = bottom and bottom:FindFirstChild("main")

            local world = workspace:FindFirstChild("World")
            local areas = world and world:FindFirstChild("Areas")
            local map = world and world:FindFirstChild("Map")
            local remote = ReplicatedStorage:FindFirstChild("performM1")

            if not label or not label:IsA("TextLabel")
                or not areas or not map
                or not remote or not remote:IsA("RemoteEvent") then
                return false
            end

            EnemyCountLabel = label
            SkillsFolder = main and main:FindFirstChild("skills")
            AreasFolder = areas
            MapFolder = map
            PerformM1 = remote
            return true
        end

        local respawn = LocalPlayer.CharacterAdded:Connect(function()
            if AutoFarmSession.Cancelled then return end
            stopHover()
            resetRubbleState()
            CurrentAreaName = nil
            LastTeleportedArea = nil
            IsHealing = false
            SkillAimState = nil
        end)
        table.insert(AutoFarmSession.Cleanups, function() respawn:Disconnect() end)

        return {
            Start = function()
                RememberCharacter(LocalPlayer.Character)
                StartAutoFarm()
            end,
            Ready = ResolveGameplay,
            Cleanup = Cleanup,
        }
    end

    FarmSection:AddToggle("ZeroXAutoFarm", {
        Title = "Auto Farm",
        Description = "ใช้ในด่าน ค้นมอนตาม Area และให้ความสำคัญกับลูกน้องก่อนบอส",
        Default = false,
        Callback = function(value)
            if not alive then return end
            generation = generation + 1
            local token = generation
            StopCurrent()
            if not value then return end

            task.spawn(function()
                local ok, err = xpcall(function()
                    -- เปิดเตรียมไว้ได้ โดยยังไม่สร้างระบบฟาร์มใน Lobby
                    while alive and token == generation
                        and not ZeroXContext.IsMatch() do
                        task.wait(1)
                    end

                    if not alive or token ~= generation then return end

                    local farm = CreateFarm()
                    local deadline = os.clock() + 30
                    while alive and token == generation do
                        if farm.Ready() then
                            farm.Start()
                            return
                        end
                        assert(os.clock() < deadline,
                            "Gameplay objects unavailable after 30 seconds")
                        task.wait(0.5)
                    end
                    farm.Cleanup()
                end, function(message)
                    return debug.traceback(tostring(message), 2)
                end)
                if not ok and alive and token == generation then
                    Report(err)
                    Options.ZeroXAutoFarm:SetValue(false)
                end
            end)
        end,
    })

    FarmSection:AddToggle("ZeroXAutoStartVote", {
        Title = "Auto Start Vote",
        Description = "โหวตเริ่มด่านอัตโนมัติเมื่อเกมเปิดช่วงโหวต",
        Default = false,
    })

    FarmSection:AddDropdown("ZeroXFarmPosition", {
        Title = "Position",
        Description = "เลือกตำแหน่งฟาร์มด้านล่าง ด้านบน หรือหมุนรอบมอน",
        Values = { "Below", "Above", "Orbit" },
        Default = "Orbit",
    })

    FarmSection:AddSlider("ZeroXFarmDistance", {
        Title = "Distance",
        Description = "รัศมีแนวนอนจากมอน ใช้เฉพาะ Orbit หน่วย studs",
        Min = 0,
        Max = 30,
        Default = 4,
        Increment = 0.5,
    })

    FarmSection:AddSlider("ZeroXFarmHeight", {
        Title = "Height",
        Description = "ระยะบน/ล่างจากมอน ส่วน Orbit ใช้ความสูงด้านบน หน่วย studs",
        Min = 1,
        Max = 30,
        Default = 6,
        Increment = 0.5,
    })

    FarmSection:AddSlider("ZeroXFarmOrbitSpeed", {
        Title = "Orbit Speed",
        Description = "ความเร็วหมุน หน่วยองศาต่อวินาที ตั้ง 0 เพื่อหยุดหมุน",
        Min = 0,
        Max = 360,
        Default = 90,
        Increment = 1,
    })

    local SkillSection = Tabs.InGame:AddSection({
        Title = "Auto Skill",
        Description = "เลือกสกิลและลำดับการใช้ ขณะเปิด Auto Farm",
        Icon = "zap",
    })

    SkillSection:AddToggle("ZeroXAutoFarmSkills", {
        Title = "Auto Skill",
        Description = "เปิดการใช้สกิลอัตโนมัติระหว่างฟาร์ม",
        Default = false,
    })

    SkillSection:AddDropdown("ZeroXSelectedSkills", {
        Title = "Select Skills",
        Description = "เลือกสกิลที่ต้องการใช้ได้หลายรายการ",
        Values = {
            "Skill 1",
            "Skill 2",
            "Skill 3",
            "Ultimate (G)",
        },
        Multi = true,
        Default = { "Skill 1", "Skill 2", "Skill 3" },
    })

    SkillSection:AddToggle("ZeroXUltimateOnlyBoss", {
        Title = "Ultimate Only Boss",
        Description = "ใช้ Ultimate เฉพาะเมื่อเป้าหมายปัจจุบันเป็นบอส",
        Default = false,
    })

    SkillSection:AddToggle("ZeroXEnableSkillCombo", {
        Title = "Enable Skill Combo",
        Description = "เปิดเพื่อใช้ลำดับ Combo ที่เลือก ปิดเพื่อใช้ลำดับ 1-2-3",
        Default = false,
    })

    SkillSection:AddDropdown("ZeroXSkillCombo", {
        Title = "Skill Combo",
        Description = "ลำดับสกิลเมื่อเปิด Enable Skill Combo",
        Values = {
            "1-2-3",
            "1-3-2",
            "2-1-3",
            "2-3-1",
            "3-1-2",
            "3-2-1",
        },
        Default = "1-2-3",
    })

    local HealSection = Tabs.InGame:AddSection({
        Title = "Retreat Heal",
        Description = "ถอยเมื่อเลือดต่ำ และกลับไปสู้เมื่อฟื้นถึงค่าที่ตั้ง ใช้ขณะ Auto Farm",
        Icon = "heart",
    })

    HealSection:AddToggle("ZeroXRetreatHeal", {
        Title = "Retreat Heal",
        Description = "เปิดระบบถอยรอฟื้นเลือด",
        Default = false,
    })

    HealSection:AddSlider("ZeroXHealStartPercent", {
        Title = "Retreat Below",
        Description = "เริ่มถอยเมื่อเลือดต่ำกว่าค่านี้ (%)",
        Min = 1,
        Max = 99,
        Default = 30,
        Increment = 1,
        Callback = function(value)
            if not alive then return end

            local resume = Options.ZeroXHealResumePercent

            if resume and value >= resume.Value then
                resume:SetValue(value + 1)
            end
        end,
    })

    HealSection:AddSlider("ZeroXHealResumePercent", {
        Title = "Resume At",
        Description = "กลับไปสู้เมื่อเลือดถึงค่านี้ (%)",
        Min = 2,
        Max = 100,
        Default = 70,
        Increment = 1,
        Callback = function(value)
            if not alive then return end

            local start = Options.ZeroXHealStartPercent

            if start and value <= start.Value then
                start:SetValue(value - 1)
            end
        end,
    })

    local EndSection = Tabs.InGame:AddSection({
        Title = "End Game",
        Description = "เลือกการทำงานเมื่อจบด่าน ใช้งานได้แม้ปิด Auto Farm",
        Icon = "flag",
    })

    EndSection:AddToggle("ZeroXAutoEndGame", {
        Title = "Auto End Game",
        Description = "ทำรายการที่เลือกเมื่อหน้าจบเกมแสดงและเกมพร้อม",
        Default = false,
    })

    EndSection:AddDropdown("ZeroXEndGameAction", {
        Title = "End Game Action",
        Description = "Next Chapter จะรอให้เกมอนุญาตไปต่อก่อน",
        Values = { "Retry", "Next Chapter", "Leave" },
        Default = "Retry",
    })

    --------------------------------------------------------------------------
    -- Start Vote / End Game: มีตัวเฝ้าสถานะร่วมกันเพียงหนึ่งตัว
    --------------------------------------------------------------------------
    do
        local RS = game:GetService("ReplicatedStorage")
        local runModule = nil
        local runPackets = nil

        local voteRound = nil
        local nextVoteAt = 0

        local endSent = false
        local endReadyAt = nil
        local lastWarningAt = -math.huge

        -- ค่าควบคุมการรอของสคริปต์
        local VOTE_RETRY_SECONDS = 3
        local END_SETTLE_SECONDS = 2

        local function ReadModule(path)
            local object = RS

            for _, name in ipairs(path) do
                object = object and object:FindFirstChild(name)

                assert(object,
                    "Module unavailable: " .. table.concat(path, "."))
            end

            assert(object:IsA("ModuleScript"),
                "Expected ModuleScript: " .. object:GetFullName())

            return require(object)
        end

        local function Enabled(key)
            local control = Options[key]
            return control ~= nil and control.Value == true
        end

        local function ReadField(object, key)
            local field = object and object[key]

            assert(field and type(field.get) == "function",
                "Run state field unavailable: " .. key)

            return field:get()
        end

        local function Tick()
            if not runModule then
                runModule = ReadModule({
                    "game", "stores", "runStore",
                })
            end

            if not alive or not ZeroXContext.IsMatch() then
                return
            end

            local state = runModule.store and runModule.store.state
            assert(state, "runStore state unavailable")

            ------------------------------------------------------------------
            -- Auto Start Vote
            ------------------------------------------------------------------
            if Enabled("ZeroXAutoStartVote") then
                local status = ReadField(state, "status")
                local endsAt = workspace:GetAttribute("StartVoteEndsAt")

                if type(endsAt) == "number" and endsAt ~= voteRound then
                    voteRound = endsAt
                    nextVoteAt = 0
                end

                if status == "waiting"
                    and type(endsAt) == "number"
                    and endsAt > workspace:GetServerTimeNow()
                    and LocalPlayer:GetAttribute("StartVoted") ~= true
                    and os.clock() >= nextVoteAt then

                    local remote = RS:FindFirstChild("startVote")

                    assert(remote and remote:IsA("RemoteEvent"),
                        "ReplicatedStorage.startVote unavailable")

                    if alive and ZeroXContext.IsMatch()
                        and Enabled("ZeroXAutoStartVote") then

                        nextVoteAt = os.clock() + VOTE_RETRY_SECONDS
                        remote:FireServer(nil)
                    end
                end
            end

            ------------------------------------------------------------------
            -- End Game
            ------------------------------------------------------------------
            if not Enabled("ZeroXAutoEndGame") and not endSent then
                endReadyAt = nil
                return
            end

            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if not playerGui then return end

            local screen = playerGui:FindFirstChild("EndScreen")

            local showing = (
                screen
                and screen:IsA("ScreenGui")
                and screen.Enabled == true
            ) or playerGui:GetAttribute("EndScreenActive") == true

            local participants = state.participants

            assert(participants and type(participants.get) == "function",
                "Run participants unavailable")

            local participant = participants:get(
                tostring(LocalPlayer.UserId)
            )

            if not participant then return end

            local status = ReadField(participant, "status")

            -- ยืนยันรอบใหม่แล้วจึงอนุญาตส่งรายการครั้งถัดไป
            if status == "active" and not showing then
                endSent = false
                endReadyAt = nil
                return
            end

            if not Enabled("ZeroXAutoEndGame") then
                endReadyAt = nil
                return
            end

            if not showing or status == "active" then
                endReadyAt = nil
                return
            end

            if endSent then return end

            if ReadField(participant, "travelStatus") ~= "idle" then
                endReadyAt = nil
                return
            end

            -- คงการรอแจกรางวัล BathTub ตามระบบในไฟล์แนบ
            if status ~= "failed"
                and (
                    workspace:GetAttribute("Mode") == "spiritedawayraid"
                    or ZeroXContext.EvolvingRequested()
                ) then

                local payoutStatus = participant.payoutStatus
                    and participant.payoutStatus:get()

                local materialsAwarded = participant.materialsAwarded
                    and participant.materialsAwarded:get()

                local paid = payoutStatus == "paid"
                    or payoutStatus == "completed"
                    or materialsAwarded == true

                if not paid then
                    endReadyAt = nil
                    return
                end
            end

            local selection = Options.ZeroXEndGameAction
            local selected = selection and selection.Value
            local crafting = ZeroXContext.CraftingRequested()
            local evolving = ZeroXContext.EvolvingRequested()

            if evolving then
                if not ZeroXContext.EvolveEndAction then
                    return
                end

                selected = ZeroXContext.EvolveEndAction()

                if not selected then
                    return
                end
            elseif crafting then
                if not ZeroXContext.CraftEndAction then
                    return
                end

                selected = ZeroXContext.CraftEndAction()

                if not selected then
                    return
                end
            end

            local action

            if selected == "Retry" then
                action = 1
            elseif selected == "Next Chapter" then
                if ReadField(state, "canNext") ~= true then
                    endReadyAt = nil
                    return
                end
                action = 2
            elseif selected == "Leave" then
                action = 3
            else
                return
            end

            if not endReadyAt then
                endReadyAt = os.clock()
                return
            end

            if os.clock() - endReadyAt < END_SETTLE_SECONDS then
                return
            end

            if not runPackets then
                runPackets = ReadModule({
                    "game", "packets", "runPackets",
                })
            end

            local packet = runPackets.endAction

            assert(packet and type(packet.fire) == "function",
                "runPackets.endAction unavailable")

            if not alive or not ZeroXContext.IsMatch()
                or not Enabled("ZeroXAutoEndGame")
                or (
                    not crafting
                    and not evolving
                    and Options.ZeroXEndGameAction.Value ~= selected
                ) then
                return
            end

            -- อ่านทรัพยากรล่าสุดอีกครั้งก่อนส่ง
            if evolving and (
                not ZeroXContext.EvolvingRequested()
                or ZeroXContext.EvolveEndAction() ~= selected
            ) then
                return
            end

            if not evolving and crafting and (
                not ZeroXContext.CraftingRequested()
                or ZeroXContext.CraftEndAction() ~= selected
            ) then
                return
            end

            -- ล็อกก่อนส่ง ป้องกันคำขอซ้ำหากส่งแล้วเกิดข้อผิดพลาด
            endSent = true
            packet:fire(action)

            warn("[Zero X / End Game] Requested:", selected)
        end

        task.spawn(function()
            -- รอสร้าง Controls และโหลด Profile ก่อน
            task.wait()

            while alive do
                local needed = Enabled("ZeroXAutoStartVote")
                    or Enabled("ZeroXAutoEndGame")
                    or endSent

                if ZeroXContext.IsMatch() and needed then
                    local ok, err = pcall(Tick)

                    if not ok
                        and os.clock() - lastWarningAt >= 5 then

                        lastWarningAt = os.clock()
                        warn("[Zero X / Run Automation]", err)
                    end

                    task.wait(0.25)
                else
                    task.wait(1)
                end
            end
        end)
    end

    MacUI:OnUnload(function()
        alive = false
        generation = generation + 1
        StopCurrent()
    end)
end

--------------------------------------------------------------------------------
-- GACHA / AUTO ROLL CHARACTER
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive, runtime, pending = true, nil, nil
    local sequence, refreshAt, warningAt = 0, 0, -math.huge

    local section = Tabs.Gacha:AddSection({
        Title = "Characters",
    })

    local toggle = section:AddToggle("ZeroXAutoRollCharacter", {
        Title = "Auto Roll Character",
        Description = "สุ่มใน Lobby และแทนที่ตัวละครใน Slot ที่เลือก",
        Default = false,
    })

    local slotUI = section:AddDropdown("ZeroXRollSlot", {
        Title = "Slot",
        Description = "ช่องตัวละครที่ปลดล็อกแล้ว",
        Values = {},
        AllowNull = true,
    })

    local spinUI = section:AddDropdown("ZeroXRollSpin", {
        Title = "Spin",
        Description = "Normal หรือ Lucky; Lucky ใช้ทรัพยากรตาม Config",
        Values = { "Normal", "Lucky" },
        Default = "Normal",
    })

    local payUI = section:AddDropdown("ZeroXRollPayment", {
        Title = "Pay With (Normal)",
        Description = "ใช้ Money หรือ Rolls สำหรับ Normal เท่านั้น",
        Values = { "Money", "Rolls" },
        Default = "Money",
    })

    local characterUI = section:AddDropdown("ZeroXRollStopCharacter", {
        Title = "Stop On Character",
        Description = "เลือกหลายตัวได้; หยุดเมื่อได้ตัวใดตัวหนึ่งที่เลือก",
        Values = {},
        Multi = true,
        AllowNull = true,
        Searchable = true,
        Default = {},
    })

    local rarityUI = section:AddDropdown("ZeroXRollStopRarity", {
        Title = "Stop On Rarity Or Better",
        Description = "หยุดเมื่อได้ระดับนี้ขึ้นไป; ตรงเงื่อนไขใดเงื่อนไขหนึ่งก็หยุด",
        Values = { "None" },
        Default = "None",
    })

    local rollStatus = section:AddParagraph({
        Title = "Character Status",
        Content = "ยังไม่มีผลสุ่มในรอบสคริปต์นี้",
    })

    local function readModule(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function stop(message)
        if alive then
            toggle:SetValue(false)
        end

        warn("[Zero X / Gacha] " .. message)
    end

    local rollPool = {}

    local function refreshRollPool(config)
        local spin = spinUI.Value

        local weights = type(config.weights) == "table"
            and config.weights[spin]

        assert(
            type(weights) == "table",
            "Roll weights unavailable: " .. tostring(spin)
        )

        assert(
            type(config.rarities) == "table",
            "Roll rarities unavailable"
        )

        local characters = {}
        local allowed = {}

        for _, rarity in ipairs(config.rarityOrder) do
            local weight = weights[rarity]

            if weight ~= nil then
                assert(
                    type(weight) == "number" and weight >= 0,
                    "Invalid roll weight: " .. rarity
                )
            end

            if type(weight) == "number" and weight > 0 then
                local definition = config.rarities[rarity]

                assert(
                    type(definition) == "table"
                        and type(definition.characters) == "table",
                    "Character pool unavailable: " .. rarity
                )

                for _, key in ipairs(definition.characters) do
                    assert(
                        type(key) == "string",
                        "Invalid character key"
                    )

                    if not allowed[key] then
                        allowed[key] = true
                        table.insert(characters, key)
                    end
                end
            end
        end

        assert(#characters > 0, "Roll pool is empty")
        table.sort(characters)

        -- เก็บเฉพาะตัวเลือกเดิมที่ยังอยู่ใน Pool ใหม่
        local selected = characterUI.Value
        local keep = {}

        if type(selected) == "table" then
            for key, enabled in pairs(selected) do
                if enabled == true and allowed[key] then
                    keep[key] = true
                end
            end

        elseif type(selected) == "string" and allowed[selected] then
            -- รองรับค่าจาก Profile เก่า
            keep[selected] = true
        end

        rollPool = allowed
        characterUI:SetValues(characters)
        characterUI:SetValue(keep)
    end

    -- อัปเดตตามการเปลี่ยน Spin โดยไม่เพิ่ม Loop
    spinUI:OnChanged(function()
        if not alive or not runtime then
            return
        end

        local ok, err = pcall(refreshRollPool, runtime.config)

        if not ok then
            rollPool = {}
            characterUI:SetValues({})
            characterUI:SetValue({})
            stop(tostring(err))
        end
    end)

    local function setup()
        local config = readModule({
            "assets", "config", "characterRollConfig",
        })

        local economy = readModule({
            "assets", "config", "economyConfig",
        })

        local account = readModule({
            "global", "stores", "accountNamespace",
        })

        local perks = readModule({
            "global", "utils", "GamepassPerks",
        })

        local packets = readModule({
            "lobby", "packets",
        })

        assert(
            type(config.rarityOrder) == "table"
                and #config.rarityOrder > 0
                and type(config.rarityByCharacter) == "table",
            "Roll config unavailable"
        )

        assert(
            type(account.getLocalPlayerAccount) == "function"
                and type(perks.GetSpinCost) == "function",
            "Roll dependencies unavailable"
        )

        assert(
            packets.rollCharacter
                and type(packets.rollCharacter.fire) == "function"
                and packets.characterRolled
                and type(packets.characterRolled.on) == "function",
            "Roll packets unavailable"
        )

        local ranks = {}
        local rarities = { "None" }

        for index, name in ipairs(config.rarityOrder) do
            assert(
                type(name) == "string" and not ranks[name],
                "Invalid rarity order"
            )

            ranks[name] = index
            table.insert(rarities, name)
        end

        refreshRollPool(config)
        rarityUI:SetValues(rarities)

        local result = {
            config = config,
            economy = economy,
            account = account,
            perks = perks,
            packets = packets,
            ranks = ranks,
        }

        result.disconnect = packets.characterRolled:on(function(packet)
            if pending
                and type(packet) == "table"
                and packet.requestId == pending.id
                and packet.slot == pending.slot then

                pending.result = packet
            end
        end)

        return result
    end

    local function reached(character, rarity)
        local wantedCharacter = characterUI.Value
        local wantedRarity = rarityUI.Value

        -- หยุดเมื่อได้ตัวใดตัวหนึ่งที่เลือกและอยู่ใน Pool ปัจจุบัน
        if type(wantedCharacter) == "table" then
            if type(character) == "string"
                and rollPool[character] == true
                and wantedCharacter[character] == true then

                return true
            end

        elseif type(wantedCharacter) == "string"
            and wantedCharacter ~= "None"
            and rollPool[character] == true
            and character == wantedCharacter then

            return true
        end

        if wantedRarity and wantedRarity ~= "None" then
            local wanted = runtime.ranks[wantedRarity]

            assert(wanted, "Selected rarity unavailable")

            local actual = runtime.ranks[rarity]
                or runtime.ranks[
                    runtime.config.rarityByCharacter[character]
                ]

            assert(actual, "Character rarity unavailable")

            return actual >= wanted
        end

        return false
    end

    local function tickGacha()
        if not runtime then
            runtime = setup()
        end

        local account = runtime.account.getLocalPlayerAccount()
        assert(account, "Account not ready")

        local data = account:toTable()

        assert(
            type(data) == "table"
                and type(data.UnlockedCharacters) == "table",
            "UnlockedCharacters unavailable"
        )

        -- ตรวจรายการ Slot เป็นช่วง ไม่สแกน Workspace
        if os.clock() >= refreshAt then
            refreshAt = os.clock() + 3

            local slots = {}

            for key, value in pairs(data.UnlockedCharacters) do
                local number = type(key) == "string"
                    and key:match("^Slot(%d+)$")

                if number
                    and type(value) == "table"
                    and value.Unlocked == true then

                    table.insert(slots, number)
                end
            end

            table.sort(slots, function(a, b)
                return tonumber(a) < tonumber(b)
            end)

            local signature = table.concat(slots, ",")

            if signature ~= runtime.slotSignature then
                runtime.slotSignature = signature
                slotUI:SetValues(slots)
            end
        end

        if not toggle.Value
            or ZeroXContext.LobbyOwner ~= nil then
            return
        end

        local number = tonumber(slotUI.Value)

        local slot = number
            and data.UnlockedCharacters["Slot" .. number]

        assert(
            slot and slot.Unlocked == true,
            "Select an unlocked Slot"
        )

        if slot.Favourite == true then
            stop("Selected Slot is Favourite")
            return
        end

        -- ตรวจตัวละครเดิมก่อน เพื่อไม่สุ่มทับเป้าหมายที่มีอยู่แล้ว
        if reached(
            slot.Character,
            runtime.config.rarityByCharacter[slot.Character]
        ) then
            stop("Selected Slot already meets stop condition")
            return
        end

        local spin = spinUI.Value

        assert(
            spin == "Normal" or spin == "Lucky",
            "Invalid Spin"
        )

        local kind = "Lucky"

        if spin == "Normal" then
            assert(
                payUI.Value == "Money" or payUI.Value == "Rolls",
                "Invalid payment"
            )

            kind = payUI.Value == "Money"
                and "Normal"
                or "NormalDice"
        end

        local costs = runtime.economy.rollCosts

        local cost = costs
            and costs.character
            and costs.character[kind]

        assert(
            type(cost) == "table"
                and type(cost.currency) == "string"
                and type(cost.amount) == "number"
                and cost.amount > 0,
            "Roll cost unavailable"
        )

        local amount = kind == "Normal"
            and runtime.perks.GetSpinCost(LocalPlayer, cost.amount)
            or cost.amount

        assert(
            type(amount) == "number" and amount > 0,
            "Invalid roll cost"
        )

        local balance = data.currencies
            and data.currencies[cost.currency]

        assert(
            type(balance) == "number",
            "Currency unavailable: " .. cost.currency
        )

        if balance < amount then
            stop("Not enough " .. cost.currency)
            return
        end

        if not alive
            or not toggle.Value
            or not ZeroXContext.IsLobby() then
            return
        end

        -- ใช้ล็อกเดิมร่วมกับ Auto Join / Delivery
        ZeroXContext.LobbyOwner = "Gacha"

        sequence = sequence % 65535 + 1

        pending = {
            id = sequence,
            slot = number,
        }

        runtime.packets.rollCharacter:fire({
            spinType = spin,
            slot = number,
            paymentCurrency = cost.currency,
            requestId = sequence,
        })

        local deadline = os.clock() + 30

        -- รอคำขอเดิมให้จบ แม้ปิดแล้วเปิด Toggle ระหว่างรอ
        while alive
            and not pending.result
            and os.clock() < deadline do

            task.wait(0.1)
        end

        if not alive then
            return
        end

        local result = pending.result
        pending = nil

        if not result then
            stop("Roll result timeout; stopped")
            return
        end

        if result.success ~= true then
            stop("Roll rejected: " .. tostring(result.reason))
            return
        end

        rollStatus:SetContent(
            "Slot: " .. tostring(number)
                .. "\nCharacter: " .. tostring(result.character)
                .. "\nRarity: " .. tostring(
                    result.rarity
                    or runtime.config.rarityByCharacter[result.character]
                )
        )

        print(
            "[Zero X / Gacha]",
            number,
            result.character,
            result.rarity
        )

        if reached(result.character, result.rarity) then
            stop("Target reached: " .. tostring(result.character))
        end

        -- เว้นจังหวะให้ Account อัปเดตหลังรับผล
        task.wait(0.5)
    end

    task.spawn(function()
        task.wait()

        while alive do
            if ZeroXContext.IsLobby() then
                local ok, err = pcall(tickGacha)

                if ZeroXContext.LobbyOwner == "Gacha" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok then
                    pending = nil

                    if toggle.Value then
                        stop(tostring(err))
                    elseif os.clock() - warningAt >= 5 then
                        warningAt = os.clock()
                        warn("[Zero X / Gacha]", err)
                    end
                end
            end

            task.wait(toggle.Value and 0.5 or 3)
        end
    end)

    MacUI:OnUnload(function()
        alive = false

        if runtime and runtime.disconnect then
            if type(runtime.disconnect) == "function" then
                runtime.disconnect()
            elseif typeof(runtime.disconnect) == "RBXScriptConnection" then
                runtime.disconnect:Disconnect()
            end
        end

        if ZeroXContext.LobbyOwner == "Gacha" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- GACHA / AUTO ROLL TRAIT
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive, runtime, pending = true, nil, nil
    local sequence, lastSent, refreshAt = 0, -math.huge, 0
    local lastWarning = -math.huge
    local retryAt, cooldownBackoff = 0, 2

    -- ลำดับจาก Source ของ TraitKeepList
    -- Exotic แสดงใน UI เป็น MYTHIC
    local rank = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 5,
        Exotic = 6,
    }

    local section = Tabs.Gacha:AddSection({
        Title = "Traits",
    })

    local enabled = section:AddToggle("ZeroXAutoRollTrait", {
        Title = "Auto Roll Trait",
        Description = "ทำงานใน Lobby; สุ่มทับ Trait ของตัวละครที่เลือก",
        Default = false,
    })

    local characterUI = section:AddDropdown("ZeroXTraitCharacter", {
        Title = "Character",
        Description = "ตัวละครใน Slot ที่ปลดล็อกแล้ว",
        Values = {},
        AllowNull = true,
        Searchable = true,
    })

    local traitUI = section:AddDropdown("ZeroXTraitStopTrait", {
        Title = "Stop On Trait",
        Description = "หยุดเมื่อได้ Trait ที่เลือก; None = ไม่กำหนด",
        Values = { "None" },
        Default = "None",
        Searchable = true,
    })

    local rarityUI = section:AddDropdown("ZeroXTraitStopRarity", {
        Title = "Stop On Rarity Or Better",
        Description = "หยุดเมื่อได้ระดับนี้ขึ้นไป; MYTHIC คือ Exotic",
        Values = { "None", "Legendary" },
        Default = "Legendary",
    })

    local rollStatus = section:AddParagraph({
        Title = "Trait Status",
        Content = "ยังไม่มีผลสุ่มในรอบสคริปต์นี้",
    })

    local function module(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function stop(message)
        if alive then
            enabled:SetValue(false)
        end

        warn("[Zero X / Trait] " .. message)
    end

    local function setup()
        local config = module({
            "assets", "config", "Traits", "traitConfig",
        })

        local economy = module({
            "assets", "config", "economyConfig",
        })

        local account = module({
            "global", "stores", "accountNamespace",
        })

        local packets = module({
            "lobby", "packets",
        })

        assert(type(config) == "table", "Trait config unavailable")

        assert(
            type(account.getLocalPlayerAccount) == "function",
            "Account API unavailable"
        )

        assert(
            packets.rollTrait
                and type(packets.rollTrait.fire) == "function"
                and packets.traitRolled
                and type(packets.traitRolled.on) == "function",
            "Trait packets unavailable"
        )

        local byId = {}
        local byName = {}
        local names = { "None" }
        local present = {}

        for _, definition in pairs(config) do
            if type(definition) == "table"
                and definition.Id ~= nil then

                local id = definition.Id

                assert(
                    type(id) == "number"
                        and id > 0
                        and id % 1 == 0
                        and id <= 65535
                        and not byId[id],
                    "Invalid/duplicate Trait Id"
                )

                assert(
                    type(definition.Name) == "string"
                        and rank[definition.Rarity],
                    "Unknown Trait name/rarity"
                )

                -- เก็บไว้ตรวจ Trait ปัจจุบัน แม้ไม่ได้อยู่ใน Pool
                byId[id] = definition

                if definition.Enabled == true
                    and type(definition.Weight) == "number"
                    and definition.Weight > 0 then

                    assert(
                        not byName[definition.Name],
                        "Duplicate Trait name"
                    )

                    byName[definition.Name] = id
                    present[definition.Rarity] = true
                    table.insert(names, definition.Name)
                end
            end
        end

        assert(#names > 1, "Trait roll pool is empty")

        table.sort(names, function(a, b)
            if a == "None" then
                return b ~= "None"
            end

            if b == "None" then
                return false
            end

            return a < b
        end)

        local ordered = {}

        for rarity in pairs(present) do
            table.insert(ordered, rarity)
        end

        table.sort(ordered, function(a, b)
            return rank[a] < rank[b]
        end)

        local values = { "None" }
        local labels = {}

        for _, rarity in ipairs(ordered) do
            local label = rarity == "Exotic" and "MYTHIC" or rarity

            labels[label] = rarity
            table.insert(values, label)
        end

        traitUI:SetValues(names)
        rarityUI:SetValues(values)

        local result = {
            account = account,
            economy = economy,
            packets = packets,
            byId = byId,
            byName = byName,
            labels = labels,
        }

        result.disconnect = packets.traitRolled:on(function(packet)
            if pending
                and type(packet) == "table"
                and packet.character == pending.character
                and packet.requestId == pending.id
                and not pending.result then

                pending.result = packet
            end
        end)

        return result
    end

    local function readAccount()
        local account = runtime.account.getLocalPlayerAccount()
        assert(account, "Account not ready")

        local data = account:toTable()

        assert(
            type(data) == "table"
                and type(data.UnlockedCharacters) == "table",
            "UnlockedCharacters unavailable"
        )

        return data
    end

    local function ownedCharacters(data)
        local list = {}
        local set = {}

        for key, slot in pairs(data.UnlockedCharacters) do
            if type(key) == "string"
                and key:match("^Slot%d+$")
                and type(slot) == "table"
                and slot.Unlocked == true
                and type(slot.Character) == "string"
                and slot.Character ~= "" then

                local key = slot.Character

                local entry = data.CharactersData
                    and data.CharactersData[key]

                if type(entry) == "table"
                    and type(entry.TraitData) == "table"
                    and not set[key] then

                    set[key] = true
                    table.insert(list, key)
                end
            end
        end

        table.sort(list)
        return list, set
    end

    local function readTrait(data, character)
        local entry = data.CharactersData
            and data.CharactersData[character]

        local trait = type(entry) == "table" and entry.TraitData
        local id = type(trait) == "table" and trait.Trait

        assert(
            type(id) == "number"
                and id >= 0
                and id % 1 == 0,
            "Trait data unavailable: " .. tostring(character)
        )

        return id
    end

    local function shouldStop(id, data)
        if id == 0 then
            return false
        end

        local definition = runtime.byId[id]

        assert(
            definition,
            "Unknown Trait Id: " .. tostring(id)
        )

        assert(
            type(data.settings) == "table",
            "Keep Traits settings unavailable"
        )

        -- เคารพ Keep Traits เดิม ไม่แก้ Settings ของเกม
        if data.settings["SkipTrait" .. id] == true then
            return true, "Kept Trait: " .. definition.Name
        end

        local wanted = traitUI.Value

        if wanted and wanted ~= "None" then
            local wantedId = runtime.byName[wanted]

            assert(
                wantedId,
                "Selected Trait no longer available"
            )

            if id == wantedId then
                return true, "Target Trait: " .. definition.Name
            end
        end

        local label = rarityUI.Value

        if label and label ~= "None" then
            local rarity = runtime.labels[label]

            assert(
                rarity and rank[rarity],
                "Selected rarity unavailable"
            )

            if rank[definition.Rarity] >= rank[rarity] then
                return true, "Target rarity: " .. definition.Name
            end
        end

        return false
    end

    local function tickTrait()
        if not runtime then
            runtime = setup()
        end

        local data = readAccount()
        local list, owned = ownedCharacters(data)

        if os.clock() >= refreshAt then
            refreshAt = os.clock() + 3

            local signature = table.concat(list, ",")

            if signature ~= runtime.signature then
                runtime.signature = signature
                characterUI:SetValues(list)
            end
        end

        if not enabled.Value
            or ZeroXContext.LobbyOwner ~= nil then
            return
        end

        if os.clock() < retryAt then
            return
        end

        local character = characterUI.Value

        assert(
            type(character) == "string" and owned[character],
            "Select an owned Character"
        )

        local id = readTrait(data, character)
        local done, reason = shouldStop(id, data)

        if done then
            stop(reason)
            return
        end

        -- ตรวจ Settings ก่อนใช้ทรัพยากร แม้ยังไม่มี Trait
        assert(
            type(data.settings) == "table",
            "Keep Traits settings unavailable"
        )

        local cost = runtime.economy.rollCosts
            and runtime.economy.rollCosts.trait

        assert(
            type(cost) == "table"
                and type(cost.currency) == "string"
                and type(cost.amount) == "number"
                and cost.amount > 0,
            "Trait cost unavailable"
        )

        local balance = data.currencies
            and data.currencies[cost.currency]

        assert(
            type(balance) == "number",
            "Trait currency unavailable"
        )

        if balance < cost.amount then
            stop("Not enough " .. cost.currency)
            return
        end

        -- เว้นอย่างน้อย 1 วินาที ตามขั้นต่ำ 0.9 วินาทีใน Handler
        if os.clock() - lastSent < 1 then
            return
        end

        if not alive
            or not enabled.Value
            or not ZeroXContext.IsLobby() then
            return
        end

        ZeroXContext.LobbyOwner = "Trait"
        sequence = sequence % 65535 + 1

        pending = {
            character = character,
            id = sequence,
        }

        lastSent = os.clock()

        runtime.packets.rollTrait:fire({
            character = character,
            requestId = sequence,
        })

        local deadline = os.clock() + 10

        -- รอคำขอเดิมให้จบ แม้ปิด Toggle ระหว่างรอ
        while alive
            and not pending.result
            and os.clock() < deadline do

            task.wait(0.1)
        end

        if not alive then
            return
        end

        local result = pending.result
        pending = nil

        assert(result, "Trait response timeout; stopped")

        if result.success ~= true then
            if result.reason == "Roll is on cooldown" then
                local delay = cooldownBackoff

                retryAt = os.clock() + delay
                cooldownBackoff = math.min(delay * 2, 8)

                -- จำกัดความถี่ข้อความแจ้งเตือน
                if os.clock() - lastWarning >= 5 then
                    lastWarning = os.clock()

                    warn(
                        "[Zero X / Trait] Cooldown; retry in",
                        delay,
                        "seconds"
                    )
                end

                return
            end

            -- ข้อผิดพลาดอื่นยังหยุดพร้อมแสดงสาเหตุ
            error("Trait rejected: " .. tostring(result.reason))
        end

        cooldownBackoff = 2
        retryAt = os.clock() + 1

        local rolledId = result.traitId

        assert(
            type(rolledId) == "number"
                and runtime.byId[rolledId],
            "Unknown result Trait"
        )

        local definition = runtime.byId[rolledId]

        local rarity = definition.Rarity == "Exotic"
            and "MYTHIC"
            or definition.Rarity

        rollStatus:SetContent(
            "Character: " .. tostring(character)
                .. "\nTrait: " .. tostring(definition.Name)
                .. "\nRarity: " .. tostring(rarity)
        )

        print(
            "[Zero X / Trait]",
            character,
            runtime.byId[rolledId].Name
        )

        -- ต้องเห็นทั้ง Trait และทรัพยากรอัปเดตก่อนสุ่มต่อ
        deadline = os.clock() + 10

        while alive and os.clock() < deadline do
            local updated = readAccount()

            local currentBalance = updated.currencies
                and updated.currencies[cost.currency]

            if readTrait(updated, character) == rolledId
                and type(currentBalance) == "number"
                and currentBalance <= balance - cost.amount then

                local reached, message = shouldStop(rolledId, updated)

                if reached then
                    stop(message)
                end

                return
            end

            task.wait(0.1)
        end

        if alive then
            error("Trait/account sync timeout; stopped")
        end
    end

    task.spawn(function()
        task.wait()

        while alive do
            if ZeroXContext.IsLobby() then
                local ok, err = pcall(tickTrait)

                if ZeroXContext.LobbyOwner == "Trait" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok then
                    pending = nil

                    if enabled.Value then
                        stop(tostring(err))
                    elseif os.clock() - lastWarning >= 5 then
                        lastWarning = os.clock()
                        warn("[Zero X / Trait]", err)
                    end
                end
            end

            task.wait(enabled.Value and 0.25 or 3)
        end
    end)

    MacUI:OnUnload(function()
        alive = false

        if runtime and runtime.disconnect then
            if type(runtime.disconnect) == "function" then
                runtime.disconnect()
            elseif typeof(runtime.disconnect) == "RBXScriptConnection" then
                runtime.disconnect:Disconnect()
            end
        end

        if ZeroXContext.LobbyOwner == "Trait" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- LOBBY / AUTO CLAIM REWARDS
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive, runtime = true, nil
    local counter, lastWarning = 0, -math.huge
    local retryAt, disconnectCurrent = {}, nil

    local SCAN_SECONDS = 5
    local RETRY_SECONDS = 90
    local RESPONSE_SECONDS = 7
    local SYNC_SECONDS = 5

    local section = Tabs.Lobby:AddSection({
        Title = "Auto Claim",
    })

    local questToggle = section:AddToggle("ZeroXAutoClaimQuest", {
        Title = "Auto Claim Quest",
        Description = "รับรางวัล Quest ที่สำเร็จและยังไม่ได้รับ; Lobby เท่านั้น",
        Default = false,
    })

    local milestoneToggle = section:AddToggle("ZeroXAutoClaimMilestone", {
        Title = "Auto Claim Milestone",
        Description = "รับ Level Milestone ที่ถึงเลเวลแล้ว; Lobby เท่านั้น",
        Default = false,
    })

    local achievementToggle = section:AddToggle("ZeroXAutoClaimAchievement", {
        Title = "Auto Claim Achievement",
        Description = "รับ Achievement ที่สำเร็จและยังไม่ได้รับ; Lobby เท่านั้น",
        Default = false,
    })

    local function module(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function anyEnabled()
        return questToggle.Value
            or milestoneToggle.Value
            or achievementToggle.Value
    end

    local function readAccount()
        local account = runtime.account.getLocalPlayerAccount()
        assert(account, "Account not ready")

        local data = account:toTable()
        assert(type(data) == "table", "Account snapshot unavailable")

        return data
    end

    local function cleanupListener()
        local disconnect = disconnectCurrent
        disconnectCurrent = nil

        if type(disconnect) == "function" then
            disconnect()
        elseif typeof(disconnect) == "RBXScriptConnection" then
            disconnect:Disconnect()
        end
    end

    local function claimableIds(state, definitions)
        assert(
            type(state) == "table"
                and type(state.completed) == "table"
                and type(state.claimed) == "table",
            "Claim state unavailable"
        )

        local ids = {}

        for id, completed in pairs(state.completed) do
            if completed == true
                and state.claimed[id] ~= true
                and (not definitions or definitions[id] ~= nil) then

                table.insert(ids, id)
            end
        end

        return ids
    end

    local function allClaimed(state, ids)
        if type(state) ~= "table"
            or type(state.claimed) ~= "table" then
            return false
        end

        for _, id in ipairs(ids) do
            if state.claimed[id] ~= true then
                return false
            end
        end

        return true
    end

    local function ready(key)
        return os.clock() >= (retryAt[key] or 0)
    end

    local function findJob(data)
        ------------------------------------------------------------------------
        -- Quest: Claim All
        ------------------------------------------------------------------------
        if questToggle.Value and ready("Quest") then
            local ids = claimableIds(data.quests)

            if #ids > 0 then
                return {
                    key = "Quest",
                    toggle = questToggle,
                    request = "claimQuestRewards",
                    response = "questActionResult",
                    payload = {},

                    synced = function(updated)
                        return allClaimed(updated.quests, ids)
                    end,
                }
            end
        end

        ------------------------------------------------------------------------
        -- Achievement: Claim All
        ------------------------------------------------------------------------
        if achievementToggle.Value and ready("Achievement") then
            if not runtime.achievements then
                runtime.achievements = module({
                    "assets", "config", "achievementConfig",
                })
            end

            local definitions = runtime.achievements.achievements

            assert(
                type(definitions) == "table",
                "Achievement definitions unavailable"
            )

            local ids = claimableIds(data.achievements, definitions)

            if #ids > 0 then
                return {
                    key = "Achievement",
                    toggle = achievementToggle,
                    request = "claimAchievementRewards",
                    response = "achievementActionResult",
                    payload = {},

                    synced = function(updated)
                        return allClaimed(updated.achievements, ids)
                    end,
                }
            end
        end

        ------------------------------------------------------------------------
        -- Level Milestone: รับทีละระดับจาก Config
        ------------------------------------------------------------------------
        if milestoneToggle.Value then
            if not runtime.milestones then
                runtime.milestones = module({
                    "assets", "config", "levelMilestoneConfig",
                })
            end

            if not runtime.progression then
                runtime.progression = module({
                    "global", "utils", "levelProgression",
                })
            end

            local xp = data.currencies and data.currencies.xp

            assert(
                type(xp) == "string",
                "currencies.xp unavailable or not a string"
            )

            assert(
                type(runtime.progression.getProgress) == "function",
                "Level API unavailable"
            )

            local progress = runtime.progression.getProgress(xp)

            assert(
                type(progress) == "table"
                    and type(progress.level) == "number",
                "Account level unavailable"
            )

            assert(
                type(runtime.milestones.order) == "table"
                    and type(data.claimedLevelMilestones) == "table",
                "Milestone state unavailable"
            )

            local levels = {}

            for _, value in ipairs(runtime.milestones.order) do
                local level = tonumber(value)

                if level
                    and level >= 1
                    and level <= 65535
                    and level % 1 == 0
                    and level <= progress.level
                    and data.claimedLevelMilestones[tostring(level)] ~= true
                    and ready("Milestone:" .. level) then

                    table.insert(levels, level)
                end
            end

            table.sort(levels)

            local level = levels[1]

            if level then
                return {
                    key = "Milestone:" .. level,
                    toggle = milestoneToggle,
                    request = "claimLevelMilestone",
                    response = "levelMilestoneClaimed",
                    level = level,

                    payload = {
                        level = level,
                    },

                    synced = function(updated)
                        return type(updated.claimedLevelMilestones) == "table"
                            and updated.claimedLevelMilestones[
                                tostring(level)
                            ] == true
                    end,
                }
            end
        end
    end

    local function sendAndConfirm(job)
        local request = runtime.packets[job.request]
        local response = runtime.packets[job.response]

        assert(
            request
                and type(request.fire) == "function"
                and response
                and type(response.on) == "function",
            "Claim packet API unavailable"
        )

        counter = counter % 65535 + 1

        local requestId = counter
        local result = nil

        job.payload.requestId = requestId

        disconnectCurrent = response:on(function(packet)
            if alive
                and type(packet) == "table"
                and packet.requestId == requestId
                and (
                    job.level == nil
                    or tonumber(packet.level) == job.level
                ) then

                result = packet
            end
        end)

        assert(
            type(disconnectCurrent) == "function"
                or typeof(disconnectCurrent) == "RBXScriptConnection",
            "Listener cleanup unavailable"
        )

        if not alive
            or not job.toggle.Value
            or not ZeroXContext.IsLobby() then

            cleanupListener()
            return false, "Cancelled"
        end

        request:fire(job.payload)

        local deadline = os.clock() + RESPONSE_SECONDS

        -- รอคำขอเดิมให้จบ แม้ปิด Toggle ระหว่างรอ
        while alive
            and ZeroXContext.IsLobby()
            and not result
            and os.clock() < deadline do

            task.wait(0.1)
        end

        cleanupListener()

        if not alive or not ZeroXContext.IsLobby() then
            return false, "Cancelled"
        end

        if not result then
            return false, "Response timeout"
        end

        if result.success ~= true then
            return false, tostring(result.reason)
        end

        -- ยืนยันสถานะรับรางวัลใน Account เพิ่มเติม
        deadline = os.clock() + SYNC_SECONDS

        repeat
            if not alive or not ZeroXContext.IsLobby() then
                return false, "Cancelled"
            end

            if job.synced(readAccount()) then
                return true
            end

            task.wait(0.2)
        until os.clock() >= deadline

        return false, "Success response received; account sync timeout"
    end

    local function tickClaims()
        if ZeroXContext.LobbyOwner ~= nil then
            return
        end

        if not runtime then
            local account = module({
                "global", "stores", "accountNamespace",
            })

            assert(
                type(account.getLocalPlayerAccount) == "function",
                "Account API unavailable"
            )

            runtime = {
                account = account,
                packets = module({ "lobby", "packets" }),
            }
        end

        local job = findJob(readAccount())

        if not job
            or not alive
            or not job.toggle.Value
            or not ZeroXContext.IsLobby() then
            return
        end

        -- ตรวจซ้ำหลังโหลด Module ก่อนยึดงาน Lobby
        if ZeroXContext.LobbyOwner ~= nil then
            return
        end

        ZeroXContext.LobbyOwner = "ClaimRewards"

        -- ตั้งก่อนส่ง เพื่อไม่ลองรายการเดิมซ้ำทันทีเมื่อ Timeout
        retryAt[job.key] = os.clock() + RETRY_SECONDS

        local success, reason = sendAndConfirm(job)

        if success then
            print(
                "[Zero X / Auto Claim] Confirmed:",
                job.key
            )
        elseif alive then
            warn(
                "[Zero X / Auto Claim]",
                job.key,
                reason
            )
        end
    end

    task.spawn(function()
        task.wait()

        while alive do
            if ZeroXContext.IsLobby() and anyEnabled() then
                local ok, err = pcall(tickClaims)

                cleanupListener()

                if ZeroXContext.LobbyOwner == "ClaimRewards" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok and os.clock() - lastWarning >= 10 then
                    lastWarning = os.clock()
                    warn("[Zero X / Auto Claim]", err)
                end
            end

            task.wait(SCAN_SECONDS)
        end
    end)

    MacUI:OnUnload(function()
        alive = false
        cleanupListener()

        if ZeroXContext.LobbyOwner == "ClaimRewards" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end
--------------------------------------------------------------------------------
-- PROGRESS / AUTO UNLOCK CHARACTER SLOT
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive, runtime, pending = true, nil, nil
    local requestId, lastWarning, lastText = 0, -math.huge, nil

    local section = Tabs.Progress:AddSection({
        Title = "Character Slots",
    })

    local toggle = section:AddToggle("ZeroXAutoUnlockSlot", {
        Title = "Auto Unlock Slot",
        Description = "ปลดล็อกช่องเก็บตัวละครตามลำดับเมื่อเงินพอ; ทำงานใน Lobby",
        Default = false,
    })

    local status = section:AddParagraph({
        Title = "Status",
        Content = "ปิดใช้งาน",
    })

    local function show(text)
        if alive and text ~= lastText then
            lastText = text
            status:SetContent(text)
        end
    end

    local function module(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function setup()
        local packets = module({
            "lobby", "packets",
        })

        local account = module({
            "global", "stores", "accountNamespace",
        })

        local economy = module({
            "assets", "config", "economyConfig",
        })

        assert(
            type(account.getLocalPlayerAccount) == "function",
            "Account API unavailable"
        )

        assert(
            packets.unlockCharacterSlot
                and type(packets.unlockCharacterSlot.fire) == "function"
                and packets.characterSlotActionResult
                and type(packets.characterSlotActionResult.on) == "function",
            "Unlock packets unavailable"
        )

        local count = economy.characterSlotCount

        assert(
            type(count) == "number"
                and count % 1 == 0
                and count >= 1
                and count <= 255,
            "Invalid characterSlotCount"
        )

        assert(
            type(economy.characterSlotUnlockCosts) == "table",
            "Slot costs unavailable"
        )

        local result = {
            packets = packets,
            account = account,
            economy = economy,
            count = count,
        }

        result.disconnect = packets.characterSlotActionResult:on(function(packet)
            if pending
                and type(packet) == "table"
                and packet.action == "unlock"
                and packet.slot == pending.slot
                and packet.requestId == pending.id then

                pending.result = packet
            end
        end)

        return result
    end

    local function readAccount()
        local account = runtime.account.getLocalPlayerAccount()

        if not account then
            return nil
        end

        local data = account:toTable()

        if type(data) ~= "table"
            or type(data.UnlockedCharacters) ~= "table" then
            return nil
        end

        return data
    end

    local function tickUnlock()
        if ZeroXContext.LobbyOwner ~= nil then
            show(
                "รอระบบ Lobby: "
                    .. tostring(ZeroXContext.LobbyOwner)
            )
            return
        end

        if not runtime then
            runtime = setup()
        end

        local data = readAccount()

        if not data then
            show("รอข้อมูลบัญชี")
            return
        end

        local selected, cost

        -- ใช้จำนวน Slot จาก Config ไม่กำหนดจำนวนช่องตายตัว
        for slot = 2, runtime.count do
            local entry = data.UnlockedCharacters["Slot" .. slot]

            if type(entry) ~= "table"
                or type(entry.Unlocked) ~= "boolean" then

                show("รอข้อมูล Slot " .. slot)
                return
            end

            if not entry.Unlocked then
                selected = slot
                cost = runtime.economy.characterSlotUnlockCosts[slot]

                assert(
                    type(cost) == "number"
                        and cost >= 0
                        and cost < math.huge,
                    "Unlock cost unavailable: Slot " .. slot
                )

                break
            end
        end

        if not selected then
            show("ปลดล็อก Slot ครบแล้ว")
            return
        end

        local money = data.currencies
            and tonumber(data.currencies.money)

        if money == nil then
            show("รอข้อมูล Money")
            return
        end

        if money < cost then
            show(
                "รอเงินสำหรับ Slot " .. selected
                    .. "\nMoney: " .. tostring(money)
                    .. " / " .. tostring(cost)
            )
            return
        end

        if not alive
            or not toggle.Value
            or not ZeroXContext.IsLobby()
            or ZeroXContext.LobbyOwner ~= nil then
            return
        end

        ZeroXContext.LobbyOwner = "UnlockSlot"

        requestId = requestId % 65535 + 1

        pending = {
            slot = selected,
            id = requestId,
        }

        show(
            "กำลังปลดล็อก Slot " .. selected
                .. "\nค่าใช้จ่าย: " .. tostring(cost) .. " Money"
        )

        runtime.packets.unlockCharacterSlot:fire({
            slot = selected,
            requestId = requestId,
        })

        local deadline = os.clock() + 8

        -- รอคำขอเดิมให้จบ แม้ปิด Toggle ระหว่างรอ
        while alive
            and ZeroXContext.IsLobby()
            and os.clock() < deadline do

            local response = pending.result

            if response and response.success ~= true then
                error(
                    "Slot " .. selected
                        .. " rejected: " .. tostring(response.reason)
                )
            end

            local updated = readAccount()

            local entry = updated
                and updated.UnlockedCharacters["Slot" .. selected]

            -- ยืนยันจากสถานะบัญชีจริงก่อนทำ Slot ถัดไป
            if type(entry) == "table"
                and entry.Unlocked == true then

                pending = nil
                show("ปลดล็อก Slot " .. selected .. " สำเร็จ")

                print(
                    "[Zero X / Unlock Slot] Confirmed:",
                    selected
                )
                return
            end

            task.wait(0.2)
        end

        if alive and ZeroXContext.IsLobby() then
            error(
                "Slot " .. selected
                    .. " unlock not confirmed; stopped"
            )
        end

        pending = nil
    end

    task.spawn(function()
        task.wait()

        while alive do
            if not toggle.Value then
                show("ปิดใช้งาน")

            elseif not ZeroXContext.IsLobby() then
                show("เปิดใช้งานแล้ว — รอเข้า Lobby")

            else
                local ok, err = pcall(tickUnlock)
                pending = nil

                if ZeroXContext.LobbyOwner == "UnlockSlot" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok then
                    toggle:SetValue(false)
                    show("หยุด: " .. tostring(err))

                    if os.clock() - lastWarning >= 5 then
                        lastWarning = os.clock()
                        warn("[Zero X / Unlock Slot]", err)
                    end
                end
            end

            task.wait(3)
        end
    end)

    MacUI:OnUnload(function()
        alive = false

        if runtime and runtime.disconnect then
            if type(runtime.disconnect) == "function" then
                runtime.disconnect()
            elseif typeof(runtime.disconnect) == "RBXScriptConnection" then
                runtime.disconnect:Disconnect()
            end
        end

        if ZeroXContext.LobbyOwner == "UnlockSlot" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- PROGRESS / AUTO SKILL TREE
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive, runtime, pending = true, nil, nil
    local sequence, characterCursor, warningAt = 0, 0, -math.huge
    local branchCursor = {}

    local section = Tabs.Progress:AddSection({
        Title = "Skill Tree",
    })

    local toggle = section:AddToggle("ZeroXAutoSkillTree", {
        Title = "Auto Skill Tree",
        Description = "อัป Tier ถัดไปของตัวละครและ Branch ที่เลือกเมื่อ Token พอ; Lobby เท่านั้น",
        Default = false,
    })

    local charactersUI = section:AddDropdown("ZeroXSkillTreeCharacters", {
        Title = "Characters",
        Description = "เลือกตัวละครได้หลายตัว",
        Values = {},
        Multi = true,
        AllowNull = true,
        Searchable = true,
        Default = {},
    })

    local branchesUI = section:AddDropdown("ZeroXSkillTreeBranches", {
        Title = "Branches",
        Description = "เลือกสายที่ต้องการอัปได้หลายสาย",
        Values = {},
        Multi = true,
        AllowNull = true,
        Default = {},
    })

    local function module(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function setup()
        local account = module({
            "global", "stores", "accountNamespace",
        })

        local config = module({
            "assets", "config", "characterSkillTreeConfig",
        })

        local progression = module({
            "global", "utils", "characterLevelProgression",
        })

        local packets = module({
            "lobby", "modules", "skillTree", "skillTreePackets",
        })

        assert(
            type(account.getLocalPlayerAccount) == "function",
            "Account API unavailable"
        )

        assert(
            type(config.characters) == "table"
                and type(config.branchOrder) == "table"
                and #config.branchOrder > 0,
            "Skill Tree config unavailable"
        )

        assert(
            type(progression.getAvailableTokens) == "function",
            "Skill Token API unavailable"
        )

        assert(
            packets.purchaseCharacterSkill
                and type(packets.purchaseCharacterSkill.fire) == "function"
                and packets.characterSkillPurchaseResult
                and type(packets.characterSkillPurchaseResult.on) == "function",
            "Skill Tree packets unavailable"
        )

        local result = {
            account = account,
            config = config,
            progression = progression,
            packets = packets,
        }

        result.disconnect = packets.characterSkillPurchaseResult:on(function(packet)
            if pending
                and type(packet) == "table"
                and packet.requestId == pending.id
                and packet.character == pending.character
                and packet.branch == pending.branch
                and packet.tier == pending.tier then

                pending.result = packet
            end
        end)

        return result
    end

    local function readAccount()
        local account = runtime.account.getLocalPlayerAccount()

        if not account then
            return nil
        end

        local data = account:toTable()

        if type(data) ~= "table"
            or type(data.UnlockedCharacters) ~= "table"
            or type(data.CharactersData) ~= "table" then
            return nil
        end

        return data
    end

    local function updateLists(data)
        local names = {}
        local seen = {}
        local branchSet = {}

        for slotKey, slot in pairs(data.UnlockedCharacters) do
            if type(slotKey) == "string"
                and slotKey:match("^Slot%d+$")
                and type(slot) == "table"
                and slot.Unlocked == true
                and type(slot.Character) == "string" then

                local key = string.lower(slot.Character)
                local definition = runtime.config.characters[key]

                if not seen[key]
                    and type(definition) == "table"
                    and type(definition.branches) == "table"
                    and type(data.CharactersData[key]) == "table" then

                    seen[key] = true
                    table.insert(names, key)

                    for _, branch in ipairs(runtime.config.branchOrder) do
                        assert(
                            type(branch) == "string",
                            "Invalid branch key"
                        )

                        if type(definition.branches[branch]) == "table" then
                            branchSet[branch] = true
                        end
                    end
                end
            end
        end

        table.sort(names)

        local branches = {}

        for _, branch in ipairs(runtime.config.branchOrder) do
            if branchSet[branch] then
                table.insert(branches, branch)
            end
        end

        local namesSignature = table.concat(names, ",")
        local branchesSignature = table.concat(branches, ",")

        -- อัปเดต UI เฉพาะเมื่อรายการเปลี่ยน
        if runtime.namesSignature ~= namesSignature then
            runtime.namesSignature = namesSignature
            charactersUI:SetValues(names)
        end

        if runtime.branchesSignature ~= branchesSignature then
            runtime.branchesSignature = branchesSignature
            branchesUI:SetValues(branches)
        end

        return names
    end

    local function findUpgrade(data, names)
        if #names == 0 then
            return
        end

        local selectedCharacters = charactersUI.Value
        local selectedBranches = branchesUI.Value

        if type(selectedCharacters) ~= "table"
            or type(selectedBranches) ~= "table" then
            return
        end

        local order = runtime.config.branchOrder

        -- วนสลับตัวละครและ Branch หลังซื้อสำเร็จ
        for offset = 1, #names do
            local characterIndex =
                (characterCursor + offset - 1) % #names + 1

            local character = names[characterIndex]

            if selectedCharacters[character] == true then
                local progress = data.CharactersData[character].Progression

                assert(
                    type(progress) == "table"
                        and type(progress.Skills) == "table"
                        and progress.Xp ~= nil,
                    "Progression unavailable: " .. character
                )

                local skills = {}

                for branch, value in pairs(progress.Skills) do
                    local tier = tonumber(value)

                    assert(
                        tier and tier >= 1 and tier % 1 == 0,
                        "Invalid current Tier"
                    )

                    skills[branch] = tier
                end

                local tokens = runtime.progression.getAvailableTokens(
                    character,
                    progress.Xp,
                    skills
                )

                assert(
                    type(tokens) == "number",
                    "Available Tokens unavailable"
                )

                if tokens > 0 then
                    local branches =
                        runtime.config.characters[character].branches

                    for step = 1, #order do
                        local index = (
                            (branchCursor[character] or 0) + step - 1
                        ) % #order + 1

                        local branch = order[index]
                        local definition = branches[branch]

                        if selectedBranches[branch] == true
                            and type(definition) == "table" then

                            -- ใช้ฐาน Tier 1 ตามระบบในไฟล์เดิม
                            local tier = (skills[branch] or 1) + 1

                            assert(
                                type(definition.tiers) == "table",
                                "Branch tiers unavailable"
                            )

                            local nextTier = definition.tiers[tier]

                            -- ไม่มี Tier ถัดไป = ไม่ส่งคำขอซื้อ
                            if nextTier ~= nil then
                                local cost = type(nextTier) == "table"
                                    and tonumber(nextTier.cost)

                                assert(
                                    cost
                                        and cost >= 0
                                        and cost < math.huge,
                                    "Invalid Skill Tier cost"
                                )

                                if tokens >= cost then
                                    return {
                                        character = character,
                                        branch = branch,
                                        tier = tier,
                                        cost = cost,
                                        characterIndex = characterIndex,
                                        branchIndex = index,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function tickTree()
        if not runtime then
            runtime = setup()
        end

        local data = readAccount()

        if not data then
            return
        end

        local names = updateLists(data)

        if not toggle.Value
            or ZeroXContext.LobbyOwner ~= nil then
            return
        end

        local job = findUpgrade(data, names)

        if not job
            or not alive
            or not toggle.Value
            or not ZeroXContext.IsLobby()
            or ZeroXContext.LobbyOwner ~= nil then
            return
        end

        ZeroXContext.LobbyOwner = "SkillTree"

        sequence = sequence % 65535 + 1
        job.id = sequence
        pending = job

        runtime.packets.purchaseCharacterSkill:fire({
            character = job.character,
            branch = job.branch,
            tier = job.tier,
            requestId = job.id,
        })

        local deadline = os.clock() + 5

        -- รอคำขอเดิม แม้ปิด Toggle ระหว่างรอ
        while alive
            and ZeroXContext.IsLobby()
            and not job.result
            and os.clock() < deadline do

            task.wait(0.1)
        end

        if not alive or not ZeroXContext.IsLobby() then
            return
        end

        assert(
            job.result,
            "Skill purchase response timeout; stopped"
        )

        assert(
            job.result.success == true,
            "Skill purchase rejected: "
                .. tostring(job.result.reason)
        )

        -- ยืนยัน Tier ในบัญชีก่อนอนุญาตซื้อครั้งถัดไป
        deadline = os.clock() + 5

        while alive
            and ZeroXContext.IsLobby()
            and os.clock() < deadline do

            local updated = readAccount()

            local character = updated
                and updated.CharactersData[job.character]

            local progress = type(character) == "table"
                and character.Progression

            local skills = type(progress) == "table"
                and progress.Skills

            local tier = type(skills) == "table"
                and tonumber(skills[job.branch])

            if tier and tier >= job.tier then
                characterCursor = job.characterIndex
                branchCursor[job.character] = job.branchIndex
                pending = nil

                print(
                    "[Zero X / Skill Tree] Confirmed:",
                    job.character,
                    job.branch,
                    job.tier
                )
                return
            end

            task.wait(0.2)
        end

        if alive and ZeroXContext.IsLobby() then
            error("Skill Tree account sync timeout; stopped")
        end
    end

    task.spawn(function()
        task.wait()

        while alive do
            if ZeroXContext.IsLobby() then
                local ok, err = pcall(tickTree)
                pending = nil

                if ZeroXContext.LobbyOwner == "SkillTree" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok then
                    if toggle.Value then
                        toggle:SetValue(false)
                    end

                    if os.clock() - warningAt >= 10 then
                        warningAt = os.clock()
                        warn("[Zero X / Skill Tree]", err)
                    end
                end
            end

            task.wait(toggle.Value and 1 or 3)
        end
    end)

    MacUI:OnUnload(function()
        alive = false

        if runtime and runtime.disconnect then
            if type(runtime.disconnect) == "function" then
                runtime.disconnect()
            elseif typeof(runtime.disconnect) == "RBXScriptConnection" then
                runtime.disconnect:Disconnect()
            end
        end

        if ZeroXContext.LobbyOwner == "SkillTree" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- PROGRESS / BEST GEAR
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive, runtime = true, nil
    local retryAt, warningAt = {}, -math.huge

    local section = Tabs.Progress:AddSection({
        Title = "Best Gear",
    })

    local accessoryToggle = section:AddToggle("ZeroXEquipBestAccessory", {
        Title = "Equip Best Accessory",
        Description = "เลือกคะแนน Buff สูงสุดแยกตามช่อง; ทำงานใน Lobby",
        Default = false,
    })

    local titleToggle = section:AddToggle("ZeroXEquipBestTitle", {
        Title = "Equip Best Title",
        Description = "เลือก Tier สูงสุด แล้วเทียบ Buff ตามเกณฑ์เดิม; ทำงานใน Lobby",
        Default = false,
    })

    -- ช่องที่ระบบเดิมรองรับ
    local slots = { "Head", "Face", "Neck", "Back" }

    local validSlot = {
        Head = true,
        Face = true,
        Neck = true,
        Back = true,
    }

    -- ลำดับเทียบ Title ตามโค้ดเดิม
    local priority = {
        "Damage",
        "Critical Damage",
        "Critical Chance",
        "Cooldown Reduction",
        "Drop Rate",
        "Exp",
        "Coins",
        "HP",
        "Walk Speed",
    }

    local function module(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function readAccount()
        local account = runtime.account.getLocalPlayerAccount()

        if not account then
            return nil
        end

        local data = account:toTable()
        return type(data) == "table" and data or nil
    end

    local function smallerId(a, b)
        local na = tonumber(a) or math.huge
        local nb = tonumber(b) or math.huge

        if na ~= nb then
            return na < nb
        end

        return a < b
    end

    local function bestAccessories(data)
        assert(
            type(data.accessory) == "table",
            "Accessory inventory unavailable"
        )

        if not runtime.accessories then
            runtime.accessories = module({
                "assets", "config", "accessoryConfig",
            })
        end

        local best = {}

        for rawId, amount in pairs(data.accessory) do
            if (tonumber(amount) or 0) > 0 then
                local id = tostring(rawId)
                local item = runtime.accessories[id]

                if type(item) == "table"
                    and validSlot[item.Slot] then

                    local score = 0

                    if type(item.Buffs) == "table" then
                        for _, buff in ipairs(item.Buffs) do
                            if type(buff) == "table" then
                                score += tonumber(buff.Percent) or 0
                                score += tonumber(buff.Amount) or 0
                            end
                        end
                    end

                    local old = best[item.Slot]

                    if not old
                        or score > old.score
                        or (
                            score == old.score
                            and smallerId(id, old.id)
                        ) then

                        best[item.Slot] = {
                            id = id,
                            name = item.Name or id,
                            score = score,
                        }
                    end
                end
            end
        end

        return best
    end

    local function titleBuffs(definition)
        local result = {}

        if type(definition.Buffs) == "table" then
            for _, buff in ipairs(definition.Buffs) do
                if type(buff) == "table"
                    and type(buff.Type) == "string" then

                    result[buff.Type] = tonumber(
                        buff.Percent or buff.Amount or 0
                    ) or 0
                end
            end
        end

        return result
    end

    local function betterTitle(a, b)
        if not b then
            return true
        end

        if a.tier ~= b.tier then
            return a.tier > b.tier
        end

        for _, stat in ipairs(priority) do
            local av = a.buffs[stat] or 0
            local bv = b.buffs[stat] or 0

            if av ~= bv then
                return av > bv
            end
        end

        return smallerId(a.id, b.id)
    end

    local function bestTitle(data)
        assert(
            type(data.title) == "table",
            "Title inventory unavailable"
        )

        if not runtime.titles then
            runtime.titles = module({
                "assets", "config", "titleConfig",
            })
        end

        local best

        for rawId, unlocked in pairs(data.title) do
            if unlocked == true then
                local id = tostring(rawId)

                local definition = runtime.titles[id]
                    or runtime.titles[tonumber(id)]

                if type(definition) == "table" then
                    local candidate = {
                        id = id,
                        name = definition.Name or id,
                        tier = tonumber(definition.Tier) or 0,
                        buffs = titleBuffs(definition),
                    }

                    if betterTitle(candidate, best) then
                        best = candidate
                    end
                end
            end
        end

        return best
    end

    local function equip(job)
        if not alive
            or not job.toggle.Value
            or not ZeroXContext.IsLobby()
            or ZeroXContext.LobbyOwner ~= nil then
            return
        end

        if os.clock() < (retryAt[job.key] or 0) then
            return
        end

        local packet = runtime.packets[job.packet]

        assert(
            packet and type(packet.fire) == "function",
            "Equip packet unavailable: " .. job.packet
        )

        ZeroXContext.LobbyOwner = "BestGear"

        -- ป้องกันส่งรายการเดิมซ้ำถี่เมื่อยังไม่ยืนยันผล
        retryAt[job.key] = os.clock() + 30

        packet:fire(job.id)

        local deadline = os.clock() + 5

        while alive
            and ZeroXContext.IsLobby()
            and os.clock() < deadline do

            local updated = readAccount()

            if updated and job.confirmed(updated) then
                print(
                    "[Zero X / Best Gear] Confirmed:",
                    job.key,
                    job.name
                )
                return
            end

            task.wait(0.2)
        end

        if alive and ZeroXContext.IsLobby() then
            warn(
                "[Zero X / Best Gear] Equip not confirmed:",
                job.key,
                job.id
            )
        end
    end

    local function tickGear()
        if ZeroXContext.LobbyOwner ~= nil then
            return
        end

        if not runtime then
            local account = module({
                "global", "stores", "accountNamespace",
            })

            assert(
                type(account.getLocalPlayerAccount) == "function",
                "Account API unavailable"
            )

            runtime = {
                account = account,
                packets = module({ "lobby", "packets" }),
            }
        end

        local data = readAccount()

        if not data then
            return
        end

        if accessoryToggle.Value then
            local best = bestAccessories(data)

            assert(
                type(data.equippedAccessories) == "table",
                "Equipped accessories unavailable"
            )

            for _, slot in ipairs(slots) do
                local target = best[slot]

                if target
                    and tostring(data.equippedAccessories[slot] or "")
                        ~= target.id
                    and os.clock() >= (
                        retryAt["Accessory:" .. slot .. ":" .. target.id] or 0
                    ) then

                    equip({
                        key = "Accessory:" .. slot .. ":" .. target.id,
                        id = target.id,
                        name = target.name,
                        toggle = accessoryToggle,
                        packet = "setEquippedAccessory",

                        confirmed = function(updated)
                            return type(updated.equippedAccessories) == "table"
                                and tostring(
                                    updated.equippedAccessories[slot] or ""
                                ) == target.id
                        end,
                    })

                    return
                end
            end
        end

        if titleToggle.Value then
            local target = bestTitle(data)

            if target
                and tostring(data.equippedTitle or "none") ~= target.id then

                equip({
                    key = "Title:" .. target.id,
                    id = target.id,
                    name = target.name,
                    toggle = titleToggle,
                    packet = "equipTitle",

                    confirmed = function(updated)
                        return tostring(updated.equippedTitle) == target.id
                    end,
                })
            end
        end
    end

    task.spawn(function()
        task.wait()

        while alive do
            if ZeroXContext.IsLobby()
                and (accessoryToggle.Value or titleToggle.Value) then

                local ok, err = pcall(tickGear)

                if ZeroXContext.LobbyOwner == "BestGear" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok and os.clock() - warningAt >= 10 then
                    warningAt = os.clock()
                    warn("[Zero X / Best Gear]", err)
                end
            end

            task.wait(5)
        end
    end)

    MacUI:OnUnload(function()
        alive = false

        if ZeroXContext.LobbyOwner == "BestGear" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

function ZeroXContext.MultiSelection(value)
    local result = {}

    if type(value) == "string" and value ~= "" then
        result[value] = true
    elseif type(value) == "table" then
        for key, enabled in pairs(value) do
            if type(key) == "number"
                and type(enabled) == "string" then
                result[enabled] = true
            elseif type(key) == "string" and enabled == true then
                result[key] = true
            end
        end
    end

    return result
end

--------------------------------------------------------------------------------
-- CRAFTING / ACCESSORY
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local TS = game:GetService("TeleportService")
    local Http = game:GetService("HttpService")
    local KEY = "ZeroX.Crafting.v1." .. LocalPlayer.UserId

    local alive, ready, restoring = true, false, false
    local runtime, launched, lastText, lastError = nil, false, nil, nil
    local savedJSON = nil

    local state = {
        version = 1,
        backups = {},
        values = {},
    }

    local section = Tabs.Crafting:AddSection({
        Title = "Accessory Crafting",
    })

    local itemUI, craftUI, farmUI
    local accessoryIcons = {}

    local function save()
        if not ready or restoring then return end

        state.enabled = craftUI.Value
        state.farm = farmUI.Value
        state.target = ZeroXContext.MultiSelection(itemUI.Value)
        state.money = nil
        state.icons = next(accessoryIcons)
            and accessoryIcons or state.icons

        local encoded = Http:JSONEncode(state)

        if encoded ~= savedJSON then
            TS:SetTeleportSetting(KEY, encoded)
            savedJSON = encoded
        end
    end

    itemUI = section:AddDropdown("ZeroXCraftAccessory", {
        Title = "Accessory",
        Values = {},
        Multi = true,
        Default = {},
        AllowNull = true,
        Searchable = true,
        Description = "เลือกหลายสูตร; ทำตามลำดับรายการและข้ามของที่มีแล้ว",

        Callback = function()
            if ready and not restoring
                and craftUI and craftUI.Value then

                craftUI:SetValue(false)
                lastError =
                    "เปลี่ยนรายการ — เปิด Auto Craft ใหม่เพื่อเริ่ม"
            end

            save()
        end,
    })

    -- รองรับค่าแบบเลือกตัวเดียวจาก Profile / Checkpoint เดิม
    do
        local originalSetValue = itemUI.SetValue

        function itemUI:SetValue(value)
            originalSetValue(
                self,
                ZeroXContext.MultiSelection(value)
            )
        end
    end

    -- รูปเล็กข้างชื่อ เฉพาะ Dropdown Accessory
    do
        local originalOpenMenu = Window._OpenMenu

        assert(
            type(originalOpenMenu) == "function",
            "MacUI dropdown menu API unavailable"
        )

        local function OpenMenuWithAccessoryIcons(self, anchor, info)
            local isAccessory = info.Values == itemUI.Values

            if isAccessory then
                info = table.clone(info)
                info.MinWidth = math.max(info.MinWidth or 0, 260)
            end

            local popup = originalOpenMenu(self, anchor, info)

            if not isAccessory or not popup or not popup.Canvas then
                return popup
            end

            local icons = next(accessoryIcons)
                and accessoryIcons or state.icons

            if type(icons) ~= "table" then
                return popup
            end

            -- ตรวจรายการครั้งเดียวเมื่อเปิดเมนู ไม่มี Loop สแกนต่อเนื่อง
            for _, row in ipairs(popup.Canvas:GetDescendants()) do
                if row:IsA("TextButton") and row.Name == "Item" then
                    local value = info.Values[row.LayoutOrder]
                    local image = value and icons[value]
                    local label = row:FindFirstChildWhichIsA("TextLabel")

                    if type(image) == "string" and label then
                        local icon = Instance.new("ImageLabel")
                        icon.Name = "AccessoryIcon"
                        icon.BackgroundTransparency = 1
                        icon.AnchorPoint = Vector2.new(0, 0.5)
                        icon.Position = UDim2.new(0, 26, 0.5, 0)
                        icon.Size = UDim2.fromOffset(20, 20)
                        icon.ScaleType = Enum.ScaleType.Fit
                        icon.ImageColor3 = Color3.new(1, 1, 1)
                        icon.Image = image
                        icon.ZIndex = label.ZIndex
                        icon.Parent = row

                        -- เว้นที่สำหรับเครื่องหมายเลือกและรูปไอเทม
                        label.Position = UDim2.fromOffset(52, 0)
                        label.Size = UDim2.new(1, -58, 1, 0)
                    end
                end
            end

            return popup
        end

        Window._OpenMenu = OpenMenuWithAccessoryIcons

        MacUI:OnUnload(function()
            if Window._OpenMenu == OpenMenuWithAccessoryIcons then
                Window._OpenMenu = originalOpenMenu
            end
        end)
    end

    craftUI = section:AddToggle("ZeroXAutoCraftAccessory", {
        Title = "Auto Craft",
        Default = false,
        Callback = save,
    })

    farmUI = section:AddToggle("ZeroXAutoFarmCraftMaterial", {
        Title = "Auto Farm Material",
        Default = false,
        Description = "ใช้ร่วมกับ Auto Craft;",
        Callback = save,
    })

    local status = section:AddParagraph({
        Title = "Status",
        Content = "รอเริ่มระบบ",
    })

    local function show(text)
        if alive and text ~= lastText then
            lastText = text
            status:SetContent(text)
        end
    end

    local function module(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)

            assert(
                object,
                "Module unavailable: " .. table.concat(path, ".")
            )
        end

        assert(object:IsA("ModuleScript"), "Expected ModuleScript")
        return require(object)
    end

    local function setOption(key, value)
        local option = Options[key]
        assert(option, "Control unavailable: " .. key)

        if option.Value ~= value then
            option:SetValue(value)
        end
    end

    local function borrow(key, value)
        local place = tostring(game.PlaceId)

        state.backups[place] = state.backups[place] or {}
        local backup = state.backups[place]

        if backup[key] == nil then
            assert(Options[key], "Control unavailable: " .. key)

            backup[key] = {
                value = Options[key].Value,
            }

            save()
        end

        setOption(key, value)
    end

    local function restore()
        ZeroXContext.CraftRoute = nil

        local place = tostring(game.PlaceId)
        local backup = state.backups[place]

        if backup then
            for key, entry in pairs(backup) do
                if Options[key] then
                    setOption(key, entry.value)
                end
            end

            state.backups[place] = nil
        end

        launched = false
    end

    local function halt(message)
        lastError = message
        restore()

        craftUI:SetValue(false)
        state.mission = nil

        save()
        show(message)
        warn("[Zero X / Crafting]", message)
    end

    local function setup()
        local account = module({
            "global", "stores", "accountNamespace",
        })

        local items = module({
            "assets", "config", "accessoryConfig",
        })

        local recipes = module({
            "assets", "config", "accessoryCraftConfig",
        })

        local materialConfig = module({
            "assets", "config", "materialConfig",
        })

        local materialNames = {}

        for id, entry in pairs(materialConfig) do
            if type(entry) == "table"
                and type(entry.Name) == "string"
                and entry.Name ~= "" then

                materialNames[tostring(id)] = entry.Name
            end
        end

        local drops = module({
            "assets", "config", "materialDropConfig",
        })

        local modes = module({
            "lobby", "enums", "gamemodeSelectEnum",
        })

        local packets = module({
            "lobby", "packets",
        })

        assert(
            type(account.getLocalPlayerAccount) == "function",
            "Account API unavailable"
        )

        assert(
            type(recipes) == "table" and type(items) == "table",
            "Craft config unavailable"
        )

        assert(
            packets.craftAccessory
                and type(packets.craftAccessory.fire) == "function",
            "Craft packet unavailable"
        )

        local lookup, values = {}, {}
        table.clear(accessoryIcons)
        state.icons = accessoryIcons

        for rawKey, recipe in pairs(recipes) do
            if type(recipe) == "table"
                and recipe.CarftID ~= nil then

                local key = tostring(rawKey)
                local id = tostring(recipe.CarftID)
                local item = items[id]

                assert(
                    type(item) == "table"
                        and type(item.Name) == "string",
                    "Unknown crafted Accessory: " .. id
                )

                assert(
                    type(recipe.Misc) == "string",
                    "Invalid material recipe: " .. key
                )

                local materials = {}

                if not recipe.Misc:match("^%s*$") then
                    for part in (recipe.Misc .. "|"):gmatch("(.-)|") do
                        local mid, amount = part:match(
                            "^%s*(%d+)%s*,%s*(%d+)%s*$"
                        )

                        amount = tonumber(amount)

                        assert(
                            mid and amount and amount > 0,
                            "Invalid material recipe: " .. key
                        )

                        materials[mid] = (materials[mid] or 0) + amount
                    end
                end

                local label = item.Name .. " [" .. key .. "]"
                assert(not lookup[label], "Duplicate recipe label")

                local iconRaw = item.Icon

                state.icons[label] = type(iconRaw) == "string"
                    and iconRaw:match("^%d+$")
                    and ("rbxassetid://" .. iconRaw)
                    or "rbxassetid://119682824932913"

                lookup[label] = {
                    key = key,
                    id = id,
                    name = item.Name,
                    materials = materials,
                }

                table.insert(values, label)
            end
        end

        table.sort(values)
        assert(#values > 0, "No craft recipes")

        local previous = ZeroXContext.MultiSelection(itemUI.Value)
        local kept = {}

        for label in pairs(previous) do
            if lookup[label] then
                kept[label] = true
            end
        end

        local wasRestoring = restoring
        restoring = true

        itemUI:SetValues(values)
        itemUI:SetValue(kept)

        restoring = wasRestoring
        state.values = values
        save()

        return {
            account = account,
            packets = packets,
            recipes = lookup,
            drops = drops,
            modes = modes,
            materialNames = materialNames,
        }
    end

    local function readAccount()
        local account = runtime.account.getLocalPlayerAccount()
        if not account then return nil end

        local data = account:toTable()

        if type(data) ~= "table"
            or type(data.material) ~= "table"
            or type(data.accessory) ~= "table" then
            return nil
        end

        return data
    end

    local function findMap(modeId, mapId)
        local modes = runtime.modes.Gamemode
        assert(type(modes) == "table", "Gamemode config unavailable")

        for _, mode in pairs(modes) do
            if type(mode) == "table" and mode.Id == modeId then
                assert(type(mode.Maps) == "table", "Mode maps unavailable")

                for _, map in pairs(mode.Maps) do
                    if type(map) == "table" and map.Id == mapId then
                        return mode, map
                    end
                end
            end
        end

        error("Queue target unavailable: " .. modeId .. "/" .. mapId)
    end

    local function materialRoute(data, missing)
        local _, map = findMap("Story", "Hxh")
        assert(type(map.Chapters) == "table", "Story chapters unavailable")

        local progress = data.achievements
            and data.achievements.progress

        assert(type(progress) == "table", "Story unlock progress unavailable")

        local cleared = tonumber(progress["story.hxh.cleared"] or 0)
        assert(cleared and cleared >= 0, "Invalid Story progress")

        local tables = runtime.drops.Tables
        local hxh = type(tables) == "table" and tables.hxh

        assert(type(hxh) == "table", "HxH material drops unavailable")

        local best, reachable, highest = nil, {}, nil

        for _, chapter in ipairs(map.Chapters) do
            assert(type(chapter) == "number", "Invalid Story chapter")

            local unlocked = chapter <= cleared + 1

            if unlocked and (not highest or chapter > highest) then
                highest = chapter
            end

            local entries = hxh[chapter]

            assert(
                type(entries) == "table",
                "Chapter drop table unavailable"
            )

            local coverage, score, seen = 0, 0, {}

            for _, drop in ipairs(entries) do
                assert(type(drop) == "table", "Invalid drop entry")

                local id = tostring(drop.Item)
                local chance = drop.Chance

                if type(chance) == "table" then
                    chance = chance.Nightmare
                end

                if missing[id]
                    and not seen[id]
                    and type(chance) == "number"
                    and chance > 0 then

                    reachable[id], seen[id] = true, true
                    coverage += 1
                    score += chance
                end
            end

            if unlocked
                and coverage > 0
                and (
                    not best
                    or coverage > best.coverage
                    or (
                        coverage == best.coverage
                        and score > best.score
                    )
                    or (
                        coverage == best.coverage
                        and score == best.score
                        and chapter < best.Chapter
                    )
                ) then

                best = {
                    Mode = "Story",
                    Map = map.Id,
                    Chapter = chapter,
                    Difficulty = 4,
                    coverage = coverage,
                    score = score,
                }
            end
        end

        for id in pairs(missing) do
            assert(
                reachable[id],
                "No verified HxH source for Material " .. id
            )
        end

        if best then return best end

        assert(highest, "No unlocked Story chapter")

        -- เคลียร์บทที่เปิดอยู่ เพื่อปลดล็อกแหล่งวัสดุบทถัดไป
        return {
            Mode = "Story",
            Map = map.Id,
            Chapter = highest,
            Difficulty = 4,
        }
    end

    local matchAccountNamespace

    local function craftNeeds(recipe, data)
        assert(
            type(data.material) == "table",
            "Material data unavailable"
        )

        local missing = {}
        local lines = { recipe.name }
        local ids = {}

        for id in pairs(recipe.materials) do
            table.insert(ids, id)
        end

        table.sort(ids, function(a, b)
            return tonumber(a) < tonumber(b)
        end)

        local names = runtime and runtime.materialNames
            or state.materialNames

        for _, id in ipairs(ids) do
            local name = type(names) == "table" and names[id]

            assert(
                type(name) == "string" and name ~= "",
                "Material name unavailable: " .. id
            )

            local have = tonumber(data.material[id]) or 0
            local need = recipe.materials[id]

            table.insert(
                lines,
                name .. ": " .. have .. "/" .. need
            )

            if have < need then
                missing[id] = need - have
            end
        end

        if not next(missing) then
            table.insert(
                lines,
                "วัสดุครบ | ยังขาดเงิน: 0 (สูตรที่ตรวจสอบไม่ใช้ Money)"
            )
        end

        return missing, lines
    end

    ZeroXContext.CraftEndAction = function()
        if not alive
            or not craftUI.Value
            or not farmUI.Value then
            return nil
        end

        -- รองรับแผนจากเวอร์ชันเก่า หรือการเปลี่ยนเป้าหมายในด่าน
        if type(state.recipe) ~= "table"
            or type(state.sources) ~= "table"
            or ZeroXContext.MultiSelection(itemUI.Value)[state.craftTarget]
                ~= true then

            show("กลับ Lobby เพื่อเตรียมแผน Material ใหม่")
            return "Leave"
        end

        if not matchAccountNamespace then
            matchAccountNamespace = module({
                "global", "stores", "accountNamespace",
            })
        end

        local account = matchAccountNamespace.getLocalPlayerAccount()

        if not account then
            return nil
        end

        local data = account:toTable()

        if type(data) ~= "table"
            or type(data.material) ~= "table"
            or type(data.accessory) ~= "table" then

            show("รอข้อมูล Material ก่อนเลือก Retry / Leave")
            return nil
        end

        local missing, lines = craftNeeds(state.recipe, data)
        local mission = state.mission

        local source = type(mission) == "table"
            and mission.Mode == "Story"
            and mission.Map == "Hxh"
            and state.sources[tostring(mission.Chapter)]

        local action = "Leave"

        if (tonumber(data.accessory[state.recipe.id]) or 0) <= 0
            and type(source) == "table" then

            for id in pairs(missing) do
                if source[id] == true then
                    action = "Retry"
                    break
                end
            end
        end

        table.insert(lines, "จบด่าน: " .. action)
        show(table.concat(lines, "\n"))

        return action
    end

    local function launch(route, recipe, targetLabel)
        if LocalPlayer:GetAttribute("QueueRoom") ~= nil
            or LocalPlayer:GetAttribute("MatchSearching") then

            show("รอคิวปัจจุบันจบก่อนเปลี่ยนเป้าหมาย")
            return
        end

        if ZeroXContext.LobbyOwner ~= nil then
            return
        end

        local hxh = runtime.drops.Tables
            and runtime.drops.Tables.hxh

        assert(
            type(hxh) == "table",
            "HxH drop sources unavailable"
        )

        local sources = {}

        for chapter, entries in pairs(hxh) do
            assert(
                type(entries) == "table",
                "Invalid chapter drop table"
            )

            local ids = {}

            for _, drop in ipairs(entries) do
                local chance = drop.Chance

                if type(chance) == "table" then
                    chance = chance.Nightmare
                end

                if type(chance) == "number" and chance > 0 then
                    ids[tostring(drop.Item)] = true
                end
            end

            sources[tostring(chapter)] = ids
        end

        state.recipe = recipe
        state.craftTarget = targetLabel
        state.sources = sources
        state.materialNames = runtime.materialNames
        state.mission = route
        state.money = nil

        save()

        ZeroXContext.CraftRoute = route

        borrow("ZeroXAutoDeliveryQuest", false)
        borrow("ZeroXLobbyAutoJoin", true)

        launched = true

        show(
            (lastText or "")
                .. "\nฟาร์ม: " .. route.Mode .. "/" .. route.Map
                .. " Chapter " .. route.Chapter
        )
    end

    local function tickCraft()
        if not craftUI.Value then
            restore()
            state.mission = nil
            save()
            show(lastError or "ปิด Auto Craft")
            return
        end

        lastError = nil

        if farmUI.Value then
            borrow("ZeroXAutoDeliveryQuest", false)
        else
            restore()
            state.mission = nil
            save()
        end

        if ZeroXContext.IsMatch() then
            if farmUI.Value and state.mission then
                borrow("ZeroXAutoFarm", true)
                borrow("ZeroXAutoStartVote", true)
                borrow("ZeroXAutoEndGame", true)

                ZeroXContext.CraftEndAction()
            else
                show("รอ Lobby เพื่อคราฟ/วางแผน")
            end

            return
        end

        if not ZeroXContext.IsLobby() then return end

        if launched then
            assert(
                Options.ZeroXLobbyAutoJoin.Value == true,
                "Auto Join stopped; check Lobby log"
            )
            return
        end

        if not runtime then runtime = setup() end

        local data = readAccount()

        if not data then
            show("รอข้อมูลบัญชี")
            return
        end

        local selectedItems =
            ZeroXContext.MultiSelection(itemUI.Value)

        if not next(selectedItems) then
            show("เลือก Accessory ก่อนเปิดใช้งาน")
            return
        end

        local recipe, targetLabel

        for _, label in ipairs(itemUI.Values) do
            if selectedItems[label] then
                local candidate = assert(
                    runtime.recipes[label],
                    "Recipe unavailable: " .. label
                )

                if (tonumber(data.accessory[candidate.id]) or 0)
                    <= 0 then

                    recipe = candidate
                    targetLabel = label
                    break
                end
            end
        end

        if not recipe then
            halt("มี Accessory ครบทุกรายการที่เลือกแล้ว")
            return
        end

        local missing, lines = craftNeeds(recipe, data)

        show(table.concat(lines, "\n"))

        if next(missing) then
            if farmUI.Value then
                launch(
                    materialRoute(data, missing),
                    recipe,
                    targetLabel
                )
            end
            return
        end

        if ZeroXContext.LobbyOwner ~= nil
            or LocalPlayer:GetAttribute("QueueRoom") ~= nil
            or LocalPlayer:GetAttribute("MatchSearching") then
            return
        end

        ZeroXContext.LobbyOwner = "Crafting"

        local before = tonumber(data.accessory[recipe.id]) or 0

        -- ส่งครั้งเดียว และยืนยันจากจำนวน Accessory ที่เพิ่ม
        runtime.packets.craftAccessory:fire(recipe.key)

        local deadline = os.clock() + 8

        while alive and os.clock() < deadline do
            local updated = readAccount()

            if updated
                and (tonumber(updated.accessory[recipe.id]) or 0)
                    > before then

                restore()

                state.recipe = nil
                state.craftTarget = nil
                state.mission = nil

                save()
                show(
                    "คราฟ " .. recipe.name
                        .. " สำเร็จ — ตรวจรายการถัดไป"
                )
                return
            end

            task.wait(0.2)
        end

        if alive then
            error("Craft not confirmed; stopped")
        end
    end

    -- เตรียมรายการใน Lobby ก่อนโหลด Profile
    if ZeroXContext.IsLobby() then
        local ok, result = pcall(setup)

        if ok then
            runtime = result
        else
            warn("[Zero X / Crafting]", result)
        end
    end

    ZeroXContext.StartCrafting = function()
        local old = TS:GetTeleportSetting(KEY)

        if type(old) == "string" then
            local loaded = Http:JSONDecode(old)

            assert(
                type(loaded) == "table"
                    and loaded.version == 1
                    and type(loaded.backups) == "table",
                "Invalid Crafting checkpoint"
            )

            state = loaded

            if state.enabled == true then
                restoring = true

                itemUI:SetValues(
                    type(state.values) == "table" and state.values or {}
                )

                itemUI:SetValue(state.target)
                farmUI:SetValue(state.farm == true)
                craftUI:SetValue(true)

                restoring = false
            end
        end

        ready = true
        save()

        task.spawn(function()
            while alive do
                local ok, err = pcall(tickCraft)

                if ZeroXContext.LobbyOwner == "Crafting" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok then
                    local stopped, stopError = pcall(halt, tostring(err))

                    if not stopped then
                        alive = false

                        warn(
                            "[Zero X / Crafting]",
                            err,
                            stopError
                        )
                    end
                end

                task.wait(1)
            end
        end)
    end

    MacUI:OnUnload(function()
        alive = false
        restore()

        if ZeroXContext.LobbyOwner == "Crafting" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

-- AUTO EVOLVE CHARACTER
-- Standard Ultimate unlock; Sung Jinwoo = Stage I
do
    local RS = game:GetService("ReplicatedStorage")
    local TS = game:GetService("TeleportService")
    local Http = game:GetService("HttpService")

    local KEY = "ZeroX.Evolve.v1." .. LocalPlayer.UserId

    local alive = true
    local started = false
    local restoring = false

    local cache
    local accountNS
    local packets

    local state = {
        backups = {},
    }

    local labels = {}
    local choices = {}
    local selected
    local targets = {}
    local pendingTargets

    local lastJSON
    local lastStatus
    local lastList

    local launched = false
    local requestId = 0

    local section = Tabs.Progress:AddSection({
        Title = "Auto Evolve Character",
    })

    local status = section:AddParagraph({
        Title = "Status",
        Content = "รอข้อมูล Slot",
    })

    local toggle
    local dropdown

    local function show(message)
        if message ~= lastStatus then
            lastStatus = message
            status:SetContent(message)
        end
    end

    local function module(path)
        local node = RS

        for part in path:gmatch("[^.]+") do
            node = node:FindFirstChild(part)

            assert(
                node,
                "Module unavailable: " .. path
            )
        end

        assert(
            node:IsA("ModuleScript"),
            "Not ModuleScript: " .. path
        )

        return require(node)
    end

    local function save()
        if not started or restoring then
            return
        end

        state.enabled = toggle.Value == true
        state.target = selected
        state.targets = targets
        state.pendingTargets = pendingTargets

        local encoded = Http:JSONEncode(state)

        if encoded ~= lastJSON then
            TS:SetTeleportSetting(KEY, encoded)
            lastJSON = encoded
        end
    end

    local function borrow(key, value)
        local option = assert(
            Options[key],
            "Option unavailable: " .. key
        )

        local place = tostring(game.PlaceId)

        state.backups[place] =
            state.backups[place] or {}

        if state.backups[place][key] == nil then
            state.backups[place][key] = {
                value = option.Value,
            }

            save()
        end

        if option.Value ~= value then
            option:SetValue(value)
        end
    end

    local function restore()
        ZeroXContext.EvolveRoute = nil

        local place = tostring(game.PlaceId)
        local backup = state.backups[place]

        if backup then
            for key, entry in pairs(backup) do
                if Options[key] then
                    Options[key]:SetValue(entry.value)
                end
            end

            state.backups[place] = nil
        end

        launched = false
    end

    local function stop(message)
        toggle:SetValue(false)
        restore()

        state.mission = nil

        save()
        show(message)
    end

    local function complete(message)
        restore()

        selected = nil
        cache = nil
        state.plan = nil
        state.mission = nil

        save()
        show(message)
    end

    dropdown = section:AddDropdown("ZeroXEvolveCharacter", {
        Title = "Character in Slot",
        Values = {},
        Multi = true,
        Default = {},
        AllowNull = true,
        Searchable = true,
        Description = "เลือกหลายตัว; ทำตามลำดับ Slot และข้ามตัวที่ Evo แล้ว",

        Callback = function(value)
            if restoring then return end

            if toggle and toggle.Value then
                stop(
                    "เปลี่ยนรายการ — เปิด Auto Evolve ใหม่เพื่อเริ่ม"
                )
            end

            pendingTargets =
                ZeroXContext.MultiSelection(value)

            targets = {}
            selected = nil
            cache = nil
            state.plan = nil
            state.mission = nil

            save()
        end,
    })

    do
        local originalSetValue = dropdown.SetValue

        function dropdown:SetValue(value)
            originalSetValue(
                self,
                ZeroXContext.MultiSelection(value)
            )
        end
    end

    toggle = section:AddToggle(
        "ZeroXAutoEvolveCharacter",
        {
            Title = "Auto Evolve Character",
            Default = false,

            Callback = function()
                save()
            end,
        }
    )

    local function read()
        accountNS = accountNS
            or module("global.stores.accountNamespace")

        local account =
            accountNS.getLocalPlayerAccount()

        return account and account:toTable()
    end

    local function updateSlots(data)
        if type(data.UnlockedCharacters) ~= "table" then
            return
        end

        local rows = {}

        for key, entry in pairs(data.UnlockedCharacters) do
            local slot = tonumber(
                tostring(key):match("^Slot(%d+)$")
            )

            if slot
                and entry.Unlocked == true
                and type(entry.Character) == "string"
                and entry.Character ~= "" then

                table.insert(rows, {
                    slot = slot,
                    character = entry.Character,
                })
            end
        end

        table.sort(rows, function(a, b)
            return a.slot < b.slot
        end)

        labels = {}
        choices = {}

        for _, row in ipairs(rows) do
            local info = data.CharactersData
                and data.CharactersData[row.character]

            local base =
                "Slot " .. row.slot .. " — " .. row.character

            local label = base .. (
                info and info.IsUltimateUnlocked == true
                and " [Evo]" or ""
            )

            choices[base] = row
            choices[label] = row
            table.insert(labels, label)
        end

        -- แปลงชื่อจาก Dropdown/Profile เป็นตัวตน Slot + Character
        if pendingTargets then
            local resolved = {}

            for label in pairs(pendingTargets) do
                local base = label:gsub(" %[Evo%]$", "")

                local row = assert(
                    choices[label] or choices[base],
                    "Saved Evo selection unavailable: " .. label
                )

                table.insert(resolved, {
                    slot = row.slot,
                    character = row.character,
                })
            end

            table.sort(resolved, function(a, b)
                return a.slot < b.slot
            end)

            targets = resolved
            pendingTargets = nil
            save()
        end

        -- คงตัวเลือกไว้ แม้ชื่อรายการเปลี่ยนเป็น [Evo]
        local current, chosenLabels = {}, {}

        for _, label in ipairs(labels) do
            local row = choices[label]

            for _, target in ipairs(targets) do
                if target.slot == row.slot
                    and target.character == row.character then

                    current[label] = true
                    table.insert(chosenLabels, label)
                    break
                end
            end
        end

        local signature = table.concat(labels, "\n") .. "\0"
            .. table.concat(chosenLabels, "\n")

        if signature ~= lastList then
            restoring = true

            dropdown:SetValues(labels)
            dropdown:SetValue(current)

            restoring = false
            lastList = signature
        end
    end

    local function prepare()
        local config =
            module("assets.config.evolutionConfig")

        local recipe = assert(
            config[selected.character],
            "ตัวละครนี้ไม่มีสูตร Evolve"
        )

        local materials = {}
        local costs = {}
        local names = {}

        assert(
            type(recipe.ultimate) == "string",
            "Invalid evolution recipe"
        )

        for part in recipe.ultimate:gmatch("[^|]+") do
            local id, amount = part:match(
                "^%s*(%d+)%s*,%s*(%d+)%s*$"
            )

            amount = tonumber(amount)

            assert(
                id and amount and amount > 0,
                "Invalid evolution material"
            )

            materials[id] =
                (materials[id] or 0) + amount
        end

        for _, cost in ipairs(
            assert(recipe.currencies, "Missing currencies")
        ) do
            assert(
                (
                    cost.currency == "money"
                    or cost.currency == "gems"
                )
                and type(cost.amount) == "number"
                and cost.amount >= 0,
                "Unsupported evolution currency"
            )

            costs[cost.currency] =
                (costs[cost.currency] or 0) + cost.amount
        end

        local matConfig =
            module("assets.config.materialConfig")

        for id in pairs(materials) do
            local def =
                matConfig[id] or matConfig[tonumber(id)]

            assert(
                def and type(def.Name) == "string",
                "Material name unavailable: " .. id
            )

            names[id] = def.Name
        end

        local drops =
            module("assets.config.materialDropConfig").Tables

        local modes =
            module("lobby.enums.gamemodeSelectEnum").Gamemode

        local routes = {}

        -- จับคู่ Drop table กับ Queue map ตามข้อมูลที่ตรวจพบ
        -- สูตร, จำนวน และรายการ Drop อ่านจาก Config จริง
        for _, spec in ipairs({
            { "hxh", "Story", "Hxh" },
            { "spiritedawayraid", "Raid", "BathTub" },
            { "sololevelingraid", "Raid", "ShadowGate" },
        }) do
            local mode = assert(
                modes[spec[2]],
                "Mode unavailable"
            )

            local map

            for _, candidate in pairs(mode.Maps) do
                if candidate.Id == spec[3] then
                    map = candidate
                    break
                end
            end

            assert(
                map,
                "Map unavailable: " .. spec[3]
            )

            for chapter, entries in pairs(
                assert(
                    drops[spec[1]],
                    "Drop table unavailable"
                )
            ) do
                assert(
                    type(chapter) == "number",
                    "Invalid drop chapter"
                )

                if not map.Chapters
                    or table.find(map.Chapters, chapter) then

                    local route = {
                        Mode = spec[2],
                        Map = spec[3],

                        Chapter = map.Chapters
                            and chapter or 0,

                        Difficulty =
                            mode.FixedDifficulty or 4,

                        items = {},
                    }

                    for _, drop in ipairs(entries) do
                        local chance = drop.Chance

                        if type(chance) == "table" then
                            chance = chance.Nightmare
                        end

                        if type(chance) == "number"
                            and chance > 0 then

                            route.items[
                                tostring(drop.Item)
                            ] = true
                        end
                    end

                    table.insert(routes, route)
                end
            end
        end

        cache = {
            materials = materials,
            costs = costs,
            names = names,
            routes = routes,
        }

        state.plan = cache
        save()
    end

    local function needs(data)
        assert(
            type(data.material) == "table"
                and type(data.currencies) == "table",
            "Material/currency data unavailable"
        )

        local missing = {}
        local currencyMissing = false
        local lines = { selected.character }
        local ids = {}

        for id in pairs(cache.materials) do
            table.insert(ids, id)
        end

        table.sort(ids)

        for _, id in ipairs(ids) do
            local have =
                tonumber(data.material[id]) or 0

            local need = cache.materials[id]

            if have < need then
                missing[id] = true
            end

            table.insert(
                lines,
                cache.names[id]
                    .. ": " .. have .. "/" .. need
            )
        end

        for _, key in ipairs({ "money", "gems" }) do
            local need = cache.costs[key] or 0

            local have = assert(
                tonumber(data.currencies[key]),
                "Currency unavailable: " .. key
            )

            currencyMissing =
                currencyMissing or have < need

            table.insert(
                lines,
                key .. ": " .. have .. "/" .. need
                    .. " | ขาด "
                    .. math.max(0, need - have)
            )
        end

        show(table.concat(lines, "\n"))

        return missing, currencyMissing
    end

    local function checkTarget(data)
        local slot = data.UnlockedCharacters
            and data.UnlockedCharacters[
                "Slot" .. selected.slot
            ]

        assert(
            slot
                and slot.Unlocked == true
                and slot.Character == selected.character,
            "ตัวละครใน Slot เปลี่ยน — เลือกใหม่"
        )

        local info = data.CharactersData
            and data.CharactersData[selected.character]

        assert(
            info
                and type(info.IsUltimateUnlocked) == "boolean",
            "Evo state unavailable"
        )

        return info.IsUltimateUnlocked
    end

    local function chooseRoute(data, missing, currencyMissing)
        local best
        local score
        local locked

        local progress = data.achievements
            and data.achievements.progress

        assert(
            type(progress) == "table",
            "Story progress unavailable"
        )

        local open =
            (tonumber(progress["story.hxh.cleared"]) or 0) + 1

        -- ตรวจทุกวัสดุก่อนเริ่มฟาร์ม
        for id in pairs(missing) do
            local found = false

            for _, route in ipairs(cache.routes) do
                if route.items[id] then
                    found = true
                    break
                end
            end

            assert(
                found,
                "No verified source: " .. cache.names[id]
            )
        end

        table.sort(cache.routes, function(a, b)
            if a.Map ~= b.Map then
                return a.Map < b.Map
            end

            return a.Chapter < b.Chapter
        end)

        for _, route in ipairs(cache.routes) do
            local coverage = 0

            for id in pairs(missing) do
                if route.items[id] then
                    coverage += 1
                end
            end

            if route.Mode == "Story"
                and route.Chapter > open then

                if coverage > 0 then
                    locked = true
                end
            elseif coverage > 0
                and (not score or coverage > score) then

                best = route
                score = coverage
            end
        end

        if best then
            return best
        end

        -- ผ่าน Chapter ที่เปิดอยู่เพื่อปลดล็อกแหล่งวัสดุ
        if next(missing) and locked then
            for _, route in ipairs(cache.routes) do
                if route.Mode == "Story"
                    and route.Chapter == open then

                    return route
                end
            end

            error("Cannot unlock required Story chapter")
        end

        if currencyMissing then
            for _, route in ipairs(cache.routes) do
                if route.Map == "ShadowGate" then
                    return route
                end
            end

            error("Shadow Gate route unavailable")
        end
    end

    ZeroXContext.EvolveEndAction = function()
        if not toggle.Value
            or not cache
            or not selected then

            return nil
        end

        local data = read()

        if not data then
            return nil
        end

        if checkTarget(data) then
            return "Leave"
        end

        local missing, currencyMissing = needs(data)
        local mission = state.mission

        if not mission then
            return "Leave"
        end

        for id in pairs(missing) do
            if mission.items[id] then
                return "Retry"
            end
        end

        if mission.Map == "ShadowGate"
            and currencyMissing then

            return "Retry"
        end

        return "Leave"
    end

    local function chooseTarget(data)
        local first
        local active

        for _, target in ipairs(targets) do
            local slot = data.UnlockedCharacters
                and data.UnlockedCharacters[
                    "Slot" .. target.slot
                ]

            assert(
                slot and slot.Unlocked == true
                    and slot.Character == target.character,
                "ตัวละครใน Slot เปลี่ยน — เลือกใหม่"
            )

            local info = data.CharactersData
                and data.CharactersData[target.character]

            assert(
                info
                    and type(info.IsUltimateUnlocked) == "boolean",
                "Evo state unavailable: " .. target.character
            )

            if not info.IsUltimateUnlocked then
                first = first or target

                if selected
                    and selected.slot == target.slot
                    and selected.character == target.character then

                    active = target
                end
            end
        end

        return active or first
    end

    local function tick()
        local data = read()

        if not data then
            show("รอ Account")
            return
        end

        updateSlots(data)

        if not toggle.Value then
            restore()
            save()
            return
        end

        assert(
            not (
                Options.ZeroXAutoCraftAccessory
                and Options.ZeroXAutoCraftAccessory.Value
            ),
            "ปิด Auto Craft Accessory ก่อนใช้ Auto Evolve"
        )

        if ZeroXContext.IsLobby() and not launched then
            local target = chooseTarget(data)

            if not target then
                if #targets > 0 then
                    stop("Evo ครบทุกตัวที่เลือกแล้ว")
                else
                    show("เลือก Character in Slot ก่อน")
                end

                return
            end

            if not selected
                or selected.slot ~= target.slot
                or selected.character ~= target.character then

                selected = {
                    slot = target.slot,
                    character = target.character,
                }

                cache = nil
                state.plan = nil
                state.mission = nil
                save()
            end
        end

        if not selected then
            show("เลือก Character in Slot ก่อน")
            return
        end

        borrow("ZeroXAutoDeliveryQuest", false)

        if ZeroXContext.IsMatch() then
            if not cache then
                show("กลับ Lobby เพื่ออ่านสูตรก่อน")
                return
            end

            borrow("ZeroXAutoFarm", true)
            borrow("ZeroXAutoStartVote", true)
            borrow("ZeroXAutoEndGame", true)

            ZeroXContext.EvolveEndAction()
            return
        end

        if not ZeroXContext.IsLobby() then
            return
        end

        if checkTarget(data) then
            complete(
                selected.character .. " [Evo] — ตรวจตัวถัดไป"
            )
            return
        end

        if launched then
            assert(
                Options.ZeroXLobbyAutoJoin.Value,
                "Auto Join stopped; ตรวจ Lobby log"
            )
            return
        end

        -- อ่าน Config ใน Lobby; ใน Match ใช้แผนที่บันทึกไว้
        if not cache then
            prepare()
        end

        local missing, currencyMissing = needs(data)

        if ZeroXContext.LobbyOwner
            or LocalPlayer:GetAttribute("QueueRoom") ~= nil
            or LocalPlayer:GetAttribute("MatchSearching") then

            return
        end

        local route = chooseRoute(
            data,
            missing,
            currencyMissing
        )

        if route then
            state.mission = route
            save()

            ZeroXContext.EvolveRoute = route

            borrow("ZeroXLobbyAutoJoin", true)
            launched = true

            show(
                lastStatus
                    .. "\nฟาร์ม "
                    .. route.Mode .. "/" .. route.Map
                    .. " Chapter " .. route.Chapter
            )

            return
        end

        local target = selected.character
        local targetSlot = selected.slot

        ZeroXContext.LobbyOwner = "Evolve"

        packets = packets or module("lobby.packets")

        if data.character ~= target then
            requestId = requestId % 65535 + 1

            packets.equipCharacterSlot:fire({
                slot = targetSlot,
                gameSlot = 1,
                requestId = requestId,
            })

            local deadline = os.clock() + 5

            repeat
                task.wait(0.2)

                if not alive or not toggle.Value then
                    return
                end

                data = read()
            until (
                data and data.character == target
            ) or os.clock() >= deadline

            assert(
                data and data.character == target,
                "Equip not confirmed; stopped"
            )
        end

        if not alive
            or not toggle.Value
            or not selected
            or selected.character ~= target
            or selected.slot ~= targetSlot then

            return
        end

        -- Equip มี yield จึงตรวจข้อมูลใหม่ก่อนใช้ทรัพยากร
        data = assert(
            read(),
            "Account unavailable before Evolve"
        )

        if checkTarget(data) then
            complete(target .. " [Evo] — ตรวจตัวถัดไป")
            return
        end

        missing, currencyMissing = needs(data)

        if next(missing) or currencyMissing then
            return
        end

        assert(
            data.character == target,
            "Active character changed"
        )

        show(
            "กำลัง Evolve " .. target
                .. " — รอยืนยัน Account"
        )

        -- ส่งครั้งเดียว ไม่ส่งซ้ำหากผลยังไม่แน่นอน
        packets.evolveCharacter:fire(target)

        local deadline = os.clock() + 8

        repeat
            task.wait(0.2)

            if not alive then
                return
            end

            local fresh = read()

            local info = fresh
                and fresh.CharactersData
                and fresh.CharactersData[target]

            if info and info.IsUltimateUnlocked == true then
                updateSlots(fresh)
                complete(
                    target .. " [Evo] — สำเร็จ; ตรวจตัวถัดไป"
                )
                return
            end
        until os.clock() >= deadline

        error("Evolve not confirmed; หยุดเพื่อไม่ส่งซ้ำ")
    end

    ZeroXContext.StartEvolve = function()
        if started then
            return
        end

        local old = TS:GetTeleportSetting(KEY)

        if type(old) == "string" then
            local loaded = Http:JSONDecode(old)

            assert(
                type(loaded) == "table"
                    and type(loaded.backups) == "table",
                "Invalid Evolve checkpoint"
            )

            state = loaded
            selected = state.target
            targets = type(state.targets) == "table"
                and state.targets
                or (selected and { selected } or {})

            pendingTargets = state.pendingTargets

            restoring = true
            toggle:SetValue(state.enabled == true)
            restoring = false

            if ZeroXContext.IsMatch() then
                cache = state.plan
            end
        end

        started = true
        save()

        task.spawn(function()
            while alive do
                local ok, err = pcall(tick)

                if ZeroXContext.LobbyOwner == "Evolve" then
                    ZeroXContext.LobbyOwner = nil
                end

                if not ok then
                    stop(tostring(err))
                    warn("[Zero X / Evolve]", err)
                end

                task.wait(1)
            end
        end)
    end

    MacUI:OnUnload(function()
        alive = false
        restore()

        if ZeroXContext.LobbyOwner == "Evolve" then
            ZeroXContext.LobbyOwner = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- IN-GAME: Auto Mirror Blessing
--------------------------------------------------------------------------------
do
    local RS = game:GetService("ReplicatedStorage")
    local alive = true
    local ready = false
    local packet
    local retryAt = 0
    local lastSentEnds
    local pending
    local lastError
    local lastText
    local connections = {}

    local function isBlessingMode()
        local mode = workspace:GetAttribute("Mode")

        return ZeroXContext.IsMatch()
            and (
                mode == "fateraid"
                or mode == "floodescape"
            )
    end

    -- ข้อมูลสำรองจากรายงาน สำหรับแสดงตัวเลือกก่อนโหลด Config จริง
    local definitions = {
        Sharp = {
            Name = "Sharper Edge", Rarity = "Common",
        },
        BigHeart = {
            Name = "Big Heart", Rarity = "Common",
        },
        Swift = {
            Name = "Swift Steps", Rarity = "Common",
        },
        ShardSnack = {
            Name = "Shard Snack", Rarity = "Rare",
        },
        ChainShatter = {
            Name = "Chain Shatter", Rarity = "Rare",
        },
        MirrorArmor = {
            Name = "Mirror Armor", Rarity = "Epic",
        },
        SpareHeart = {
            Name = "Spare Heart", Rarity = "Epic",
        },
    }

    local rarityRank = {
        Common = 1,
        Rare = 2,
        Epic = 3,
    }

    local labels = {}
    local labelToId = {}

    local section = Tabs.Card:AddSection({
        Title = "Mirror Blessing",
        Icon = "diamond",
        Description = "เลือก Blessing ตาม Priority 1 → 3; ",
    })

    local toggle = section:AddToggle("ZeroXAutoMirrorBlessing", {
        Title = "Auto Mirror Blessing",
        Description = "เลือกจากการ์ดออโต้",
        Default = false,
    })

    local priority = {}

    local function rebuildChoices()
        labels = { "None" }
        labelToId = {}

        for id, def in pairs(definitions) do
            local label = def.Name .. " [" .. id .. "]"
            table.insert(labels, label)
            labelToId[label] = id
        end

        table.sort(labels, function(a, b)
            if a == "None" then return b ~= "None" end
            if b == "None" then return false end
            return a < b
        end)

        for _, control in ipairs(priority) do
            local previous = control.Value
            control:SetValues(labels)
            control:SetValue(
                labelToId[previous] and previous or "None"
            )
        end
    end

    rebuildChoices()

    for index = 1, 3 do
        priority[index] = section:AddDropdown(
            "ZeroXMirrorPriority" .. index,
            {
                Title = "Priority " .. index,
                Values = labels,
                Default = "None",
                Searchable = true,
            }
        )
    end

    local fallback = section:AddDropdown("ZeroXMirrorFallback", {
        Title = "Fallback",
        Description = "ใช้เมื่อการ์ด Priority ไม่อยู่ในข้อเสนอ",
        Values = {
            "Highest Rarity",
            "First Offered",
        },
        Default = "Highest Rarity",
    })

    local status = section:AddParagraph({
        Title = "Status",
        Content = "ปิด Auto Mirror Blessing",
    })

    local function show(text)
        if text ~= lastText then
            lastText = text
            status:SetContent(text)
        end
    end

    local function find(path)
        local object = RS

        for _, name in ipairs(path) do
            object = object:FindFirstChild(name)
            if not object then return nil end
        end

        return object
    end

    local function setup()
        if ready then return true end
        if os.clock() < retryAt then return false end

        retryAt = os.clock() + 1

        local configModule = find({
            "assets", "config", "FateBlessings",
        })

        local remote = RS:FindFirstChild("FateBlessingPick")

        if not configModule or not remote then
            return false
        end

        assert(
            configModule:IsA("ModuleScript"),
            "FateBlessings is not ModuleScript"
        )

        assert(
            remote:IsA("RemoteEvent"),
            "FateBlessingPick is not RemoteEvent"
        )

        local config = require(configModule)

        assert(
            type(config) == "table"
                and type(config.List) == "table",
            "FateBlessings.List unavailable"
        )

        local actual = {}

        for key, def in pairs(config.List) do
            assert(
                type(def) == "table",
                "Unsupported FateBlessings.List entry"
            )

            local id = type(def.Id) == "string" and def.Id
                or type(key) == "string" and key

            assert(id and id ~= "", "Blessing ID unavailable")

            local previous = definitions[id]

            local name = type(def.Name) == "string" and def.Name
                or previous and previous.Name or id

            local rarity = type(def.Rarity) == "string" and def.Rarity
                or previous and previous.Rarity

            assert(
                not actual[id],
                "Duplicate Blessing ID: " .. id
            )

            actual[id] = {
                Name = name,
                Rarity = rarity,
            }
        end

        assert(next(actual), "Empty FateBlessings.List")

        definitions = actual
        packet = remote

        rebuildChoices()
        ready = true

        return true
    end

    local function parse(raw)
        local result = {}
        local seen = {}

        if type(raw) ~= "string" then
            return result
        end

        for part in raw:gmatch("[^,]+") do
            local id = part:match("^%s*(.-)%s*$")

            if id ~= "" and not seen[id] then
                seen[id] = true
                table.insert(result, id)
            end
        end

        return result
    end

    local function countHistory(id)
        local raw = LocalPlayer:GetAttribute("FateBlessings")

        if raw == nil then return 0 end

        assert(
            type(raw) == "string",
            "Invalid FateBlessings attribute"
        )

        local count = 0

        for part in raw:gmatch("[^,]+") do
            if part:match("^%s*(.-)%s*$") == id then
                count += 1
            end
        end

        return count
    end

    local function cardName(id)
        return definitions[id] and definitions[id].Name or id
    end

    local function choose(offered)
        for _, control in ipairs(priority) do
            local id = labelToId[control.Value]

            if id and table.find(offered, id) then
                return id
            end
        end

        local best = offered[1]

        if fallback.Value == "Highest Rarity" then
            for _, id in ipairs(offered) do
                local rank =
                    rarityRank[(definitions[id] or {}).Rarity] or 0

                local bestRank =
                    rarityRank[(definitions[best] or {}).Rarity] or 0

                if rank > bestRank then
                    best = id
                end
            end
        end

        return best
    end

    local function tick()
        if pending then
            if countHistory(pending.id) > pending.before then
                show("ยืนยันได้รับ: " .. cardName(pending.id))
                pending = nil

            elseif workspace:GetServerTimeNow()
                > pending.endsAt + 5 then

                show("ไม่พบการยืนยันรับ Blessing — ไม่ส่งซ้ำรอบเดิม")
                pending = nil
            end
        end

        if not toggle.Value then
            show(lastError or "ปิด Auto Mirror Blessing")
            return
        end

        if not isBlessingMode() then
            show("รอเข้า Evil Reflection / Tidal High Rise")
            return
        end

        if not setup() then
            show("รอ Config / FateBlessingPick")
            return
        end

        if pending then return end

        local raw = LocalPlayer:GetAttribute("FateOffer")
        local endsAt = LocalPlayer:GetAttribute("FateOfferEnds")

        if type(raw) ~= "string" or raw == "" then
            if not lastText
                or not lastText:find("ยืนยันได้รับ:", 1, true) then

                show("รอ Mirror Blessing รอบถัดไป")
            end

            return
        end

        if type(endsAt) ~= "number" or endsAt ~= endsAt then
            show("รอ FateOfferEnds")
            return
        end

        if workspace:GetServerTimeNow() >= endsAt then
            show("ข้อเสนอหมดเวลา")
            return
        end

        if lastSentEnds == endsAt then
            return
        end

        local offered = parse(raw)
        local id = choose(offered)

        if not id then
            show("ไม่พบตัวเลือกใน FateOffer")
            return
        end

        assert(
            definitions[id],
            "Unknown offered Blessing: " .. id
        )

        -- ตรวจข้อเสนออีกครั้งก่อนส่ง
        if not alive or not toggle.Value
            or not isBlessingMode()
            or LocalPlayer:GetAttribute("FateOffer") ~= raw
            or LocalPlayer:GetAttribute("FateOfferEnds") ~= endsAt
            or workspace:GetServerTimeNow() >= endsAt then

            return
        end

        local before = countHistory(id)

        -- ล็อกก่อน FireServer เพื่อไม่ส่งซ้ำกรณีผลไม่แน่นอน
        lastSentEnds = endsAt

        pending = {
            id = id,
            endsAt = endsAt,
            before = before,
        }

        show("ส่งเลือก: " .. cardName(id) .. " — รอยืนยัน")
        packet:FireServer(id)
    end

    -- Event เป็นหลัก พร้อมตรวจสำรองสำหรับการโหลดและ Timeout
    local dirty = true

    local function changed()
        dirty = true
    end

    for _, name in ipairs({
        "FateOffer",
        "FateOfferEnds",
        "FateBlessings",
    }) do
        table.insert(
            connections,
            LocalPlayer:GetAttributeChangedSignal(name):Connect(changed)
        )
    end

    table.insert(
        connections,
        workspace:GetAttributeChangedSignal("Mode"):Connect(changed)
    )

    toggle:OnChanged(function()
        lastError = nil
        changed()
    end)

    for _, control in ipairs(priority) do
        control:OnChanged(changed)
    end

    fallback:OnChanged(changed)

    MacUI:OnUnload(function()
        alive = false

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        table.clear(connections)
    end)

    task.spawn(function()
        local nextCheck = 0

        while alive do
            if dirty or os.clock() >= nextCheck then
                dirty = false
                nextCheck = os.clock() + 1

                local ok, err = pcall(tick)

                if not ok then
                    toggle:SetValue(false)
                    lastError = tostring(err)
                    show("Mirror Blessing: " .. lastError)
                end
            end

            task.wait(0.15)
        end
    end)
end

-- Keep the original settings folders and custom theme loading.
ThemeManager:SetLibrary(MacUI)
ThemeManager:SetFolder("ZeroX")
ThemeManager:LoadCustomThemes()

InterfaceManager:SetLibrary(MacUI)
InterfaceManager:SetFolder("ZeroX")
InterfaceManager:BuildInterfaceSection(Tabs.Appearance)

-- Profiles: saved separately for each PlaceId, as in the supplied file.
SaveManager:SetLibrary(MacUI)
SaveManager:SetFolder("ZeroX/" .. tostring(game.PlaceId))
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Profiles)

-- Keep this call after all controls are created.
SaveManager:LoadAutoloadConfig()
ZeroXContext.StartCrafting()
ZeroXContext.StartEvolve()

if Options.ZeroXHideOnStart and Options.ZeroXHideOnStart.Value then
    Window:Minimize()
end
