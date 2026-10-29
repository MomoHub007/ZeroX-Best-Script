--[[
    Zero X — reusable UI base
    Based on the supplied MacUI demo (MacUI by Kiwzu).
    Original Dark / Blue appearance retained; demo pages and tasks removed.
    Run in the same client environment as the original HttpGet/loadstring script.
]]

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

--------------------------------------------------------------------------------
-- Window: original theme, accent, layout and sizing retained.
--------------------------------------------------------------------------------

local Window = MacUI:CreateWindow({
	Title = "Zero X",
	SubTitle = "Camera Tower Defends",
	Icon = "command", -- Lucide icon name, rbxassetid:// or a number
	IconColor = "Blue", -- tile colour for that icon (dock, dialogs)
	Size = UDim2.fromOffset(820, 600),
	MinSize = Vector2.new(620, 420),
	TabWidth = 214, -- sidebar width
	Theme = "Dark", -- "Dark" | "Light" | "Midnight" | "Ocean" | "Rose"
	Accent = "Blue", -- accent name, hex string or Color3
	SidebarStyle = "Tile", -- "Tile" | "Tinted" | "Plain"
	Profile = { Title = "ZERO X SCRIPTHUB", Subtitle = "ZERO X SCRIPTHUB" }, -- fixed display name in UI
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
local Tabs = {
    Lobby = Window:AddTab({ Title = "Lobby", Icon = "home" }),
    Match = Window:AddTab({
        Title = "Match",
        Icon = "play",
         Section = "Match",
    }),
    AutoPlay = Window:AddTab({
        Title = "Auto Play",
        Icon = "play",
    }),
    Macro = Window:AddTab({
        Title = "Macro ",
        Icon = "file",
    }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" , Section = "Player" }),
    Appearance = Window:AddTab({ Title = "Settings", Icon = "palette", Section = "Settings" }),
    Profiles = Window:AddTab({ Title = "Profiles", Icon = "folder" }),
}



--------------------------------------------------------------------------------
-- ADD YOUR FEATURES HERE
-- Use Tabs.Home:AddSection(...) or Window:AddTab(...) to add your own controls.
-- Register controls with unique indexes so SaveManager can save their values.
-- Add controls before LoadAutoloadConfig at the bottom of this file.
-- Connect callbacks only after the real game functions are available.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- PLAY: Auto Join & Start Elevator
--------------------------------------------------------------------------------
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local settings = {
        MinimumPlayers = 1,
        Map = "Toilet City",
    }

    local alive = true
    local enabled = false
    local generation = 0
    local busy = false
    local activeVisit
    local toggle

    local Play = Tabs.Lobby:AddSection({
        Title = "Play",
        Icon = "play",
    })

    local function setStatus(_message)
        -- ปิดการแสดงสถานะแล้ว
    end

    local function inside(area, position)
        local point = area.CFrame:PointToObjectSpace(position)
        local half = area.Size * 0.5

        return math.abs(point.X) <= half.X
            and math.abs(point.Y) <= half.Y
            and math.abs(point.Z) <= half.Z
    end

    local function restorePosition()
        local visit = activeVisit
        if not visit or visit.teleporting then
            return
        end

        activeVisit = nil

        if LocalPlayer.Character == visit.character
            and visit.root:IsDescendantOf(visit.character)
            and visit.area:IsDescendantOf(workspace)
            and inside(visit.area, visit.root.Position)
            and not inside(visit.area, visit.origin.Position) then
            visit.root.CFrame = visit.origin
        end
    end

    Play:AddDropdown("ZeroXPlayPlayers", {
        Title = "Players",
        Description = "จำนวนผู้เล่นขั้นต่ำก่อนเริ่ม Start",
        Values = {
            "1 Player", "2 Players", "3 Players",
            "4 Players", "5 Players",
        },
        Default = "1 Player",
        Callback = function(value)
            local count = tonumber(tostring(value):match("^(%d+)"))
            if count and count >= 1 and count <= 5 then
                settings.MinimumPlayers = count
            end
        end,
    })

    Play:AddDropdown("ZeroXPlayMap", {
        Title = "Map",
        Values = {
            "Toilet City",
            "Desert",
            "Cameraman HQ",
        },
        Default = "Toilet City",
        Callback = function(value)
            settings.Map = value
        end,
    })

    local function getRemote(className, name)
        local current = ReplicatedStorage

        for _, childName in ipairs({
            "ModuleLoader", "Shared", "Network", className, name,
        }) do
            current = current and current:FindFirstChild(childName)
        end

        return current and current:IsA(className) and current or nil
    end

    local launch

    launch = function()
        if busy or not alive or not enabled then
            return
        end

        busy = true
        local token = generation

        task.spawn(function()
            local connections = {}

            local function running()
                return alive and enabled and token == generation
            end

            local function waitUntil(predicate, seconds, description)
                local deadline = os.clock() + seconds

                while running() do
                    local value = predicate()
                    if value then
                        return value
                    end

                    if os.clock() >= deadline then
                        error("Timeout: " .. description, 0)
                    end

                    task.wait(0.2)
                end

                return nil
            end

            local ok, reason = pcall(function()
                if game.PlaceId ~= 132929771812494 then
                    error("Auto Join is available in the lobby.", 0)
                end

                -- Prevent the previous progression controller from
                -- issuing competing summon / elevator commands.
                local previous = _G.ZeroXCameramanKaitun
                if type(previous) == "table"
                    and type(previous.Stop) == "function" then
                    previous.Stop()
                end

                setStatus("Waiting for lobby")

                local remotes = waitUntil(function()
                    if not game:IsLoaded() then return nil end

                    local entered = getRemote(
                        "RemoteEvent", "ElevatorEntered"
                    )
                    local teleporting = getRemote(
                        "RemoteEvent", "ElevatorTeleporting"
                    )
                    local start = getRemote(
                        "RemoteFunction", "ElevatorStart"
                    )

                    if entered and teleporting and start then
                        return {
                            entered = entered,
                            teleporting = teleporting,
                            start = start,
                        }
                    end
                end, 90, "lobby remotes")

                if not remotes or not running() then return end

                local targetMap = settings.Map
                local minimum = settings.MinimumPlayers

                setStatus("Finding elevator: " .. targetMap)

                local elevator = waitUntil(function()
                    local folder = workspace:FindFirstChild("Elevators")
                    if not folder then return nil end

                    local best
                    local bestCount = -1

                    for _, model in ipairs(folder:GetChildren()) do
                        local count = model:GetAttribute("Players")
                        local maximum = model:GetAttribute("MaxPlayers")
                        local time = model:GetAttribute("Time")
                        local area = model:FindFirstChild("Area")
                            or model:FindFirstChild("Hitbox")

                        if model:GetAttribute("Map") == targetMap
                            and model:GetAttribute("PlaceId")
                                == 114068177100380
                            and type(count) == "number"
                            and type(maximum) == "number"
                            and count >= 0 and count < maximum
                            and maximum >= minimum
                            and type(time) == "number" and time > 2
                            and area and area:IsA("BasePart")
                            and count > bestCount then
                            best = model
                            bestCount = count
                        end
                    end

                    return best
                end, 60, "available elevator")

                if not elevator or not running() then return end

                local characterState = waitUntil(function()
                    local character = LocalPlayer.Character
                    local root = character
                        and character:FindFirstChild("HumanoidRootPart")

                    if root and root:IsA("BasePart") then
                        return { character = character, root = root }
                    end
                end, 60, "character")

                if not characterState or not running() then return end

                local area = elevator:FindFirstChild("Area")
                    or elevator:FindFirstChild("Hitbox")

                if not area or not area:IsA("BasePart") then
                    error("Elevator area became unavailable.", 0)
                end

                local visit = {
                    character = characterState.character,
                    root = characterState.root,
                    area = area,
                    origin = characterState.root.CFrame,
                    teleporting = false,
                }

                activeVisit = visit
                local joined = false

                table.insert(connections,
                    remotes.entered.OnClientEvent:Connect(function(name)
                        if running() and name == elevator.Name then
                            joined = true
                        end
                    end)
                )

                table.insert(connections,
                    remotes.teleporting.OnClientEvent:Connect(function()
                        if running() and joined then
                            visit.teleporting = true
                        end
                    end)
                )

                local function validateVisit()
                    if LocalPlayer.Character ~= visit.character
                        or not visit.root:IsDescendantOf(visit.character)
                        or not elevator:IsDescendantOf(workspace)
                        or not area:IsDescendantOf(elevator)
                        or not inside(area, visit.root.Position) then
                        error("Character left the elevator area.", 0)
                    end
                end

                setStatus("Entering " .. elevator.Name)
                visit.root.CFrame = area.CFrame

                -- Native client handles entry after physical movement.
                local ready = waitUntil(function()
                    if visit.teleporting then return true end
                    validateVisit()

                    local host = elevator:GetAttribute("Host")
                    local count = elevator:GetAttribute("Players")

                    if host == LocalPlayer.UserId then
                        joined = true
                    end

                    return joined
                        and type(host) == "number" and host > 0
                        and type(count) == "number" and count > 0
                end, 20, "native elevator entry")

                if not ready or not running() then return end

                local startRequested = false

                setStatus("Waiting for players")

                waitUntil(function()
                    if visit.teleporting then return true end
                    validateVisit()

                    local count = elevator:GetAttribute("Players")
                    local host = elevator:GetAttribute("Host")

                    setStatus(string.format(
                        "%s | Players %s/%d",
                        elevator.Name, tostring(count), minimum
                    ))

                    if not startRequested
                        and host == LocalPlayer.UserId
                        and type(count) == "number"
                        and count >= minimum then
                        startRequested = true
                        setStatus("Starting " .. elevator.Name)

                        local accepted =
                            remotes.start:InvokeServer(elevator.Name)

                        if not running() then return true end

                        if accepted == false
                            and not visit.teleporting then
                            error("ElevatorStart was rejected.", 0)
                        end
                    end

                    return visit.teleporting
                end, 60, "elevator teleport acknowledgement")

                if running() and visit.teleporting then
                    setStatus("Teleporting")
                end
            end)

            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end

            -- Release this visit before another worker can start.
            restorePosition()
            busy = false

            if alive and token == generation and not ok then
                enabled = false
                generation += 1
                toggle:SetValue(false)
                setStatus(tostring(reason))
                warn("[Zero X / Play]", reason)
            elseif alive and enabled and token ~= generation then
                launch()
            end
        end)
    end

    toggle = Play:AddToggle("ZeroXAutoJoinStart", {
        Title = "Auto Join & Start",
        Description = "สร้างห้องและกด Start อัตโนมัติ",
        Default = false,
        Callback = function(value)
            if value == true then
                local summon = Options.ZeroXAutoSummon

                if summon and summon.Value then
                    task.defer(function()
                        if alive and toggle then
                            toggle:SetValue(false)
                            setStatus("กรุณาปิดสุ่มอัตโนมัติก่อนเปิดเข้าด่าน")
                        end
                    end)
                    return
                end
            end

            enabled = value == true
            generation += 1

            if enabled then
                launch()
            else
                restorePosition()
                setStatus("Idle")
            end
        end,
    })

    MacUI:OnUnload(function()
        alive = false
        enabled = false
        generation += 1
        restorePosition()
    end)

    Tabs.Lobby:Select()
end

--------------------------------------------------------------------------------
-- LOBBY: Auto Summon · สุ่มตัวละครอัตโนมัติ
--------------------------------------------------------------------------------
do
    local Storage = game:GetService("ReplicatedStorage")

    local alive = true
    local enabled = false
    local generation = 0
    local busy = false
    local selectedAmount = 1
    local pendingRequest
    local toggle

    local section = Tabs.Lobby:AddSection({
        Title = "Auto Summon",
        Description = "สุ่มตัวละครอัตโนมัติ",
        Icon = "star",
    })


    section:AddDropdown("ZeroXSummonAmount", {
        Title = "Amount · จำนวนสุ่มต่อครั้ง",
        Description = "เลือกสุ่มครั้งละ 1 ตัว หรือ 10 ตัว",
        Values = { "x1", "x10" },
        Default = "x1",
        Callback = function(value)
            if value == "x1" then
                selectedAmount = 1
            elseif value == "x10" then
                selectedAmount = 10
            end
        end,
    })

    local function setStatus(_message)
        -- ปิดการแสดงสถานะแล้ว
    end

    local function findPath(root, names)
        for _, name in ipairs(names) do
            root = root and root:FindFirstChild(name)
        end
        return root
    end

    local function finite(value)
        return type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
    end

    local function inventoryCount(towers)
        local count = 0
        for _ in pairs(towers) do
            count += 1
        end
        return count
    end

    local function inside(zone, root)
        local point = zone.CFrame:PointToObjectSpace(root.Position)
        local half = zone.Size * 0.5

        return math.abs(point.X) <= half.X
            and math.abs(point.Y) <= half.Y
            and math.abs(point.Z) <= half.Z
    end

    local launch

    launch = function()
        if busy or not alive or not enabled then return end

        busy = true
        local token = generation

        task.spawn(function()
            local function running()
                return alive and enabled and token == generation
            end

            -- ใช้รอข้อมูลและผลตอบกลับ ไม่ใช่ Summon Delay
            local function waitUntil(check, timeout, description)
                local deadline = os.clock() + timeout

                while running() do
                    local result = check()
                    if result then return result end

                    if os.clock() >= deadline then
                        error("หมดเวลารอ: " .. description, 0)
                    end

                    task.wait(0.1)
                end

                return nil
            end

            local ok, problem = pcall(function()
                if game.PlaceId ~= 132929771812494 then
                    error("ต้องอยู่ในล็อบบี้ก่อนเปิดสุ่ม", 0)
                end

                if pendingRequest and not pendingRequest.done then
                    error("คำขอสุ่มเดิมยังไม่ตอบกลับ ยังส่งคำขอใหม่ไม่ได้", 0)
                end

                local join = Options.ZeroXAutoJoinStart
                if join and join.Value then
                    join:SetValue(false)
                end

                local previous = _G.ZeroXCameramanKaitun
                if type(previous) == "table"
                    and type(previous.Stop) == "function" then
                    previous.Stop()
                end

                setStatus("รอระบบเกมและข้อมูลผู้เล่น")

                local dependencies = waitUntil(function()
                    if not game:IsLoaded() then return nil end

                    local config = findPath(Storage, {
                        "ModuleLoader", "Configs", "Config",
                    })
                    local replication = findPath(Storage, {
                        "ModuleLoader", "Client", "Replication",
                    })
                    local remote = findPath(Storage, {
                        "ModuleLoader", "Shared", "Network",
                        "RemoteFunction", "SummonTowers",
                    })

                    if config and config:IsA("ModuleScript")
                        and replication and replication:IsA("ModuleScript")
                        and remote and remote:IsA("RemoteFunction") then
                        return {
                            config = config,
                            replication = replication,
                            remote = remote,
                        }
                    end
                end, 90, "โมดูลและรีโมทสุ่ม")

                if not dependencies or not running() then return end

                local config = require(dependencies.config)
                if not running() then return end

                local replication = require(dependencies.replication)
                if not running() then return end

                if type(config) ~= "table"
                    or type(config.GameSettings) ~= "table"
                    or type(replication) ~= "table"
                    or type(replication.GetCurrentReplica) ~= "function" then
                    error("โครงสร้างโมดูลไม่ตรงกับข้อมูลที่ตรวจสอบไว้", 0)
                end

                local crates = config.GameSettings.SummonCrates
                local crate

                if type(crates) == "table" then
                    for _, entry in pairs(crates) do
                        if type(entry) == "table"
                            and entry.Name == "Basic Crate" then
                            crate = entry
                            break
                        end
                    end
                end

                if not crate or not finite(crate.SummonPrice)
                    or crate.SummonPrice <= 0 then
                    error("ไม่พบราคาสุ่ม Basic Crate ที่ถูกต้อง", 0)
                end

                local replica = waitUntil(function()
                    local current = replication.GetCurrentReplica()
                    local data = current and current.Data

                    if type(data) == "table"
                        and type(data.Towers) == "table"
                        and finite(data.Money)
                        and finite(data.InventorySpace) then
                        return current
                    end
                end, 90, "ข้อมูลเงินและช่องเก็บตัวละคร")

                if not replica or not running() then return end

                local function readData()
                    local data = replica.Data

                    if type(data) ~= "table"
                        or type(data.Towers) ~= "table"
                        or not finite(data.Money)
                        or not finite(data.InventorySpace) then
                        error("ข้อมูลเงินหรือคลังตัวละครยังไม่พร้อม", 0)
                    end

                    return data
                end

                while running() do
                    local data = readData()
                    local room = math.floor(data.InventorySpace)
                        - inventoryCount(data.Towers)

                    if room < 1 then
                        return "หยุดสุ่ม: ช่องเก็บตัวละครเต็ม"
                    end

                    if data.Money < crate.SummonPrice then
                        return string.format(
                            "เงินไม่พอสุ่มต่อ · เหลือ %s",
                            tostring(data.Money)
                        )
                    end

                    setStatus("เตรียมตัวละครที่จุดสุ่ม")

                    local position = waitUntil(function()
                        local zones = workspace:FindFirstChild("Zones")
                        local zone = zones and zones:FindFirstChild("Summon")
                        local character = LocalPlayer.Character
                        local root = character
                            and character:FindFirstChild("HumanoidRootPart")

                        if zone and zone:IsA("BasePart")
                            and root and root:IsA("BasePart") then
                            return {
                                zone = zone,
                                character = character,
                                root = root,
                            }
                        end
                    end, 60, "ตัวละครและจุดสุ่ม")

                    if not position or not running() then return end

                    local function positionValid()
                        return LocalPlayer.Character == position.character
                            and position.root:IsDescendantOf(position.character)
                            and position.zone:IsDescendantOf(workspace)
                    end

                    if not inside(position.zone, position.root) then
                        position.root.CFrame = position.zone.CFrame
                    end

                    local observations = 0

                    local positioned = waitUntil(function()
                        if not positionValid() then
                            error("ตัวละครหรือจุดสุ่มเปลี่ยนระหว่างเตรียมสุ่ม", 0)
                        end

                        if inside(position.zone, position.root) then
                            observations += 1
                        else
                            observations = 0
                        end

                        return observations >= 2
                    end, 15, "ตัวละครอยู่ภายในจุดสุ่ม")

                    if not positioned or not running() then return end

                    -- อ่านใหม่หลังขั้นตอนที่มีการรอ
                    data = readData()
                    room = math.floor(data.InventorySpace)
                        - inventoryCount(data.Towers)

                    local amount = selectedAmount

                    if amount == 10
                        and (room < 10
                            or data.Money < crate.SummonPrice * 10) then
                        amount = 1
                    end

                    if room < amount
                        or data.Money < crate.SummonPrice * amount then
                        continue
                    end

                    local before = {}
                    for uuid in pairs(data.Towers) do
                        before[uuid] = true
                    end

                    local moneyBefore = data.Money
                    local expectedCost = crate.SummonPrice * amount

                    local request = {
                        done = false,
                        ok = false,
                    }
                    pendingRequest = request

                    setStatus("กำลังสุ่ม x" .. amount)

                    task.spawn(function()
                        if not running() or not positionValid()
                            or not inside(position.zone, position.root) then
                            request.result = "ยกเลิกก่อนส่งคำขอสุ่ม"
                            request.done = true
                            return
                        end

                        request.ok, request.result = pcall(function()
                            return dependencies.remote:InvokeServer(
                                crate.Name, amount
                            )
                        end)

                        request.done = true
                    end)

                    local confirmed = waitUntil(function()
                        if request.done and not request.ok then
                            error(
                                "SummonTowers: " .. tostring(request.result),
                                0
                            )
                        end

                        local current = readData()
                        local added = 0

                        for uuid, record in pairs(current.Towers) do
                            if not before[uuid] then
                                if type(uuid) ~= "string"
                                    or type(record) ~= "table"
                                    or type(record.Name) ~= "string" then
                                    return nil
                                end

                                added += 1
                            end
                        end

                        if added > amount then
                            error("มีตัวละครเพิ่มเกินจำนวนที่ขอ ยืนยันรอบสุ่มไม่ได้", 0)
                        end

                        return request.done
                            and added == amount
                            and moneyBefore - current.Money >= expectedCost
                    end, 30, "ผลสุ่ม ตัวละครใหม่ และยอดเงินที่หัก")

                    if not confirmed or not running() then return end

                    print(
                        "[Zero X / Auto Summon]",
                        "ยืนยันผล x" .. amount,
                        "เงินเหลือ:", replica.Data.Money
                    )

                    -- ยืนยันสำเร็จแล้ว เริ่มรอบถัดไปทันที
                end
            end)

            busy = false

            if alive and token == generation then
                enabled = false
                generation += 1

                if toggle then
                    toggle:SetValue(false)
                end

                if ok then
                    setStatus(problem or "ปิดอยู่")
                else
                    setStatus(tostring(problem))
                    warn("[Zero X / Auto Summon]", problem)
                end
            elseif alive and enabled then
                launch()
            end
        end)
    end

    toggle = section:AddToggle("ZeroXAutoSummon", {
        Title = "Auto Summon · เปิดสุ่มอัตโนมัติ",
        Description = "สุ่มจนเงินไม่พอหรือคลังเต็ม โดยรอยืนยันผลแต่ละรอบ",
        Default = false,
        Callback = function(value)
            enabled = value == true
            generation += 1

            if enabled then
                launch()
            else
                setStatus("ปิดอยู่")
            end
        end,
    })

    MacUI:OnUnload(function()
        alive = false
        enabled = false
        generation += 1
    end)
end

--------------------------------------------------------------------------------
-- LOBBY: Auto Sell · ขายยูนิตอัตโนมัติ
--------------------------------------------------------------------------------
do
    local Storage = game:GetService("ReplicatedStorage")

    local alive = true
    local enabled = false
    local busy = false
    local generation = 0
    local dirty = true
    local selected = {}
    local pending
    local toggle

    -- เวลาขั้นต่ำตาม RemoteSecurity ที่ตรวจสอบได้
    local SALE_INTERVAL = 0.75
    local CONFIRM_TIMEOUT = 20
    local lastSent = -math.huge

    local section = Tabs.Lobby:AddSection({
        Title = "Auto Sell · ขายยูนิตอัตโนมัติ",
        Description = "ขายยูนิตตามระดับที่เลือก โดยไม่ขายตัวเริ่มต้นและตัวที่ใส่ทีม ",
        Icon = "coins",
    })

    local rarityControl = section:AddDropdown("ZeroXSellRarities", {
        Title = "Select Rarities · เลือกระดับที่ต้องการขาย",
        Description = "เลือกได้หลายระดับ ยูนิตที่ตรงระดับจะถูกขายอัตโนมัติ",
        Values = {
            "Basic", "Uncommon", "Rare", "Epic",
            "Legendary", "Mythic", "Godly", "Exclusive",
        },
        Multi = true,
        Searchable = true,
        Default = {},
        Callback = function(values)
            selected = {}

            if type(values) == "table" then
                for key, value in pairs(values) do
                    -- รองรับทั้งรายการชื่อและตารางชื่อ = true
                    if type(key) == "number"
                        and type(value) == "string" then
                        selected[value] = true
                    elseif type(key) == "string" and value == true then
                        selected[key] = true
                    end
                end
            end

            dirty = true
        end,
    })

    local function setStatus(_message)
        -- ปิดการแสดงสถานะแล้ว
    end

    local function finite(value)
        return type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
    end

    local function findPath(root, names)
        for _, name in ipairs(names) do
            root = root and root:FindFirstChild(name)
        end
        return root
    end

    local launch

    launch = function()
        if busy or not alive or not enabled then return end

        busy = true
        local token = generation
        local connections = {}

        task.spawn(function()
            local function running()
                return alive and enabled and token == generation
            end

            local function waitUntil(check, timeout, description)
                local deadline = os.clock() + timeout

                while running() do
                    local result = check()
                    if result then return result end

                    if os.clock() >= deadline then
                        error("หมดเวลารอ: " .. description, 0)
                    end

                    task.wait(0.1)
                end

                return nil
            end

            local ok, problem = pcall(function()
                if game.PlaceId ~= 132929771812494 then
                    error("ต้องอยู่ในล็อบบี้ก่อนเปิดขายอัตโนมัติ", 0)
                end

                setStatus("รอข้อมูลคลังและระบบขาย")

                local dependencies = waitUntil(function()
                    local config = findPath(Storage, {
                        "ModuleLoader", "Configs", "Config",
                    })
                    local replication = findPath(Storage, {
                        "ModuleLoader", "Client", "Replication",
                    })
                    local sell = findPath(Storage, {
                        "ModuleLoader", "Shared", "Network",
                        "RemoteEvent", "SellPart",
                    })

                    if config and config:IsA("ModuleScript")
                        and replication and replication:IsA("ModuleScript")
                        and sell and sell:IsA("RemoteEvent") then
                        return {
                            config = config,
                            replication = replication,
                            sell = sell,
                        }
                    end
                end, 90, "โมดูลข้อมูลและ SellPart")

                if not dependencies or not running() then return end

                local config = require(dependencies.config)
                if not running() then return end

                local replication = require(dependencies.replication)
                if not running() then return end

                if type(config) ~= "table"
                    or type(config.Towers) ~= "table"
                    or type(config.GameSettings) ~= "table"
                    or type(config.GameSettings.SellValues) ~= "table"
                    or type(config.GameSettings.StarterTower) ~= "string"
                    or type(replication) ~= "table"
                    or type(replication.GetCurrentReplica) ~= "function" then
                    error("โครงสร้างข้อมูลขายไม่ตรงกับผลตรวจสอบ", 0)
                end

                local replica = waitUntil(function()
                    local current = replication.GetCurrentReplica()
                    local data = current and current.Data

                    if type(data) == "table"
                        and type(data.Towers) == "table"
                        and finite(data.Money) then
                        return current
                    end
                end, 90, "ข้อมูลคลังและเงิน")

                if not replica or not running() then return end

                if type(replica.OnChange) ~= "function"
                    or type(replica.OnSet) ~= "function" then
                    error("ไม่พบ API ติดตามการเปลี่ยนข้อมูลคลัง", 0)
                end

                table.insert(connections, replica:OnChange(function(_, path)
                    if type(path) == "table" and path[1] == "Towers" then
                        dirty = true
                    end
                end))

                table.insert(connections, replica:OnSet(
                    { "Money" },
                    function()
                        dirty = true
                    end
                ))

                local function readData()
                    local data = replica.Data

                    if type(data) ~= "table"
                        or type(data.Towers) ~= "table"
                        or not finite(data.Money) then
                        error("ข้อมูลคลังหรือเงินไม่พร้อม", 0)
                    end

                    return data
                end

                local function saleValue(uuid, record)
                    if type(uuid) ~= "string"
                        or type(record) ~= "table"
                        or type(record.Name) ~= "string"
                        or record.Equipped ~= nil
                        or record.Name == config.GameSettings.StarterTower then
                        return nil
                    end

                    -- ตรวจเฉพาะรายการใน Data.Towers
                    local definition = config.Towers[record.Name]
                    if type(definition) ~= "table"
                        or type(definition.Rarity) ~= "string"
                        or not selected[definition.Rarity] then
                        return nil
                    end

                    local price =
                        config.GameSettings.SellValues[definition.Rarity]

                    if finite(price) and price > 0 then
                        return price
                    end

                    return nil
                end

                dirty = true

                while running() do
                    local data = readData()

                    if pending then
                        if pending.replica ~= replica then
                            error("Replica เปลี่ยน ยังยืนยันคำขอขายเดิมไม่ได้", 0)
                        end

                        local removed = data.Towers[pending.uuid] == nil
                        local credited =
                            data.Money >= pending.moneyBefore + pending.price

                        if removed and credited then
                            print(
                                "[Zero X / Auto Sell]",
                                "ขายสำเร็จ:", pending.name,
                                "เงินเพิ่มอย่างน้อย:", pending.price
                            )

                            pending = nil
                            dirty = true
                            setStatus("ขายสำเร็จ กำลังตรวจคลัง")

                        elseif os.clock() - pending.sentAt >= CONFIRM_TIMEOUT then
                            error(
                                "ยังยืนยันการขายไม่ได้: "
                                    .. pending.name
                                    .. " | นำออกจากคลัง="
                                    .. tostring(removed)
                                    .. " | เงินเข้า="
                                    .. tostring(credited)
                                    .. " | หยุดโดยไม่ส่งขายซ้ำ",
                                0
                            )
                        else
                            setStatus("รอยืนยันขาย: " .. pending.name)
                        end

                    elseif Options.ZeroXAutoSummon
                        and Options.ZeroXAutoSummon.Value == true then
                        setStatus("รอให้สุ่มอัตโนมัติหยุดก่อนขาย")

                    elseif next(selected) == nil then
                        setStatus("กรุณาเลือกระดับที่ต้องการขาย")

                    elseif dirty
                        and os.clock() - lastSent >= SALE_INTERVAL then
                        dirty = false

                        local candidate

                        for uuid, record in pairs(data.Towers) do
                            local price = saleValue(uuid, record)

                            if price then
                                candidate = {
                                    uuid = uuid,
                                    name = record.Name,
                                    price = price,
                                }
                                break
                            end
                        end

                        if not candidate then
                            setStatus("รอยูนิตระดับที่เลือกเข้าคลัง")
                        else
                            if not dependencies.sell:IsDescendantOf(Storage) then
                                error("SellPart ถูกนำออกจากเกม", 0)
                            end

                            -- ไม่มีการรอระหว่างตรวจซ้ำกับส่งคำขอ
                            local current = readData()
                            local price = saleValue(
                                candidate.uuid,
                                current.Towers[candidate.uuid]
                            )

                            if price and running() then
                                lastSent = os.clock()

                                pending = {
                                    uuid = candidate.uuid,
                                    name = candidate.name,
                                    price = price,
                                    moneyBefore = current.Money,
                                    sentAt = lastSent,
                                    replica = replica,
                                }

                                setStatus("กำลังขาย: " .. candidate.name)

                                -- ขายทีละตัว ไม่สมมติขีดจำกัด batch ของเซิร์ฟเวอร์
                                dependencies.sell:FireServer({
                                    candidate.uuid,
                                })
                            else
                                dirty = true
                            end
                        end
                    end

                    task.wait(0.1)
                end
            end)

            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            table.clear(connections)

            busy = false

            if alive and token == generation and not ok then
                enabled = false
                generation += 1

                if toggle then
                    toggle:SetValue(false)
                end

                setStatus(tostring(problem))
                warn("[Zero X / Auto Sell]", problem)

            elseif alive and enabled and token ~= generation then
                launch()
            end
        end)
    end

    toggle = section:AddToggle("ZeroXAutoSell", {
        Title = "Auto Sell · เปิดขายยูนิตอัตโนมัติ",
        Description = "ขายระดับที่เลือก โดยเว้นตัวเริ่มต้นและตัวที่ใส่ทีม",
        Default = false,
        Callback = function(value)
            enabled = value == true
            generation += 1
            dirty = true

            if enabled then
                launch()
            else
                setStatus(pending
                    and "ปิดแล้ว มีคำขอขายที่ส่งไปก่อนปิด"
                    or "ปิดอยู่")
            end
        end,
    })

    MacUI:OnUnload(function()
        alive = false
        enabled = false
        generation += 1
    end)
end

--------------------------------------------------------------------------------
-- LOBBY: Crates · ซื้อและเปิดกล่อง
--------------------------------------------------------------------------------
do
    local Storage = game:GetService("ReplicatedStorage")

    local alive = true
    local ready = false
    local busy = false
    local uncertain = false

    local config
    local replica
    local buyRemote
    local openRemote

    local buyName
    local openName
    local buyAmount = 1
    local openAmount = 1

    local offers = {}
    local connections = {}
    local refreshQueued = false

    local lastBuy = -math.huge
    local lastOpen = -math.huge

    local function finite(value)
        return type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
    end

    local function findPath(root, names)
        for _, name in ipairs(names) do
            root = root and root:FindFirstChild(name)
        end
        return root
    end

    local section = Tabs.Lobby:AddSection({
        Title = "Crates · ซื้อและเปิดกล่อง",
        Description = "เลือกกล่องและจำนวน แล้วกดซื้อหรือเปิดหนึ่งครั้งต่อรายการ",
        Icon = "package",
    })

    local buyChoice = section:AddDropdown("ZeroXBuyCrateName", {
        Title = "Buy Crate · เลือกกล่องที่จะซื้อ",
        Description = "รายการจากร้านค้า",
        Values = { "รอข้อมูล" },
        Default = "รอข้อมูล",
        Callback = function(value)
            buyName = value
        end,
    })

    section:AddDropdown("ZeroXBuyCrateAmount", {
        Title = "Buy Amount · จำนวนกล่องที่จะซื้อ",
        Description = "จำนวนที่จะซื้อเมื่อกดปุ่มซื้อหนึ่งครั้ง",
        Values = { "1", "3", "10" },
        Default = "1",
        Callback = function(value)
            local amount = tonumber(value)
            if amount == 1 or amount == 3 or amount == 10 then
                buyAmount = amount
            end
        end,
    })

    local priceLabel = section:AddLabel({
        Title = "Price · ราคาต่อกล่อง",
        Value = "รอข้อมูล",
    })

    local openChoice = section:AddDropdown("ZeroXOpenCrateName", {
        Title = "Open Crate · เลือกกล่องในคลัง",
        Description = "แสดงเฉพาะกล่องที่มีอยู่จริงในคลัง",
        Values = { "รอข้อมูล" },
        Default = "รอข้อมูล",
        Callback = function(value)
            openName = value
        end,
    })

    section:AddDropdown("ZeroXOpenCrateAmount", {
        Title = "Open Amount · จำนวนกล่องที่จะเปิด",
        Description = "เปิดครั้งละ 1 หรือ 10 กล่องจากรายการเดียวกันในคลัง",
        Values = { "1", "10" },
        Default = "1",
        Callback = function(value)
            local amount = tonumber(value)
            if amount == 1 or amount == 10 then
                openAmount = amount
            end
        end,
    })

    local ownedLabel = section:AddLabel({
        Title = "Owned · จำนวนกล่องที่มี",
        Value = "รอข้อมูล",
    })

    local function setStatus(_message)
        -- ปิดการแสดงสถานะแล้ว
    end

    local function readData()
        local data = replica and replica.Data

        if type(data) ~= "table"
            or type(data.Items) ~= "table"
            or type(data.Towers) ~= "table"
            or not finite(data.InventorySpace) then
            error("ข้อมูลคลังกล่องหรือยูนิตไม่พร้อม", 0)
        end

        return data
    end

    local function crateCount(data, name)
        local total = 0

        for _, item in pairs(data.Items) do
            if type(item) == "table"
                and item.Type == "Crate"
                and item.Name == name
                and finite(item.Amount)
                and item.Amount > 0 then
                total += item.Amount
            end
        end

        return total
    end

    local function refreshLabels()
        if not alive or not ready then return end

        local data = readData()
        local offer = offers[buyName]

        if offer then
            priceLabel:SetValue(string.format(
                "%s %s",
                tostring(offer.Price.Amount),
                offer.Price.Type
            ))
        else
            priceLabel:SetValue("ยังไม่ได้เลือกกล่อง")
        end

        ownedLabel:SetValue(
            tostring(crateCount(data, openName)) .. " กล่อง"
        )
    end

    local function refreshInventory()
        if not alive or not ready then return end

        local data = readData()
        local names = {}
        local seen = {}

        for _, item in pairs(data.Items) do
            if type(item) == "table"
                and item.Type == "Crate"
                and type(item.Name) == "string"
                and finite(item.Amount)
                and item.Amount > 0
                and not seen[item.Name] then
                seen[item.Name] = true
                table.insert(names, item.Name)
            end
        end

        table.sort(names)

        if #names == 0 then
            openChoice:SetValues({ "ไม่มีกล่องในคลัง" })
            openChoice:SetValue("ไม่มีกล่องในคลัง")
        else
            openChoice:SetValues(names)

            if not seen[openName] then
                openChoice:SetValue(names[1])
            end
        end

        refreshLabels()
    end

    local function scheduleRefresh()
        if not alive or refreshQueued then return end

        refreshQueued = true

        task.defer(function()
            refreshQueued = false

            if not alive or not ready then return end

            local ok, problem = pcall(refreshInventory)

            if not ok then
                setStatus(tostring(problem))
                warn("[Zero X / Crates]", problem)
            end
        end)
    end

    -- Callback ที่ประกาศไว้ข้างต้นจะถูกเรียกตอนสร้าง Control ได้
    buyChoice:OnChanged(scheduleRefresh)
    openChoice:OnChanged(function()
        if ready then
            local ok, problem = pcall(refreshLabels)
            if not ok then
                setStatus(tostring(problem))
            end
        end
    end)

    local function waitUntil(check, timeout, description)
        local deadline = os.clock() + timeout

        while alive do
            local value = check()
            if value then return value end

            if os.clock() >= deadline then
                error("หมดเวลารอ: " .. description, 0)
            end

            task.wait(0.1)
        end

        return nil
    end

    local function conflictingFeature()
        for _, index in ipairs({
            "ZeroXAutoSummon",
            "ZeroXAutoSell",
            "ZeroXAutoJoinStart",
        }) do
            local control = Options[index]

            if control and control.Value == true then
                return true
            end
        end

        return false
    end

    local function runTransaction(action)
        if not alive then return end

        if not ready then
            setStatus("ระบบกล่องยังโหลดไม่เสร็จ")
            return
        end

        if busy then
            setStatus("กำลังรอผลรายการก่อนหน้า")
            return
        end

        if uncertain then
            setStatus("ผลรายการเดิมยังไม่ชัดเจน กรุณาตรวจคลังก่อนทำต่อ")
            return
        end

        if game.PlaceId ~= 132929771812494 then
            setStatus("ใช้ระบบกล่องได้เฉพาะในล็อบบี้")
            return
        end

        if conflictingFeature() then
            setStatus("ปิดสุ่ม ขาย และเข้าด่านอัตโนมัติก่อนทำรายการ")
            return
        end

        busy = true

        task.spawn(function()
            local sent = false

            local ok, problem = pcall(function()
                action(function()
                    sent = true
                end)
            end)

            busy = false

            if not alive then return end

            if not ok then
                -- ไม่ส่งรายการซ้ำ หากส่งแล้วแต่ยืนยันผลไม่ได้
                if sent then
                    uncertain = true
                end

                setStatus(tostring(problem))
                warn("[Zero X / Crates]", problem)
            else
                scheduleRefresh()
            end
        end)
    end

    section:AddButton({
        Title = "Buy Crates · ซื้อกล่องตามจำนวนที่เลือก",
        Description = "กดหนึ่งครั้งเพื่อซื้อหนึ่งรายการ",
        ButtonText = "ซื้อกล่อง",
        Callback = function()
            runTransaction(function(markSent)
                -- เก็บค่าของรายการนี้ ไม่เปลี่ยนตาม Dropdown ระหว่างรอ
                local name = buyName
                local amount = buyAmount
                local offer = offers[name]

                if not offer then
                    error("กรุณาเลือกกล่องที่ซื้อได้ก่อน", 0)
                end

                local currency = offer.Price.Type
                local cost = offer.Price.Amount * amount

                setStatus("กำลังเตรียมซื้อกล่อง")

                local cooled = waitUntil(function()
                    return os.clock() - lastBuy >= 1
                end, 3, "ช่วงห่างคำขอซื้อ")

                if not cooled or not alive then return end

                if conflictingFeature() then
                    error("มีระบบอัตโนมัติเปิดอยู่ กรุณาปิดก่อนซื้อ", 0)
                end

                local data = readData()
                local balance = data[currency]

                if not finite(balance) then
                    error(
                        "ไม่พบยอดเงิน Data."
                            .. currency
                            .. " ที่ตรงกับ Config จึงยังไม่ส่งซื้อ",
                        0
                    )
                end

                if balance < cost then
                    error(string.format(
                        "เงินไม่พอ ต้องใช้ %s %s แต่มี %s",
                        tostring(cost), currency, tostring(balance)
                    ), 0)
                end

                if not buyRemote:IsDescendantOf(Storage) then
                    error("BuyCrate ไม่พร้อมใช้งาน", 0)
                end

                local countBefore = crateCount(data, name)

                lastBuy = os.clock()
                markSent()

                setStatus("กำลังซื้อ " .. name .. " x" .. amount)
                buyRemote:FireServer(name, amount)

                local confirmed = waitUntil(function()
                    local current = readData()
                    local now = current[currency]

                    return crateCount(current, name)
                            >= countBefore + amount
                        and finite(now)
                        and balance - now >= cost
                end, 20, "กล่องเข้าคลังและยอดเงินที่หัก")

                if confirmed and alive then
                    setStatus("ซื้อสำเร็จ: " .. name .. " x" .. amount)
                end
            end)
        end,
    })

    section:AddButton({
        Title = "Open Crates · เปิดกล่องจากคลัง",
        Description = "ใช้กล่องที่เลือกและรอยืนยันยูนิตที่ได้รับ",
        ButtonText = "เปิดกล่อง",
        Callback = function()
            runTransaction(function(markSent)
                local name = openName
                local amount = openAmount

                setStatus("กำลังเตรียมเปิดกล่อง")

                local cooled = waitUntil(function()
                    return os.clock() - lastOpen >= 0.25
                end, 3, "ช่วงห่างคำขอเปิด")

                if not cooled or not alive then return end

                if conflictingFeature() then
                    error("มีระบบอัตโนมัติเปิดอยู่ กรุณาปิดก่อนเปิดกล่อง", 0)
                end

                local data = readData()
                local uuid
                local stackBefore

                for id, item in pairs(data.Items) do
                    if type(id) == "string"
                        and type(item) == "table"
                        and item.Type == "Crate"
                        and item.Name == name
                        and finite(item.Amount)
                        and item.Amount >= amount then
                        uuid = id
                        stackBefore = item.Amount
                        break
                    end
                end

                if not uuid then
                    error(
                        "ไม่พบรายการกล่องที่มีครบ "
                            .. amount
                            .. " กล่อง หากกระจายหลายรายการให้เลือกเปิด x1",
                        0
                    )
                end

                local before = {}
                local towerCount = 0

                for id in pairs(data.Towers) do
                    before[id] = true
                    towerCount += 1
                end

                if towerCount + amount > data.InventorySpace then
                    error("ช่องเก็บยูนิตไม่พอสำหรับเปิดกล่อง", 0)
                end

                if not openRemote:IsDescendantOf(Storage) then
                    error("OpenCrate ไม่พร้อมใช้งาน", 0)
                end

                local response = { done = false }

                lastOpen = os.clock()
                markSent()
                setStatus("กำลังเปิด " .. name .. " x" .. amount)

                task.spawn(function()
                    response.ok, response.value = pcall(function()
                        return openRemote:InvokeServer(uuid, amount)
                    end)
                    response.done = true
                end)

                local confirmed = waitUntil(function()
                    if response.done and not response.ok then
                        error(
                            "OpenCrate: " .. tostring(response.value),
                            0
                        )
                    end

                    local current = readData()
                    local item = current.Items[uuid]
                    local remaining

                    if item == nil then
                        remaining = 0
                    elseif type(item) == "table"
                        and item.Type == "Crate"
                        and item.Name == name
                        and finite(item.Amount) then
                        remaining = item.Amount
                    else
                        return nil
                    end

                    local added = 0

                    for id, record in pairs(current.Towers) do
                        if not before[id] then
                            if type(id) ~= "string"
                                or type(record) ~= "table"
                                or type(record.Name) ~= "string" then
                                return nil
                            end

                            added += 1
                        end
                    end

                    if added > amount then
                        error("จำนวนยูนิตใหม่เกินคำขอ ยืนยันผลเปิดไม่ได้", 0)
                    end

                    return response.done
                        and stackBefore - remaining == amount
                        and added == amount
                end, 30, "กล่องถูกใช้และยูนิตใหม่เข้าคลัง")

                if confirmed and alive then
                    setStatus("เปิดสำเร็จ: " .. name .. " x" .. amount)
                end
            end)
        end,
    })

    MacUI:OnUnload(function()
        alive = false

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end)

    task.spawn(function()
        local ok, problem = pcall(function()
            local dependencies = waitUntil(function()
                local configModule = findPath(Storage, {
                    "ModuleLoader", "Configs", "Config",
                })
                local replicationModule = findPath(Storage, {
                    "ModuleLoader", "Client", "Replication",
                })
                local buy = findPath(Storage, {
                    "ModuleLoader", "Shared", "Network",
                    "RemoteEvent", "BuyCrate",
                })
                local open = findPath(Storage, {
                    "ModuleLoader", "Shared", "Network",
                    "RemoteFunction", "OpenCrate",
                })

                if configModule and configModule:IsA("ModuleScript")
                    and replicationModule
                    and replicationModule:IsA("ModuleScript")
                    and buy and buy:IsA("RemoteEvent")
                    and open and open:IsA("RemoteFunction") then
                    return {
                        config = configModule,
                        replication = replicationModule,
                        buy = buy,
                        open = open,
                    }
                end
            end, 90, "ระบบกล่อง")

            if not dependencies or not alive then return end

            config = require(dependencies.config)
            if not alive then return end

            local replication = require(dependencies.replication)
            if not alive then return end

            if type(config) ~= "table"
                or type(config.GameSettings) ~= "table"
                or type(config.GameSettings.ShopCrates) ~= "table"
                or type(replication) ~= "table"
                or type(replication.GetCurrentReplica) ~= "function" then
                error("โครงสร้างข้อมูลกล่องไม่ตรงกับผลตรวจสอบ", 0)
            end

            replica = waitUntil(function()
                local current = replication.GetCurrentReplica()
                local data = current and current.Data

                if type(data) == "table"
                    and type(data.Items) == "table"
                    and type(data.Towers) == "table"
                    and finite(data.InventorySpace) then
                    return current
                end
            end, 90, "ข้อมูลคลังกล่อง")

            if not replica or not alive then return end

            if type(replica.OnChange) ~= "function" then
                error("ไม่พบ Replica.OnChange", 0)
            end

            buyRemote = dependencies.buy
            openRemote = dependencies.open

            local names = {}

            for _, offer in pairs(config.GameSettings.ShopCrates) do
                if type(offer) == "table"
                    and type(offer.Name) == "string"
                    and offer.IsRobux == false
                    and type(offer.Price) == "table"
                    and finite(offer.Price.Amount)
                    and offer.Price.Amount > 0
                    and type(offer.Price.Type) == "string"
                    and not offers[offer.Name] then
                    offers[offer.Name] = offer
                    table.insert(names, offer.Name)
                end
            end

            table.sort(names)
            ready = true

            buyChoice:SetValues(
                #names > 0 and names or { "ไม่พบกล่องที่ซื้อได้" }
            )

            if not offers[buyName] then
                buyChoice:SetValue(
                    names[1] or "ไม่พบกล่องที่ซื้อได้"
                )
            end

            table.insert(connections, replica:OnChange(function(_, path)
                if type(path) == "table" and path[1] == "Items" then
                    scheduleRefresh()
                end
            end))

            refreshInventory()
            setStatus("พร้อมซื้อและเปิดกล่อง")
        end)

        if not ok and alive then
            ready = false
            setStatus(tostring(problem))
            warn("[Zero X / Crates]", problem)
        end
    end)
end

--------------------------------------------------------------------------------
-- MATCH: โหวตความยาก ข้ามเวฟ และปรับความเร็ว
--------------------------------------------------------------------------------
do
    local Storage = game:GetService("ReplicatedStorage")

    local alive = true
    local connections = {}
    local cachedRemotes = {}

    local difficulty = "Easy"
    local autoVote = false
    local autoSkip = false
    local autoSpeed = false
    local selectedSpeed = 1

    local blockedWaves = {}
    local validWaveInput = true

    local lastVote
    local lastSkip

    local speedGeneration = 0
    local speedTried = {}
    local speedRequest
    local speedAwaiting

    local voteSection = Tabs.Match:AddSection({
        Title = "Pre-match Vote · โหวตก่อนเริ่มด่าน",
        Description = "เลือกความยากที่ต้องการ แล้วเปิดโหวตอัตโนมัติ ",
        Icon = "check",
    })

    local waveSection = Tabs.Match:AddSection({
        Title = "Wave · ควบคุมเวฟและความเร็ว",
        Description = "ข้ามเวฟอัตโนมัติ",
        Icon = "play",
    })
    
    local voteStatus = "Vote"
    local waveStatus = "Wave"
    local speedStatus = "Speed"

    local function show(_label, _message)
        -- ปิดการแสดงสถานะแล้ว
    end

    local function finite(value)
        return type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
    end

    local function getRemote(className, name)
        local cached = cachedRemotes[name]

        if cached and cached:IsDescendantOf(Storage) then
            return cached
        end

        local current = Storage

        for _, part in ipairs({
            "ModuleLoader", "Shared", "Network", className, name,
        }) do
            current = current and current:FindFirstChild(part)
        end

        if current and current:IsA(className) then
            cachedRemotes[name] = current
            return current
        end

        cachedRemotes[name] = nil
        return nil
    end

    local function finished()
        local message = workspace:GetAttribute("Message")
        return message == "You Won!" or message == "You Lost!"
    end

    local function activeMatch()
        local phase = workspace:GetAttribute("GameState")

        return game.PlaceId == 114068177100380
            and not finished()
            and workspace:GetAttribute("IsVoting") ~= true
            and (phase == "InWave" or phase == "Intermission")
    end

    local function resetSpeed()
        speedGeneration += 1
        speedTried = {}
        speedAwaiting = nil

        -- เก็บคำขอที่ยังไม่ตอบกลับไว้ ป้องกัน InvokeServer ซ้อน
    end

    voteSection:AddDropdown("ZeroXMatchDifficulty", {
        Title = "Difficulty · เลือกระดับความยาก",
        Description = "ระดับที่ต้องการส่งโหวตเมื่อเปิดโหวตอัตโนมัติ",
        Values = { "Easy", "Normal", "Hard", "Insane", "Nightmare" },
        Default = "Easy",
        Callback = function(value)
            if table.find({
                "Easy", "Normal", "Hard", "Insane", "Nightmare",
            }, value) then
                difficulty = value
            end
        end,
    })

    voteSection:AddToggle("ZeroXMatchAutoVote", {
        Title = "Auto Vote Difficulty · โหวตความยากอัตโนมัติ",
        Description = "ส่งระดับที่เลือกในช่วงโหวตก่อนเริ่มด่าน",
        Default = false,
        Callback = function(value)
            autoVote = value == true
        end,
    })

    waveSection:AddToggle("ZeroXMatchAutoSkip", {
        Title = "Auto Skip Waves · ข้ามเวฟอัตโนมัติ",
        Description = "ส่งข้ามเวฟเมื่อเกมอนุญาต โดยเว้นเวฟที่กำหนด",
        Default = false,
        Callback = function(value)
            autoSkip = value == true
        end,
    })

    waveSection:AddInput("ZeroXMatchStopSkipAt", {
        Title = "Stop Auto Skip At · เวฟที่ไม่ให้ข้าม",
        Description = "คั่นเลขด้วยจุลภาค เช่น 1,4,5,13 เว้นว่างเพื่อไม่ยกเว้น",
        Placeholder = "1,4,5,13",
        Default = "",
        Finished = true,
        Callback = function(value)
            local text = tostring(value or "")
            local parsed = {}

            if text:match("^%s*$") then
                blockedWaves = {}
                validWaveInput = true
                return
            end

            -- รับรายการเลขจำนวนเต็มบวก ไม่ข้ามส่วนที่พิมพ์ผิด
            for _, part in ipairs(string.split(text, ",")) do
                local digits = part:match("^%s*(%d+)%s*$")
                local wave = digits and tonumber(digits)

                if not finite(wave) or wave < 1 or wave % 1 ~= 0 then
                    validWaveInput = false
                    show(
                        waveStatus,
                        "รูปแบบเลขเวฟไม่ถูกต้อง กรุณาใช้ เช่น 1,4,13"
                    )
                    return
                end

                parsed[wave] = true
            end

            blockedWaves = parsed
            validWaveInput = true
        end,
    })

    waveSection:AddToggle("ZeroXMatchAutoSpeed", {
        Title = "Auto Speed Scale · ปรับความเร็วอัตโนมัติ",
        Description = "ปรับตามค่าที่เลือก และตรวจความเร็วที่เกมยืนยันจริง",
        Default = false,
        Callback = function(value)
            autoSpeed = value == true
            resetSpeed()
        end,
    })

    waveSection:AddDropdown("ZeroXMatchSpeed", {
        Title = "Speed Scale · เลือกความเร็วเกม",
        Description = "เลือก 1x, 1.5x หรือ 2x หาก 2x ไม่ได้จะลอง 1.5x",
        Values = { "1x", "1.5x", "2x" },
        Default = "1x",
        Callback = function(value)
            local speeds = {
                ["1x"] = 1,
                ["1.5x"] = 1.5,
                ["2x"] = 2,
            }

            if speeds[value] then
                selectedSpeed = speeds[value]
                resetSpeed()
            end
        end,
    })

    local function evaluateVote()
        if not autoVote then
            show(voteStatus, "ปิดอยู่")
            return
        end

        if game.PlaceId ~= 114068177100380 then
            show(voteStatus, "รอเข้าด่าน")
            return
        end

        if workspace:GetAttribute("IsVoting") ~= true then
            lastVote = nil
            show(voteStatus, "รอช่วงโหวต")
            return
        end

        if finished()
            or workspace:GetAttribute("GameState") == "Restarting" then
            return
        end

        if lastVote == difficulty then return end

        local remote = getRemote("RemoteEvent", "ModeVote")

        if not remote then
            show(voteStatus, "รอโหลด ModeVote")
            return
        end

        lastVote = difficulty

        local ok, problem = pcall(function()
            remote:FireServer(difficulty)
        end)

        if ok then
            show(voteStatus, "ส่งโหวตแล้ว: " .. difficulty)
        else
            show(voteStatus, "ส่งโหวตไม่สำเร็จ")
            warn("[Zero X / Match Vote]", problem)
        end
    end

    local function evaluateSkip()
        local canSkip = workspace:GetAttribute("CanSkip")
        local wave = workspace:GetAttribute("Wave")

        if canSkip ~= true then
            lastSkip = nil
        end

        if not autoSkip then
            show(waveStatus, "ปิดอยู่")
            return
        end

        if not validWaveInput then
            show(waveStatus, "กรุณาแก้รูปแบบเลขเวฟก่อนเปิดข้ามเวฟ")
            return
        end

        if not activeMatch() then
            show(waveStatus, "รอด่านเริ่มหรือรอด่านถัดไป")
            return
        end

        if not finite(wave) or wave < 1 or wave % 1 ~= 0 then
            show(waveStatus, "รอข้อมูลเลขเวฟ")
            return
        end

        if blockedWaves[wave] then
            show(waveStatus, "เว้นการข้ามเวฟ " .. wave)
            return
        end

        if workspace:GetAttribute("GameState") ~= "InWave"
            or canSkip ~= true then
            show(waveStatus, "รอเกมอนุญาตให้ข้ามเวฟ")
            return
        end

        if lastSkip == wave then return end

        local remote = getRemote("RemoteEvent", "WaveSkip")

        if not remote then
            show(waveStatus, "รอโหลด WaveSkip")
            return
        end

        lastSkip = wave

        local ok, problem = pcall(function()
            remote:FireServer()
        end)

        if ok then
            show(waveStatus, "ส่งคำขอข้ามเวฟ " .. wave .. " แล้ว")
        else
            show(waveStatus, "ส่งคำขอข้ามเวฟไม่สำเร็จ")
            warn("[Zero X / Match Skip]", problem)
        end
    end

    local function evaluateSpeed()
        -- ประมวลผลคำขอเดิมก่อน แม้ปิดสวิตช์หรือเปลี่ยนรอบแล้ว
        if speedRequest then
            local request = speedRequest

            if not request.done then
                if autoSpeed and os.clock() - request.sentAt >= 10 then
                    show(
                        speedStatus,
                        "รอ ChangeSpeed ตอบกลับ ยังไม่ส่งคำขอซ้อน"
                    )
                end
                return
            end

            speedRequest = nil

            if autoSpeed and request.generation == speedGeneration then
                if request.ok and request.result == false then
                    show(
                        speedStatus,
                        tostring(request.target) .. "x ถูกปฏิเสธ"
                    )
                else
                    -- ไม่ถือว่าค่าส่งกลับเพียงอย่างเดียวยืนยันความเร็ว
                    speedAwaiting = {
                        target = request.target,
                        deadline = os.clock() + 5,
                    }

                    if not request.ok then
                        warn("[Zero X / Match Speed]", request.result)
                    end
                end
            end
        end

        if not autoSpeed then
            show(speedStatus, "ปิดอยู่")
            return
        end

        if not activeMatch() then
            show(speedStatus, "รอเริ่มด่าน")
            return
        end

        local current = workspace:GetAttribute("GameSpeed")

        if not finite(current) then
            show(speedStatus, "รอข้อมูลความเร็ว")
            return
        end

        if speedAwaiting then
            if math.abs(current - speedAwaiting.target) < 0.01 then
                show(speedStatus, "ยืนยันความเร็ว " .. current .. "x")
                speedAwaiting = nil

            elseif os.clock() >= speedAwaiting.deadline then
                show(
                    speedStatus,
                    tostring(speedAwaiting.target)
                        .. "x ยังไม่ยืนยัน กำลังตรวจค่าถัดไป"
                )
                speedAwaiting = nil
            end

            return
        end

        if math.abs(current - selectedSpeed) < 0.01 then
            show(speedStatus, "ความเร็วปัจจุบัน " .. current .. "x")
            return
        end

        local candidates = selectedSpeed == 2
            and { 2, 1.5 }
            or { selectedSpeed }

        local target

        for _, candidate in ipairs(candidates) do
            if math.abs(current - candidate) < 0.01 then
                show(speedStatus, "ใช้ความเร็ว " .. current .. "x")
                return
            end

            if not speedTried[candidate] then
                target = candidate
                break
            end
        end

        if not target then
            show(
                speedStatus,
                "ปรับไม่ได้ คงความเร็วปัจจุบัน " .. current .. "x"
            )
            return
        end

        local remote = getRemote("RemoteFunction", "ChangeSpeed")

        if not remote then
            show(speedStatus, "รอโหลด ChangeSpeed")
            return
        end

        speedTried[target] = true

        local request = {
            target = target,
            generation = speedGeneration,
            sentAt = os.clock(),
            done = false,
        }

        speedRequest = request
        show(speedStatus, "กำลังขอความเร็ว " .. target .. "x")

        task.spawn(function()
            if not alive or not autoSpeed
                or request.generation ~= speedGeneration then
                request.done = true
                return
            end

            request.ok, request.result = pcall(function()
                return remote:InvokeServer(target)
            end)

            request.done = true
        end)
    end

    table.insert(connections,
        workspace:GetAttributeChangedSignal("IsVoting"):Connect(function()
            if workspace:GetAttribute("IsVoting") ~= true then
                lastVote = nil
            end
        end)
    )

    table.insert(connections,
        workspace:GetAttributeChangedSignal("CanSkip"):Connect(function()
            if workspace:GetAttribute("CanSkip") ~= true then
                lastSkip = nil
            end
        end)
    )

    table.insert(connections,
        workspace:GetAttributeChangedSignal("GameState"):Connect(function()
            if workspace:GetAttribute("GameState") == "Restarting" then
                lastVote = nil
                lastSkip = nil
                resetSpeed()
            end
        end)
    )

    ------------------------------------------------------------------------
    -- MATCH END: การทำงานหลังจบด่าน
    ------------------------------------------------------------------------
    local afterMatch = "None"
    local endHandled = false
    local endRequestAt
    local endRequestedAction

    local endSection = Tabs.Match:AddSection({
        Title = "Match End · การทำงานหลังจบด่าน",
        Description = "เลือกให้เล่นซ้ำหรือกลับล็อบบี้หลังชนะหรือแพ้ "
            .. "ระบบจะส่งคำขอครั้งเดียวต่อรอบ "
            .. "เลือกไม่ทำอะไรเพื่อหยุดอยู่หน้าผลการแข่งขัน",
        Icon = "flag",
    })

    endSection:AddDropdown("ZeroXAfterMatch", {
        Title = "After Match · เลือกการทำงานหลังจบด่าน",
        Description = "ทำงานเมื่อเกมแสดงผลชนะหรือแพ้แล้วเท่านั้น",
        Values = {
            "None · ไม่ทำอะไร",
            "Replay · เล่นซ้ำ",
            "Lobby · กลับล็อบบี้",
        },
        Default = "None · ไม่ทำอะไร",
        Callback = function(value)
            local actions = {
                ["None · ไม่ทำอะไร"] = "None",
                ["Replay · เล่นซ้ำ"] = "Replay",
                ["Lobby · กลับล็อบบี้"] = "Lobby",
            }

            if actions[value] then
                afterMatch = actions[value]
            end
        end,
    })

    local endStatus = "End"

    local function evaluateMatchEnd()
        if not alive then return end

        if game.PlaceId ~= 114068177100380 then
            show(endStatus, "รอเข้าด่าน")
            return
        end

        local phase = workspace:GetAttribute("GameState")
        local terminal = finished()

        if phase == "Restarting" then
            endHandled = false
            endRequestAt = nil
            endRequestedAction = nil
            show(endStatus, "กำลังเริ่มรอบใหม่")
            return
        end

        if not terminal then
            -- รีเซ็ตเมื่อเห็นรอบที่กำลังเล่นจริง
            if phase == "Intermission" or phase == "InWave" then
                endHandled = false
                endRequestAt = nil
                endRequestedAction = nil
            end

            show(endStatus, afterMatch == "None"
                and "ยังไม่เลือกการทำงาน"
                or "รอผลชนะหรือแพ้")
            return
        end

        if endHandled then
            if endRequestAt and os.clock() - endRequestAt >= 20 then
                show(
                    endStatus,
                    "ยังไม่เห็นการเปลี่ยนด่านหรือเริ่มใหม่ ไม่ส่งคำขอซ้ำ"
                )
            else
                show(endStatus, endRequestedAction == "Replay"
                    and "ส่งคำขอเล่นซ้ำแล้ว"
                    or "ส่งคำขอกลับล็อบบี้แล้ว")
            end
            return
        end

        if afterMatch == "None" then
            show(endStatus, "จบด่านแล้ว ไม่ทำรายการต่อ")
            return
        end

        local remoteName = afterMatch == "Replay"
            and "PlayAgain"
            or "OnLeave"

        local remote = getRemote("RemoteEvent", remoteName)

        if not remote then
            show(endStatus, "รอโหลด " .. remoteName)
            return
        end

        -- บันทึกก่อนส่ง เพื่อกันคำขอซ้ำจาก worker รอบถัดไป
        endHandled = true
        endRequestedAction = afterMatch
        endRequestAt = os.clock()

        local ok, problem = pcall(function()
            remote:FireServer()
        end)

        if not ok then
            endRequestAt = nil
            show(endStatus, "ส่งคำขอไม่สำเร็จ ไม่ส่งซ้ำอัตโนมัติ")
            warn("[Zero X / Match End]", problem)
        else
            show(endStatus, afterMatch == "Replay"
                and "ส่งคำขอเล่นซ้ำแล้ว"
                or "ส่งคำขอกลับล็อบบี้แล้ว")
        end
    end

    ------------------------------------------------------------------------
    -- AUTO SELL FARM: ขายตัวฟาร์มตามเวฟ
    ------------------------------------------------------------------------
    local farmEnabled = false
    local farmSellWave = 30
    local farmWaveValid = true
    local farmSellDelay = 0.2

    local farmPending
    local farmStopped = false
    local farmLastSent = -math.huge
    local farmRemoveRemote
    local farmRemoveConnection

    local farmSection = Tabs.Match:AddSection({
        Title = "Auto Sell Farm · ขายตัวฟาร์มตามเวฟ",
        Description = "ขายเฉพาะตัวฟาร์มที่วางอยู่และเป็นของเรา "
            .. "ตั้งแต่เวฟที่กำหนดเป็นต้นไป รวมตัวฟาร์มที่วางเพิ่มหลังจากนั้น ",

        Icon = "coins",
    })

    farmSection:AddToggle("ZeroXMatchSellFarms", {
        Title = "Auto Sell All Farm On Wave · ขายตัวฟาร์มอัตโนมัติ",
        Description = "ขายตัวฟาร์มของเราทั้งหมดเมื่อถึงเวฟที่กำหนด",
        Default = false,
        Callback = function(value)
            farmEnabled = value == true
        end,
    })

    farmSection:AddInput("ZeroXMatchSellFarmWave", {
        Title = "Sell At Wave · เวฟที่เริ่มขายตัวฟาร์ม",
        Description = "ใส่เลขจำนวนเต็มตั้งแต่ 1 ขึ้นไป",
        Default = "30",
        Placeholder = "30",
        Finished = true,
        Callback = function(value)
            local digits = tostring(value or ""):match("^%s*(%d+)%s*$")
            local number = digits and tonumber(digits)

            farmWaveValid = finite(number)
                and number >= 1
                and number % 1 == 0

            if farmWaveValid then
                farmSellWave = number
            end
        end,
    })

    farmSection:AddSlider("ZeroXMatchSellFarmDelay", {
        Title = "Sell Delay · ช่วงห่างระหว่างคำขอขาย",
        Description = "รอยืนยันผลด้วยเสมอ จึงอาจขายช้ากว่าค่าที่ตั้ง",
        Min = 0.15,
        Max = 2,
        Default = 0.2,
        Increment = 0.05,
        Rounding = 2,
        Suffix = " s",
        Callback = function(value)
            if finite(value) then
                farmSellDelay = math.max(value, 0.15)
            end
        end,
    })

    local farmStatus = "Farm"

    local function resetFarmSelling()
        farmPending = nil
        farmStopped = false
        farmLastSent = -math.huge
    end

    local function getFarmRuntime()
        local nativeShared = shared

        if type(getrenv) == "function" then
            local ok, environment = pcall(getrenv)

            if not ok then
                return nil, nil, "อ่าน native environment ไม่สำเร็จ"
            end

            if type(environment) == "table"
                and type(environment.shared) == "table" then
                nativeShared = environment.shared
            end
        end

        local modules = type(nativeShared) == "table"
            and nativeShared.Modules
        local config = type(modules) == "table" and modules.Config
        local replicator = type(modules) == "table"
            and modules.GameReplicator

        if type(config) ~= "table"
            or type(config.Towers) ~= "table"
            or type(replicator) ~= "table"
            or type(replicator.Data) ~= "table"
            or type(replicator.Data.Towers) ~= "table" then
            return nil, nil, "รอข้อมูล Config และทาวเวอร์ในด่าน"
        end

        return config, replicator.Data.Towers
    end

    local function isOwnedFarm(record, config)
        if type(record) ~= "table"
            or record.OwnerUserId ~= LocalPlayer.UserId
            or type(record.Name) ~= "string" then
            return false
        end

        local definition = config.Towers[record.Name]
        if type(definition) ~= "table" then return false end

        if type(definition.Tags) == "table"
            and definition.Tags.Farm == true then
            return true
        end

        if type(definition.Upgrades) == "table" then
            for _, tier in ipairs(definition.Upgrades) do
                if type(tier) == "table"
                    and finite(tier.CashPerWave)
                    and tier.CashPerWave > 0 then
                    return true
                end
            end
        end

        return false
    end

    local function bindFarmRemoval(remote)
        if farmRemoveRemote == remote and farmRemoveConnection then
            return
        end

        if farmRemoveConnection then
            farmRemoveConnection:Disconnect()
        end

        farmRemoveRemote = remote
        farmRemoveConnection = remote.OnClientEvent:Connect(function(payload)
            if not alive or not farmPending then return end

            if type(payload) == "table"
                and payload.Id == farmPending.id then
                farmPending.acknowledged = true
            end
        end)
    end

    local function evaluateFarmSelling()
        local macro = _G.ZeroXMacroController

        if type(macro) == "table" and macro.Active and not farmPending then
            show(farmStatus, "พักขายตัวฟาร์มระหว่างใช้มาโคร")
            return
        end

        if game.PlaceId ~= 114068177100380 then
            show(farmStatus, farmEnabled and "รอเข้าด่าน" or "ปิดอยู่")
            return
        end

        if not activeMatch() then
            show(farmStatus, farmEnabled
                and "รอเริ่มด่านหรือรอบถัดไป"
                or "ปิดอยู่")
            return
        end

        if not farmEnabled and not farmPending then
            show(farmStatus, "ปิดอยู่")
            return
        end

        if farmStopped then
            show(farmStatus, "หยุดขายรอบนี้ เพราะยังยืนยันรายการเดิมไม่ได้")
            return
        end

        local config, records, reason = getFarmRuntime()

        if not config then
            show(farmStatus, reason)
            return
        end

        local root = workspace:FindFirstChild("Game")
        local models = root and root:FindFirstChild("Towers")

        if not models then
            show(farmStatus, "รอโหลดทาวเวอร์ในด่าน")
            return
        end

        -- ตรวจผลคำขอที่ส่งแล้ว แม้ปิดสวิตช์ระหว่างรอ
        if farmPending then
            local pending = farmPending

            if pending.acknowledged
                and records[pending.id] == nil
                and models:FindFirstChild(pending.id) == nil then
                farmPending = nil
                show(farmStatus, "ยืนยันนำตัวฟาร์มออกแล้ว: " .. pending.name)

            elseif os.clock() - pending.sentAt >= 12 then
                farmStopped = true

                show(farmStatus, "ยืนยันขายไม่สำเร็จ หยุดโดยไม่ส่งซ้ำ")
                warn(
                    "[Zero X / Farm Sell]",
                    "Confirmation timeout",
                    "Id:", pending.id,
                    "Name:", pending.name,
                    "TowerRemove:", pending.acknowledged == true,
                    "RecordRemoved:", records[pending.id] == nil,
                    "ModelRemoved:", models:FindFirstChild(pending.id) == nil
                )
            else
                show(farmStatus, "รอยืนยันขาย: " .. pending.name)
            end

            return
        end

        if not farmEnabled then
            show(farmStatus, "ปิดอยู่")
            return
        end

        if not farmWaveValid then
            show(farmStatus, "กรุณาใส่เลขเวฟจำนวนเต็มตั้งแต่ 1")
            return
        end

        local wave = workspace:GetAttribute("Wave")

        if not finite(wave) then
            show(farmStatus, "รอข้อมูลเลขเวฟ")
            return
        end

        if wave < farmSellWave then
            show(farmStatus, "รอขายตั้งแต่เวฟ " .. farmSellWave)
            return
        end

        if os.clock() - farmLastSent < farmSellDelay then
            return
        end

        local sellRemote = getRemote("RemoteEvent", "TowerSell")
        local removeRemote = getRemote("RemoteEvent", "TowerRemove")

        if not sellRemote or not removeRemote then
            show(farmStatus, "รอโหลด TowerSell และ TowerRemove")
            return
        end

        -- เชื่อมสัญญาณก่อนส่งขาย
        bindFarmRemoval(removeRemote)

        local candidate

        for id, record in pairs(records) do
            if type(id) == "string"
                and isOwnedFarm(record, config)
                and (not candidate or id < candidate.id) then
                candidate = {
                    id = id,
                    name = record.Name,
                }
            end
        end

        if not candidate then
            show(farmStatus, "ไม่มีตัวฟาร์มของเราที่ต้องขาย")
            return
        end

        -- ตรวจซ้ำก่อนส่ง ไม่มีการ yield ระหว่างตรวจและส่ง
        if not isOwnedFarm(records[candidate.id], config) then
            return
        end

        farmLastSent = os.clock()

        farmPending = {
            id = candidate.id,
            name = candidate.name,
            sentAt = farmLastSent,
            acknowledged = false,
        }

        local ok, problem = pcall(function()
            sellRemote:FireServer({
                Id = candidate.id,
            })
        end)

        if not ok then
            farmStopped = true
            show(farmStatus, "ส่งขายไม่สำเร็จ หยุดโดยไม่ส่งซ้ำ")
            warn("[Zero X / Farm Sell]", problem)
        else
            show(farmStatus, "ส่งขายแล้ว: " .. candidate.name)
        end
    end

    table.insert(connections,
        workspace:GetAttributeChangedSignal("GameState"):Connect(function()
            if workspace:GetAttribute("GameState") == "Restarting" then
                resetFarmSelling()
            end
        end)
    )

    MacUI:OnUnload(function()
        if farmRemoveConnection then
            farmRemoveConnection:Disconnect()
            farmRemoveConnection = nil
        end
    end)

    MacUI:OnUnload(function()
        alive = false
        speedGeneration += 1

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        table.clear(connections)
        table.clear(cachedRemotes)
    end)

    -- Worker เดียว ไม่สร้างลูปใหม่ทุกครั้งที่เปิดสวิตช์
    task.spawn(function()
        while alive do
            evaluateVote()
            evaluateSkip()
            evaluateSpeed()
            evaluateFarmSelling()
            evaluateMatchEnd()

            task.wait(0.25)
        end
    end)
end

--------------------------------------------------------------------------------
-- AUTO PLAY: วางและอัปเกรดยูนิตอัตโนมัติ
--------------------------------------------------------------------------------
do
    local Storage = game:GetService("ReplicatedStorage")

    local alive = true
    local autoPlace = false
    local autoUpgrade = false
    local preferUpgrade = false
    local paused = false
    local pending

    local bindings = {}
    local geometryCache = {}
    local rejectedPositions = {}
    local routeCache

    local placeSection = Tabs.AutoPlay:AddSection({
        Title = "Auto Place · วางยูนิตอัตโนมัติ",
        Icon = "map-pin",
    })

    placeSection:AddToggle("ZeroXAutoPlace", {
        Title = "Auto Place · เปิดวางยูนิตอัตโนมัติ",
        Description = "วางตัวโจมตีที่ใส่ทีมเมื่อมีเงินและพื้นที่เหมาะสม",
        Default = false,
        Callback = function(value)
            autoPlace = value == true
        end,
    })

    local upgradeSection = Tabs.AutoPlay:AddSection({
        Title = "Auto Upgrade · อัปเกรดยูนิตอัตโนมัติ",
        Icon = "arrow-up",
    })

    upgradeSection:AddToggle("ZeroXAutoUpgrade", {
        Title = "Auto Upgrade · เปิดอัปเกรดยูนิตอัตโนมัติ",
        Description = "อัปทีละตัวและรอระดับใหม่ยืนยันก่อนทำรายการถัดไป",
        Default = false,
        Callback = function(value)
            autoUpgrade = value == true
        end,
    })

    local function show(_message)
        -- ปิดการแสดงสถานะแล้ว
    end

    local function finite(value)
        return type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
    end

    local function owned(record)
        return type(record) == "table"
            and record.OwnerUserId == LocalPlayer.UserId
    end

    local function distanceXZ(a, b)
        local x = a.X - b.X
        local z = a.Z - b.Z
        return math.sqrt(x * x + z * z)
    end

    local function attack(tier)
        if type(tier) ~= "table"
            or not finite(tier.Damage) or tier.Damage <= 0
            or not finite(tier.Cooldown) or tier.Cooldown <= 0
            or not finite(tier.Range) or tier.Range <= 0 then
            return nil
        end

        return {
            dps = tier.Damage / tier.Cooldown,
            range = tier.Range,
        }
    end

    local function getModules()
        local nativeShared = shared

        if type(getrenv) == "function" then
            local ok, environment = pcall(getrenv)

            if not ok then
                error("อ่าน native environment ไม่สำเร็จ", 0)
            end

            if type(environment) == "table"
                and type(environment.shared) == "table" then
                nativeShared = environment.shared
            end
        end

        return type(nativeShared) == "table" and nativeShared.Modules
    end

    local function remote(name, callback)
        local current = Storage

        for _, child in ipairs({
            "ModuleLoader", "Shared", "Network", "RemoteEvent", name,
        }) do
            current = current and current:FindFirstChild(child)
        end

        local old = bindings[name]

        if not current or not current:IsA("RemoteEvent") then
            if old then
                old.connection:Disconnect()
                bindings[name] = nil
            end
            return nil
        end

        if not old or old.remote ~= current then
            if old then old.connection:Disconnect() end

            bindings[name] = {
                remote = current,
                connection = current.OnClientEvent:Connect(callback),
            }
        end

        return current
    end

    local function onPlaced(payload)
        if not alive or not pending or pending.kind ~= "Place"
            or type(payload) ~= "table"
            or type(payload.Id) ~= "string"
            or not owned(payload)
            or payload.UnitId ~= pending.unitId
            or payload.Name ~= pending.name
            or typeof(payload.Pos) ~= "Vector3"
            or pending.before[payload.Id] then
            return
        end

        if (payload.Pos - pending.position).Magnitude <= 0.5 then
            pending.acknowledged = payload.Id
        end
    end

    local function onUpgraded(payload)
        if not alive or not pending or pending.kind ~= "Upgrade"
            or type(payload) ~= "table"
            or payload.Id ~= pending.id
            or not finite(payload.Level) then
            return
        end

        if payload.Level >= pending.level then
            pending.acknowledged = true
        end
    end

    local function getRoute(folder, bezier)
        local indexed = {}

        for _, part in ipairs(folder:GetChildren()) do
            local index = tonumber(part.Name)

            if index and index >= 1 and index % 1 == 0
                and part:IsA("BasePart") then
                table.insert(indexed, {
                    index = index,
                    part = part,
                    position = part.Position,
                })
            end
        end

        table.sort(indexed, function(a, b)
            return a.index < b.index
        end)

        if #indexed < 2 then return nil end

        local unchanged = routeCache and #routeCache.inputs == #indexed

        for index, entry in ipairs(indexed) do
            if entry.index ~= index then return nil end

            if unchanged then
                local old = routeCache.inputs[index]
                unchanged = old.part == entry.part
                    and old.position == entry.position
            end
        end

        if unchanged then return routeCache.samples end

        if type(bezier) ~= "table" or type(bezier.new) ~= "function" then
            return nil
        end

        local points = {}
        for _, entry in ipairs(indexed) do
            table.insert(points, entry.position)
        end

        local path = bezier.new(points, 2)
        local samples = {}

        -- จำนวนจุดประเมินเป็นงบคำนวณของสคริปต์
        for index = 0, 47 do
            local cf = path:CalculateUniformCFrame(index / 47)
            if typeof(cf) ~= "CFrame" then return nil end
            table.insert(samples, cf.Position)
        end

        routeCache = {
            inputs = indexed,
            samples = samples,
        }

        return samples
    end

    local function geometry(name, definition)
        local template = definition.Model
        if typeof(template) ~= "Instance"
            or not template:IsA("Model") then
            return nil
        end

        local cached = geometryCache[name]

        if cached and cached.template == template then
            return cached
        end

        local boxCF, boxSize = template:GetBoundingBox()
        local size = definition.HitboxSize

        if typeof(size) ~= "Vector3" then
            size = template:GetExtentsSize()
        end

        if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
            return nil
        end

        cached = {
            template = template,
            size = size,
            offset = math.max(
                template:GetPivot().Position.Y
                    - (boxCF.Position.Y - boxSize.Y / 2),
                0
            ),
        }

        geometryCache[name] = cached
        return cached
    end

    local function upgradeAction(config, records, money)
        local best

        for id, record in pairs(records) do
            if type(id) == "string" and owned(record) then
                local definition = config.Towers[record.Name]
                local tiers = type(definition) == "table"
                    and definition.Upgrades
                local level = record.Level or 1

                if type(tiers) == "table" and finite(level)
                    and level >= 1 and level % 1 == 0 then
                    local nextTier = tiers[level + 1]
                    local price = type(nextTier) == "table"
                        and nextTier.Price

                    if finite(price) and price >= 0 and price <= money
                        and (not best or price < best.price
                            or (price == best.price and id < best.id)) then
                        best = {
                            kind = "Upgrade",
                            id = id,
                            name = record.Name,
                            level = level + 1,
                            price = price,
                        }
                    end
                end
            end
        end

        return best
    end

    local function placementAction(root, models, config, modules, records, money)
        local area = root:FindFirstChild("TowerArea")
        local surface = area and area:FindFirstChild("Part")
        local waypoints = root:FindFirstChild("Waypoints")
        local placed = LocalPlayer:FindFirstChild("PlacedTowers")

        if not surface or not surface:IsA("BasePart")
            or not waypoints
            or not placed or not placed:IsA("IntValue")
            or placed.Value >= 15 then
            return nil
        end

        local samples = getRoute(waypoints, modules.BezierPath)
        if not samples then return nil end

        local defense = {}
        local counts = {}

        for index in ipairs(samples) do defense[index] = 0 end

        for id, record in pairs(records) do
            if owned(record) then
                counts[record.Name] = (counts[record.Name] or 0) + 1

                local definition = config.Towers[record.Name]
                local tiers = type(definition) == "table"
                    and definition.Upgrades
                local level = record.Level or 1
                local stats = record.Stats

                if type(stats) ~= "table" and type(tiers) == "table"
                    and finite(level) then
                    stats = tiers[level]
                end

                local profile = attack(stats)
                local position = record.Pos

                if typeof(position) ~= "Vector3" then
                    local model = type(id) == "string"
                        and models:FindFirstChild(id)

                    if model and model:IsA("Model") then
                        position = model:GetPivot().Position
                    end
                end

                if profile and typeof(position) == "Vector3" then
                    for index, point in ipairs(samples) do
                        if distanceXZ(position, point) <= profile.range then
                            defense[index] += profile.dps
                        end
                    end
                end
            end
        end

        local proposals = {}
        local seen = {}

        for slot = 1, 5 do
            local name = LocalPlayer:GetAttribute("Slot" .. slot)
            local unitId = LocalPlayer:GetAttribute("Slot" .. slot .. "Id")
            local definition = type(name) == "string" and config.Towers[name]
            local tiers = type(definition) == "table" and definition.Upgrades
            local base = type(tiers) == "table" and tiers[1]
            local profile = attack(base)
            local price = type(base) == "table" and base.Price
            local limit = type(definition) == "table"
                and definition.PlacementLimit

            local validLimit = limit == nil
                or (finite(limit) and limit >= 0 and limit % 1 == 0)

            if not seen[name] and type(name) == "string" and name ~= ""
                and type(unitId) == "string" and unitId ~= ""
                and profile and finite(price) and price >= 0
                and price <= money and validLimit
                and (limit == nil or (counts[name] or 0) < limit) then
                seen[name] = true

                local info = geometry(name, definition)

                if info then
                    local offset =
                        math.sqrt(info.size.X ^ 2 + info.size.Z ^ 2) / 2 + 1

                    for index = 2, #samples - 1, 6 do
                        local direction = samples[index + 1]
                            - samples[index - 1]
                        local normal = Vector3.new(
                            -direction.Z, 0, direction.X
                        )

                        if normal.Magnitude > 0 then
                            normal = normal.Unit

                            for _, side in ipairs({ -1, 1 }) do
                                local position = samples[index]
                                    + normal * offset * side

                                local key = name .. ":" .. index .. ":" .. side
                                local rejectedUntil = rejectedPositions[key]
                                local score = 0

                                if not rejectedUntil
                                    or os.clock() >= rejectedUntil then
                                    for sampleIndex, point in ipairs(samples) do
                                        if distanceXZ(position, point)
                                            <= profile.range then
                                            score += profile.dps
                                                / (30 + defense[sampleIndex])
                                        end
                                    end

                                    if score > 0 then
                                        table.insert(proposals, {
                                            kind = "Place",
                                            name = name,
                                            unitId = unitId,
                                            price = price,
                                            info = info,
                                            position = position,
                                            key = key,
                                            score = score / math.max(price, 1),
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        table.sort(proposals, function(a, b)
            if a.score == b.score then return a.key < b.key end
            return a.score > b.score
        end)

        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Include
        ray.FilterDescendantsInstances = { surface }

        local overlap = OverlapParams.new()
        overlap.FilterType = Enum.RaycastFilterType.Include
        overlap.FilterDescendantsInstances = { models }

        -- จำกัดจำนวนตรวจพื้นที่ต่อรอบ
        for index = 1, math.min(#proposals, 8) do
            local action = proposals[index]
            local localPoint = surface.CFrame:PointToObjectSpace(
                action.position
            )

            if math.abs(localPoint.X) <= surface.Size.X / 2
                and math.abs(localPoint.Z) <= surface.Size.Z / 2 then
                local length = surface.Size.Magnitude
                    + action.info.size.Magnitude

                local origin = surface.CFrame:PointToWorldSpace(Vector3.new(
                    localPoint.X,
                    surface.Size.Y / 2 + length,
                    localPoint.Z
                ))

                local hit = workspace:Raycast(
                    origin,
                    -surface.CFrame.UpVector * length * 2,
                    ray
                )

                if hit and hit.Instance == surface then
                    local pivot = CFrame.new(
                        hit.Position + Vector3.new(0, action.info.offset, 0)
                    )

                    if #workspace:GetPartBoundsInBox(
                        pivot, action.info.size, overlap
                    ) == 0 then
                        action.pivot = pivot
                        return action
                    end
                end
            end

            -- พักตำแหน่งที่ใช้ไม่ได้ เพื่อเปิดโอกาสตรวจจุดอื่น
            rejectedPositions[action.key] = os.clock() + 2
        end

        return nil
    end

    local function evaluate()
        local macro = _G.ZeroXMacroController

        if type(macro) == "table" and macro.Active then
            show("พัก Auto Play ระหว่างบันทึกหรือเล่นมาโคร")
            return
        end

        if game.PlaceId ~= 114068177100380 then
            show("รอเข้าด่าน")
            return
        end

        local phase = workspace:GetAttribute("GameState")
        local message = workspace:GetAttribute("Message")

        if phase == "Restarting"
            or message == "You Won!" or message == "You Lost!"
            or workspace:GetAttribute("IsVoting") == true
            or (phase ~= "InWave" and phase ~= "Intermission") then
            show("รอเริ่มด่านหรือรอบถัดไป")
            return
        end

        if paused then
            show("หยุดรอบนี้ เพราะคำขอก่อนหน้ายังยืนยันไม่ได้")
            return
        end

        if not autoPlace and not autoUpgrade and not pending then
            show("ปิดอยู่")
            return
        end

        local modules = getModules()
        local config = type(modules) == "table" and modules.Config
        local replicator = type(modules) == "table"
            and modules.GameReplicator
        local records = type(replicator) == "table"
            and type(replicator.Data) == "table"
            and replicator.Data.Towers

        local root = workspace:FindFirstChild("Game")
        local models = root and root:FindFirstChild("Towers")
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local money = leaderstats and leaderstats:FindFirstChild("Money")

        if type(config) ~= "table" or type(config.Towers) ~= "table"
            or type(records) ~= "table" or not models
            or not money or not money:IsA("IntValue") then
            show("รอข้อมูลทีม ทาวเวอร์ และเงินในด่าน")
            return
        end

        local add = remote("TowerAdd", onPlaced)
        local upgrade = remote("TowerUpgrade", onUpgraded)

        if pending then
            local confirmed = false

            if pending.kind == "Place" and pending.acknowledged then
                local record = records[pending.acknowledged]

                confirmed = owned(record)
                    and record.Name == pending.name
                    and record.UnitId == pending.unitId

            elseif pending.kind == "Upgrade" and pending.acknowledged then
                local record = records[pending.id]

                confirmed = owned(record)
                    and finite(record.Level)
                    and record.Level >= pending.level
            end

            if confirmed then
                show("ยืนยันสำเร็จ: " .. pending.name)
                pending = nil

            elseif os.clock() - pending.sentAt >= 12 then
                paused = true
                show("หมดเวลายืนยัน หยุดโดยไม่ส่งคำขอซ้ำ")
                warn("[Zero X / Auto Play]", "Acknowledgement timeout",
                    pending.kind, pending.name)
            else
                show("รอยืนยัน: " .. pending.name)
            end

            return
        end

        local action

        if autoUpgrade and upgrade
            and (preferUpgrade or not autoPlace) then
            action = upgradeAction(config, records, money.Value)
        end

        if not action and autoPlace and add then
            action = placementAction(
                root, models, config, modules, records, money.Value
            )
        end

        if not action and autoUpgrade and upgrade then
            action = upgradeAction(config, records, money.Value)
        end

        if not action then
            show("รอเงิน ข้อมูล หรือรายการที่ทำได้")
            return
        end

        if action.price > money.Value then return end

        action.sentAt = os.clock()

        if action.kind == "Place" then
            -- ตรวจว่า UUID ยังอยู่ในทีมก่อนส่งวาง
            local equipped = false

            for slot = 1, 5 do
                if LocalPlayer:GetAttribute("Slot" .. slot) == action.name
                    and LocalPlayer:GetAttribute("Slot" .. slot .. "Id")
                        == action.unitId then
                    equipped = true
                    break
                end
            end

            if not equipped then return end

            action.before = {}
            for id in pairs(records) do action.before[id] = true end

            action.position = action.pivot.Position
            pending = action
            preferUpgrade = true

            show("ส่งวาง: " .. action.name)
            add:FireServer({
                Name = action.name,
                UnitId = action.unitId,
                Pos = action.pivot.Position,
                CFrame = action.pivot,
            })
        else
            if not owned(records[action.id]) then return end

            pending = action
            preferUpgrade = false

            show("ส่งอัปเกรด: " .. action.name)
            upgrade:FireServer({
                Id = action.id,
            })
        end
    end

    local restartConnection =
        workspace:GetAttributeChangedSignal("GameState"):Connect(function()
            if workspace:GetAttribute("GameState") == "Restarting" then
                pending = nil
                paused = false
                preferUpgrade = false
                routeCache = nil
                table.clear(rejectedPositions)
            end
        end)

    MacUI:OnUnload(function()
        alive = false
        restartConnection:Disconnect()

        for _, binding in pairs(bindings) do
            binding.connection:Disconnect()
        end

        table.clear(bindings)
        table.clear(geometryCache)
        table.clear(rejectedPositions)
    end)

    task.spawn(function()
        while alive do
            local ok, problem = pcall(evaluate)

            if not ok then
                paused = true
                show("ระบบหยุดเนื่องจากข้อผิดพลาด ดูข้อความใน Console")
                warn("[Zero X / Auto Play]", problem)
            end

            task.wait(0.5)
        end
    end)
end

--------------------------------------------------------------------------------
-- MACRO: บันทึกและเล่นคำสั่งวาง / อัปเกรด
--------------------------------------------------------------------------------
do
    local Storage = game:GetService("ReplicatedStorage")
    local Http = game:GetService("HttpService")

    local previous = _G.ZeroXMacroController
    if type(previous) == "table" and type(previous.Stop) == "function" then
        previous.Stop()
    end

    local controller = { Active = false }
    _G.ZeroXMacroController = controller

    -- ไฟล์ของระบบมาโครนี้เอง ไม่ใช่ Path ภายในเกม
    local FILE_NAME = "ZeroX_Cameraman_Macros_v1.json"

    local alive = true
    local bindings = {}
    local connections = {}
    local macros = {}
    local selected
    local draftName = ""
    local playbackMode = "Hybrid"
    local automatic = false

    local recording
    local playing
    local state = "Idle · พร้อมใช้งาน"
    local attempted = false
    local waveStartedAt = os.clock()

    local recordToggle
    local macroChoice
    local diskUsable = type(readfile) == "function"
        and type(writefile) == "function"
        and type(isfile) == "function"

    local function finite(value)
        return type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
    end

    local function activeMatch()
        local phase = workspace:GetAttribute("GameState")
        local message = workspace:GetAttribute("Message")

        return game.PlaceId == 114068177100380
            and workspace:GetAttribute("IsVoting") ~= true
            and message ~= "You Won!"
            and message ~= "You Lost!"
            and (phase == "InWave" or phase == "Intermission")
    end

    local function runtime()
        local nativeShared = shared

        if type(getrenv) == "function" then
            local ok, environment = pcall(getrenv)
            if not ok then return nil end

            if type(environment) == "table"
                and type(environment.shared) == "table" then
                nativeShared = environment.shared
            end
        end

        local modules = type(nativeShared) == "table"
            and nativeShared.Modules
        local config = type(modules) == "table" and modules.Config
        local replicator = type(modules) == "table"
            and modules.GameReplicator
        local records = type(replicator) == "table"
            and type(replicator.Data) == "table"
            and replicator.Data.Towers

        local stats = LocalPlayer:FindFirstChild("leaderstats")
        local money = stats and stats:FindFirstChild("Money")

        if type(config) == "table" and type(config.Towers) == "table"
            and type(records) == "table"
            and money and money:IsA("IntValue") then
            return {
                config = config,
                records = records,
                money = money,
            }
        end

        return nil
    end

    local function owned(record)
        return type(record) == "table"
            and record.OwnerUserId == LocalPlayer.UserId
    end

    local function hasOwnedTowers(data)
        for _, record in pairs(data.records) do
            if owned(record) then return true end
        end
        return false
    end

    local function conflicting()
        for _, index in ipairs({
            "ZeroXAutoPlace",
            "ZeroXAutoUpgrade",
            "ZeroXMatchSellFarms",
        }) do
            local control = Options[index]
            if control and control.Value == true then
                return true
            end
        end
        return false
    end

    local function save()
        if not diskUsable then return false end

        local ok, problem = pcall(function()
            writefile(FILE_NAME, Http:JSONEncode({
                Version = 1,
                Universe = game.GameId,
                Macros = macros,
            }))
        end)

        if not ok then
            warn("[Zero X / Macro Save]", problem)
        end
        return ok
    end

    if diskUsable then
        local ok, problem = pcall(function()
            if not isfile(FILE_NAME) then return end

            local decoded = Http:JSONDecode(readfile(FILE_NAME))

            if type(decoded) ~= "table"
                or decoded.Version ~= 1
                or decoded.Universe ~= game.GameId
                or type(decoded.Macros) ~= "table" then
                error("รูปแบบไฟล์มาโครไม่ถูกต้อง")
            end

            macros = decoded.Macros
        end)

        if not ok then
            -- เก็บไฟล์เดิมไว้ ไม่เขียนทับไฟล์ที่อ่านไม่ได้
            diskUsable = false
            warn("[Zero X / Macro Load]", problem)
        end
    end

    local function names()
        local result = {}
        for name, macro in pairs(macros) do
            if type(name) == "string" and type(macro) == "table"
                and type(macro.Actions) == "table" then
                table.insert(result, name)
            end
        end
        table.sort(result)
        return result
    end

    local section = Tabs.Macro:AddSection({
        Title = "Macro State · สถานะและจัดการมาโคร",
        Description = "สร้างมาโคร เลือกรายการ แล้วเปิด Record เพื่อบันทึก "
            .. "การวางและอัปเกรดที่เซิร์ฟเวอร์ยืนยัน\n"
            .. "เริ่มบันทึกหรือเล่นขณะไม่มีทาวเวอร์ของเราวางอยู่ "
            .. "การเริ่มบันทึกจะเขียนทับคำสั่งเดิมของรายการที่เลือก "
            .. "และควรใช้แผนที่ ความยาก และทีมเดียวกับตอนบันทึก",
        Icon = "file",
    })

    local stateLabel = section:AddLabel({
        Title = "State · สถานะมาโคร",
        Value = state,
    })

    local liveLabel = section:AddLabel({
        Title = "Live Match · ข้อมูลด่านปัจจุบัน",
        Value = "รอข้อมูล",
    })

    local actionsLabel = section:AddLabel({
        Title = "Recorded Actions · จำนวนคำสั่ง",
        Value = "0",
    })

    section:AddLabel({
        Title = "Storage · การเก็บมาโคร",
        Value = diskUsable
            and "บันทึกเป็นไฟล์บนเครื่อง"
            or "เก็บเฉพาะระหว่างรัน UI ครั้งนี้",
    })

    local function refreshList()
        local values = names()

        macroChoice:SetValues(
            #values > 0 and values or { "(none)" }
        )

        if not selected or not macros[selected] then
            selected = values[1]
        end

        macroChoice:SetValue(selected or "(none)")
    end

    local function finishRecording()
        if not recording then return end

        recording = nil
        controller.Active = false

        local saved = save()
        state = saved
            and "Idle · หยุดบันทึกและบันทึกไฟล์แล้ว"
            or "Idle · หยุดบันทึก เก็บข้อมูลในหน่วยความจำ"
    end

    local function stopWithError(message)
        if recording then
            finishRecording()
        end

        playing = nil
        controller.Active = false
        attempted = true
        state = "Stopped · " .. message

        if recordToggle and recordToggle.Value then
            recordToggle:SetValue(false)
        end

        warn("[Zero X / Macro]", message)
    end

    section:AddInput("ZeroXMacroDraftName", {
        Title = "Create Macro · ตั้งชื่อมาโคร",
        Description = "ชื่อสำหรับสร้างรายการมาโครใหม่",
        Placeholder = "ชื่อมาโคร",
        Finished = true,
        Callback = function(value)
            draftName = tostring(value or ""):match("^%s*(.-)%s*$")
        end,
    })

    section:AddButton({
        Title = "Create New Macro · สร้างมาโครใหม่",
        Description = "สร้างรายการว่าง แล้วเลือกเพื่อเริ่มบันทึก",
        ButtonText = "สร้าง",
        Callback = function()
            if controller.Active then
                state = "หยุดบันทึกหรือเล่นก่อนสร้างรายการ"
                return
            end

            if draftName == "" or #draftName > 120 then
                state = "กรุณาตั้งชื่อมาโคร ความยาวไม่เกิน 120 ไบต์"
                return
            end

            if macros[draftName] then
                state = "มีชื่อมาโครนี้แล้ว"
                return
            end

            macros[draftName] = { Actions = {} }
            selected = draftName
            save()
            refreshList()
            state = "สร้างมาโครแล้ว: " .. selected
        end,
    })

    local initialNames = names()

    macroChoice = section:AddDropdown("ZeroXMacroSelected", {
        Title = "Select Macro · เลือกมาโคร",
        Description = "รายการที่จะบันทึกหรือเล่นซ้ำ",
        Values = #initialNames > 0 and initialNames or { "(none)" },
        Default = initialNames[1] or "(none)",
        Callback = function(value)
            if controller.Active then return end
            selected = macros[value] and value or nil
        end,
    })

    section:AddButton({
        Title = "Delete Selected Macro · ลบมาโครที่เลือก",
        Description = "ลบรายการที่เลือกขณะไม่ได้บันทึกหรือเล่น",
        ButtonText = "ลบ",
        Style = "Destructive",
        Callback = function()
            if controller.Active then
                state = "หยุดบันทึกหรือเล่นก่อนลบรายการ"
                return
            end

            if selected then
                macros[selected] = nil
                selected = nil
                save()
                refreshList()
                state = "ลบมาโครแล้ว"
            end
        end,
    })

    section:AddDropdown("ZeroXMacroPlaybackMode", {
        Title = "Playback Mode · วิธีเล่นมาโคร",
        Description = "Time: ตามเวลา | Hybrid: เวฟและเวลาภายในเวฟ "
            .. "| Money: ทำตามลำดับเมื่อเงินพอ",
        Values = { "Hybrid", "Time", "Money" },
        Default = "Hybrid",
        Callback = function(value)
            if not playing and table.find({
                "Hybrid", "Time", "Money",
            }, value) then
                playbackMode = value
            end
        end,
    })

    local function validateMacro(macro)
        if type(macro) ~= "table" or type(macro.Actions) ~= "table"
            or #macro.Actions == 0
            or type(macro.Map) ~= "string"
            or type(macro.Mode) ~= "string" then
            return false
        end

        local keys = {}
        local lastTime = -1

        for _, action in ipairs(macro.Actions) do
            if type(action) ~= "table"
                or type(action.key) ~= "string"
                or not finite(action.time) or action.time < lastTime
                or not finite(action.wave) or action.wave < 1
                or action.wave % 1 ~= 0
                or not finite(action.waveTime) or action.waveTime < 0 then
                return false
            end

            lastTime = action.time

            if action.kind == "Place" then
                if keys[action.key] or type(action.name) ~= "string"
                    or type(action.cf) ~= "table" or #action.cf ~= 12 then
                    return false
                end

                for _, component in ipairs(action.cf) do
                    if not finite(component) then return false end
                end

                keys[action.key] = true

            elseif action.kind == "Upgrade" then
                if not keys[action.key] or not finite(action.level)
                    or action.level < 2 or action.level % 1 ~= 0 then
                    return false
                end
            else
                return false
            end
        end

        return true
    end

    local function startRecording()
        local data = runtime()
        local macro = selected and macros[selected]
        local map = workspace:GetAttribute("Map")
        local mode = workspace:GetAttribute("Mode")

        if not activeMatch() or not data then
            return false, "รอด่านเริ่มและข้อมูลพร้อมก่อนบันทึก"
        end

        if not macro then return false, "กรุณาสร้างและเลือกมาโคร" end
        if playing then return false, "หยุดเล่นมาโครก่อนบันทึก" end

        if conflicting() then
            return false, "ปิด Auto Place, Auto Upgrade และขายตัวฟาร์มก่อน"
        end

        if hasOwnedTowers(data) then
            return false, "เริ่มบันทึกก่อนวางทาวเวอร์ตัวแรก"
        end

        if type(map) ~= "string" or type(mode) ~= "string" then
            return false, "รอชื่อแผนที่และความยาก"
        end

        macro.Actions = {}
        macro.Map = map
        macro.Mode = mode

        recording = {
            macro = macro,
            startedAt = os.clock(),
            keys = {},
            levels = {},
        }

        controller.Active = true
        attempted = true
        state = "Recording · กำลังบันทึก"
        return true
    end

    recordToggle = section:AddToggle("ZeroXMacroRecord", {
        Title = "Record · บันทึกมาโคร",
        Description = "เริ่มบันทึกใหม่ลงรายการที่เลือก ปิดเพื่อบันทึกผล",
        Default = false,
        Callback = function(value)
            if value then
                if recording then return end

                local ok, reason = startRecording()

                if not ok then
                    state = reason
                    task.defer(function()
                        if alive and recordToggle then
                            recordToggle:SetValue(false)
                        end
                    end)
                end
            else
                finishRecording()
            end
        end,
    })

    section:AddToggle("ZeroXMacroAutoPlayback", {
        Title = "Auto Playback Every Match · เล่นมาโครทุกด่าน",
        Description = "เริ่มเล่นรายการที่เลือกเมื่อด่านพร้อมและยังไม่มีตัวเราวางอยู่ "
            .. "ปิดสวิตช์เพื่อหยุดส่งคำสั่งใหม่",
        Default = false,
        Callback = function(value)
            automatic = value == true

            if not automatic and playing then
                playing = nil
                controller.Active = false
                state = "Idle · หยุดเล่นมาโคร"
            elseif automatic and not recording then
                attempted = false
            end
        end,
    })

    local function getRemote(name)
        local current = Storage

        for _, child in ipairs({
            "ModuleLoader", "Shared", "Network", "RemoteEvent", name,
        }) do
            current = current and current:FindFirstChild(child)
        end

        return current and current:IsA("RemoteEvent") and current or nil
    end

    local function append(action)
        if not recording or not activeMatch() then return end

        local wave = workspace:GetAttribute("Wave")
        if not finite(wave) or wave < 1 then
            stopWithError("ไม่มีข้อมูลเวฟสำหรับบันทึก")
            return
        end

        action.time = os.clock() - recording.startedAt
        action.wave = wave
        action.waveTime = math.max(os.clock() - waveStartedAt, 0)
        table.insert(recording.macro.Actions, action)
    end

    local function onPlace(payload)
        if not alive or not activeMatch()
            or type(payload) ~= "table"
            or type(payload.Id) ~= "string"
            or not owned(payload) then
            return
        end

        if recording then
            if recording.keys[payload.Id] then return end

            if type(payload.Name) ~= "string"
                or typeof(payload.CFrame) ~= "CFrame" then
                stopWithError("TowerAdd ไม่ส่งชื่อหรือ CFrame ตามสัญญาที่ตรวจไว้")
                return
            end

            local key = tostring(#recording.macro.Actions + 1)
            recording.keys[payload.Id] = key
            recording.levels[payload.Id] = 1

            append({
                kind = "Place",
                key = key,
                name = payload.Name,
                cf = { payload.CFrame:GetComponents() },
            })
        end

        local action = playing and playing.pending

        if action and action.kind == "Place"
            and not action.before[payload.Id]
            and payload.Name == action.name
            and payload.UnitId == action.unitId
            and typeof(payload.Pos) == "Vector3"
            and (payload.Pos - action.position).Magnitude <= 0.5 then
            action.acknowledged = payload.Id
        end
    end

    local function onUpgrade(payload)
        if not alive or not activeMatch()
            or type(payload) ~= "table"
            or type(payload.Id) ~= "string"
            or not finite(payload.Level) then
            return
        end

        if recording then
            local key = recording.keys[payload.Id]

            if key and payload.Level > (recording.levels[payload.Id] or 1) then
                recording.levels[payload.Id] = payload.Level

                append({
                    kind = "Upgrade",
                    key = key,
                    level = payload.Level,
                })
            end
        end

        local action = playing and playing.pending

        if action and action.kind == "Upgrade"
            and payload.Id == action.id
            and payload.Level >= action.level then
            action.acknowledged = true
        end
    end

    local function bind(name, callback)
        local remote = getRemote(name)
        local old = bindings[name]

        if old and old.remote ~= remote then
            old.connection:Disconnect()
            bindings[name] = nil
            old = nil
        end

        if remote and not old then
            bindings[name] = {
                remote = remote,
                connection = remote.OnClientEvent:Connect(callback),
            }
        end

        return remote
    end

    local function startPlayback(data)
        local macro = selected and macros[selected]

        if not validateMacro(macro) then
            return false, "กรุณาเลือกมาโครที่มีคำสั่งและรูปแบบถูกต้อง"
        end

        if conflicting() then
            return false, "ปิด Auto Place, Auto Upgrade และขายตัวฟาร์มก่อน"
        end

        if hasOwnedTowers(data) then
            return false, "ยังเริ่มเล่นไม่ได้ มีทาวเวอร์ของเราวางอยู่แล้ว"
        end

        if macro.Map ~= workspace:GetAttribute("Map")
            or macro.Mode ~= workspace:GetAttribute("Mode") then
            return false, "แผนที่หรือความยากไม่ตรงกับมาโคร"
        end

        playing = {
            macro = macro,
            mode = playbackMode,
            index = 1,
            ids = {},
            startedAt = os.clock(),
        }

        controller.Active = true
        state = "Playing · กำลังเล่นมาโคร"
        return true
    end

    local function evaluatePlayback(data, add, upgrade)
        local session = playing
        if not session then return end

        if session.pending then
            local pending = session.pending
            local confirmed = false

            if pending.kind == "Place" and pending.acknowledged then
                local record = data.records[pending.acknowledged]

                confirmed = owned(record)
                    and record.Name == pending.name
                    and record.UnitId == pending.unitId

                if confirmed then
                    session.ids[pending.key] = pending.acknowledged
                end

            elseif pending.kind == "Upgrade" and pending.acknowledged then
                local record = data.records[pending.id]
                confirmed = owned(record)
                    and finite(record.Level)
                    and record.Level >= pending.level
            end

            if confirmed then
                session.pending = nil
                session.waitingSince = nil

                if pending.kind == "Upgrade"
                    and pending.finalLevel
                    and pending.level < pending.finalLevel then
                    -- คงข้อเดิมไว้ แล้วส่งอัปขั้นถัดไปในรอบตรวจถัดไป
                else
                    session.index += 1
                end

            elseif os.clock() - pending.sentAt >= 12 then
                stopWithError("หมดเวลายืนยันคำสั่ง ไม่ส่งซ้ำ")
            end

            return
        end

        local action = session.macro.Actions[session.index]

        if not action then
            playing = nil
            controller.Active = false
            state = "Completed · เล่นมาโครครบแล้ว"
            return
        end

        local wave = workspace:GetAttribute("Wave")

        if session.mode == "Time" then
            if os.clock() - session.startedAt < action.time then return end

        elseif session.mode == "Hybrid" then
            if not finite(wave) or wave < action.wave then return end

            if wave == action.wave
                and os.clock() - waveStartedAt < action.waveTime then
                return
            end
        end

        session.waitingSince = session.waitingSince or os.clock()

        if os.clock() - session.waitingSince >= 120 then
            stopWithError("รอเงินหรือเงื่อนไขคำสั่งนานเกิน 120 วินาที")
            return
        end

        local pending = {
            kind = action.kind,
            key = action.key,
        }

        if action.kind == "Place" then
            local definition = data.config.Towers[action.name]
            local tiers = type(definition) == "table" and definition.Upgrades
            local base = type(tiers) == "table" and tiers[1]
            local price = type(base) == "table" and base.Price

            if not finite(price) or price < 0 then
                stopWithError("ไม่พบราคาวาง: " .. action.name)
                return
            end

            if data.money.Value < price then return end

            local unitId

            for slot = 1, 5 do
                if LocalPlayer:GetAttribute("Slot" .. slot) == action.name then
                    local id = LocalPlayer:GetAttribute("Slot" .. slot .. "Id")

                    if type(id) == "string" and id ~= "" then
                        unitId = id
                        break
                    end
                end
            end

            if not unitId then
                stopWithError("ทีมไม่มีตัวละคร: " .. action.name)
                return
            end

            local placed = LocalPlayer:FindFirstChild("PlacedTowers")
            if not placed or not placed:IsA("IntValue") then return end

            if placed.Value >= 15 then
                stopWithError("จำนวนทาวเวอร์เต็ม")
                return
            end

            local count = 0
            for _, record in pairs(data.records) do
                if owned(record) and record.Name == action.name then
                    count += 1
                end
            end

            local limit = definition.PlacementLimit
            if limit ~= nil then
                if not finite(limit) or limit < 0 then
                    stopWithError("PlacementLimit ไม่ถูกต้อง")
                    return
                end
                if count >= limit then
                    stopWithError("วางครบจำนวนของ " .. action.name)
                    return
                end
            end

            local pivot = CFrame.new(table.unpack(action.cf))
            pending.name = action.name
            pending.unitId = unitId
            pending.position = pivot.Position
            pending.before = {}

            for id in pairs(data.records) do
                pending.before[id] = true
            end

            pending.sentAt = os.clock()
            session.pending = pending

            add:FireServer({
                Name = action.name,
                UnitId = unitId,
                Pos = pivot.Position,
                CFrame = pivot,
            })
        else
            local id = session.ids[action.key]
            local record = id and data.records[id]

            if not owned(record) then
                stopWithError("ไม่พบทาวเวอร์สำหรับอัปเกรดตามมาโคร")
                return
            end

            local level = record.Level or 1

            if not finite(level) then
                stopWithError("ระดับทาวเวอร์ไม่ถูกต้อง")
                return
            end

            if level >= action.level then
                session.index += 1
                session.waitingSince = nil
                return
            end

            local definition = data.config.Towers[record.Name]
            local tiers = type(definition) == "table" and definition.Upgrades
            local nextTier = type(tiers) == "table" and tiers[level + 1]
            local price = type(nextTier) == "table" and nextTier.Price

            if not finite(price) or price < 0 then
                stopWithError("ไม่พบขั้นอัปเกรดถัดไป")
                return
            end

            if data.money.Value < price then return end

            pending.id = id
            pending.level = level + 1
            pending.sentAt = os.clock()
            session.pending = pending

            upgrade:FireServer({ Id = id })

            -- หากไฟล์บันทึกข้ามหลายระดับ ให้ไล่อัปทีละขั้น
            pending.finalLevel = action.level
        end
    end

    local function stopSession()
        if recording then
            finishRecording()
        end

        playing = nil
        controller.Active = false

        if recordToggle and recordToggle.Value then
            recordToggle:SetValue(false)
        end
    end

    table.insert(connections,
        workspace:GetAttributeChangedSignal("Wave"):Connect(function()
            waveStartedAt = os.clock()
        end)
    )

    table.insert(connections,
        workspace:GetAttributeChangedSignal("GameState"):Connect(function()
            if workspace:GetAttribute("GameState") == "Restarting" then
                stopSession()
                attempted = false
                waveStartedAt = os.clock()
                state = "Idle · รอรอบใหม่"
            end
        end)
    )

    local function evaluate()
        local data = runtime()
        local add = bind("TowerAdd", onPlace)
        local upgrade = bind("TowerUpgrade", onUpgrade)

        if not activeMatch() then
            if recording or playing then
                stopSession()
                state = "Idle · ด่านสิ้นสุดหรือออกจากช่วงเล่น"
            end
            return
        end

        if not data or not add or not upgrade then
            state = "Waiting · รอข้อมูลและรีโมทในด่าน"
            return
        end

        if automatic and not attempted and not recording then
            -- รอข้อมูลชื่อด่านพร้อมก่อนตัดสินใจเริ่ม
            if type(workspace:GetAttribute("Map")) ~= "string"
                or type(workspace:GetAttribute("Mode")) ~= "string" then
                return
            end

            attempted = true
            local ok, reason = startPlayback(data)
            if not ok then state = "Stopped · " .. reason end
        end

        if playing then
            evaluatePlayback(data, add, upgrade)
        end
    end

    function controller.Stop()
        if not alive then return end
        stopSession()
        alive = false

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        for _, binding in pairs(bindings) do
            binding.connection:Disconnect()
        end

        table.clear(connections)
        table.clear(bindings)
    end

    MacUI:OnUnload(controller.Stop)

    local displayed = {}

    local function display(label, text)
        if displayed[label] ~= text then
            displayed[label] = text
            label:SetValue(text)
        end
    end

    task.spawn(function()
        while alive do
            local ok, problem = pcall(evaluate)

            if not ok then
                stopWithError(tostring(problem))
            end

            if alive then
                local data = runtime()
                local macro = selected and macros[selected]
                local count = macro and type(macro.Actions) == "table"
                    and #macro.Actions or 0

                display(stateLabel, state)

                display(liveLabel, string.format(
                    "เวฟ %s | %s | เงิน %s",
                    tostring(workspace:GetAttribute("Wave") or "-"),
                    playing and playing.mode or playbackMode,
                    data and tostring(data.money.Value) or "-"
                ))

                display(actionsLabel, string.format(
                    "%s | %d คำสั่ง%s",
                    selected or "ยังไม่ได้เลือก",
                    count,
                    playing and (" | กำลังทำข้อ " .. playing.index) or ""
                ))
            end

            task.wait(0.2)
        end
    end)
end

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
        Description = "WASD: เคลื่อนที่ตามกล้อง\nSpace: ขึ้น\nLeft Ctrl: ลง",
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

-- Keep the original settings folders and custom theme loading.
--------------------------------------------------------------------------------
-- ZERO X: local overhead name (verified OverHead hierarchy)
-- Changes only the LocalPlayer's existing name labels on this client.
--------------------------------------------------------------------------------
do
    local TARGET_NAME = "ZERO X SCRIPTHUB"
    local alive = true
    local queued = false
    local character
    local playerConnections = {}
    local characterConnections = {}
    local labels = {}

    local function DisconnectAll(list)
        for _, connection in ipairs(list) do
            connection:Disconnect()
        end
        table.clear(list)
    end

    local function EscapeRichText(value)
        return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
    end

    local function NameTexts()
        local tag = LocalPlayer:GetAttribute("GuildTag")
        if type(tag) ~= "string" or tag == "" then
            return TARGET_NAME, EscapeRichText(TARGET_NAME)
        end

        local color = LocalPlayer:GetAttribute("GuildColor")
        local hex = typeof(color) == "Color3" and color:ToHex() or "8D89ED"
        return "[" .. tag .. "] " .. TARGET_NAME,
            '<font color="#' .. hex .. '">[' .. EscapeRichText(tag)
                .. ']</font> ' .. EscapeRichText(TARGET_NAME)
    end

    local function ReleaseLabel(label, record)
        record.Connection:Disconnect()
        pcall(function()
            if label.Text == record.Expected then
                label.Text = record.Original
            end
        end)
        labels[label] = nil
    end

    local function ClearLabels()
        for label, record in pairs(labels) do
            ReleaseLabel(label, record)
        end
    end

    local Refresh
    local function ScheduleRefresh()
        if not alive or queued then return end
        queued = true
        task.defer(function()
            queued = false
            if alive then Refresh() end
        end)
    end

    Refresh = function()
        local overhead = character and character:FindFirstChild("OverHead")
        if overhead and not overhead:IsA("BillboardGui") then overhead = nil end
        local main = overhead and overhead:FindFirstChild("Main")
        local display = main and main:FindFirstChild("DisplayName")
        local shadow = display and display:FindFirstChild("TxtShadow")
        local front = shadow and shadow:FindFirstChild("Txt")
        local plainText, richText = NameTexts()
        local wanted = {}

        if shadow and shadow:IsA("TextLabel") then
            wanted[shadow] = plainText
        end
        if front and front:IsA("TextLabel") then
            wanted[front] = front.RichText and richText or plainText
        end

        for label, record in pairs(labels) do
            if wanted[label] == nil then ReleaseLabel(label, record) end
        end

        for label, text in pairs(wanted) do
            local record = labels[label]
            if not record then
                record = { Original = label.Text }
                labels[label] = record
                record.Connection = label:GetPropertyChangedSignal("Text"):Connect(function()
                    if not alive or labels[label] ~= record then return end
                    if label.Text ~= record.Expected then
                        record.Original = label.Text
                        ScheduleRefresh()
                    end
                end)
            elseif label.Text ~= record.Expected then
                record.Original = label.Text
            end

            record.Expected = text
            if label.Text ~= text then label.Text = text end
        end
    end

    local function BindCharacter(nextCharacter)
        DisconnectAll(characterConnections)
        ClearLabels()
        character = nextCharacter
        if character then
            table.insert(characterConnections,
                character.DescendantAdded:Connect(ScheduleRefresh))
            table.insert(characterConnections,
                character.DescendantRemoving:Connect(ScheduleRefresh))
        end
        ScheduleRefresh()
    end

    table.insert(playerConnections, LocalPlayer.CharacterAdded:Connect(BindCharacter))
    table.insert(playerConnections, LocalPlayer.CharacterRemoving:Connect(function(oldCharacter)
        if character == oldCharacter then BindCharacter(nil) end
    end))
    table.insert(playerConnections,
        LocalPlayer:GetAttributeChangedSignal("GuildTag"):Connect(ScheduleRefresh))
    table.insert(playerConnections,
        LocalPlayer:GetAttributeChangedSignal("GuildColor"):Connect(ScheduleRefresh))

    MacUI:OnUnload(function()
        alive = false
        DisconnectAll(playerConnections)
        DisconnectAll(characterConnections)
        ClearLabels()
        character = nil
    end)

    BindCharacter(LocalPlayer.Character)
end

ThemeManager:SetLibrary(MacUI)
ThemeManager:SetFolder("ZeroX")
ThemeManager:LoadCustomThemes()

InterfaceManager:SetLibrary(MacUI)
InterfaceManager:SetFolder("ZeroX")
InterfaceManager:BuildInterfaceSection(Tabs.Appearance)

-- Profiles: saved separately for each PlaceId, as in the supplied file.
SaveManager:SetLibrary(MacUI)
SaveManager:SetFolder("ZeroX/" .. tostring(game.GameId))
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Profiles)

-- Keep this call after all controls are created.
SaveManager:LoadAutoloadConfig()

if Options.ZeroXHideOnStart and Options.ZeroXHideOnStart.Value then
    Window:Minimize()
end
