--!strict
-- Plugin bootstrap — loaded by Roblox Studio when the plugin is activated.
-- Sets up the toolbar button and the main interactive widget with:
--   - API key authentication (TextBox + Connect button)
--   - Tier badge display
--   - Code generation (query TextBox + Generate button)
--   - Read-only code output display with Copy button
--
-- NON-NEGOTIABLE: Generated code is NEVER executed. Display and copy only.

local Plugin = plugin -- Roblox injects the `plugin` global

local Toolbar = Plugin:CreateToolbar("AI Assistant")
local Constants = require(script.Parent.Shared.Constants)
local HttpService = require(script.Parent.Server.HttpService)

-- ── State ───────────────────────────────────────────────────────────────

local _http = HttpService.new(Constants.API_BASE_URL)
local _isAuthenticated = false
local _tier = "free"
local _generatedCode = ""

-- ── Widget ──────────────────────────────────────────────────────────────

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,  -- initEnabled
	false,  -- overrideEnabledRestore
	Constants.WIDGET_MIN_WIDTH.X,
	Constants.WIDGET_MIN_WIDTH.Y,
	Constants.WIDGET_DEFAULT_SIZE.X,
	Constants.WIDGET_DEFAULT_SIZE.Y
)

local widget = Plugin:CreateDockWidgetPluginGui("AI_Assistant_Widget", widgetInfo)
widget.Name = Constants.PLUGIN_NAME
widget.Title = Constants.PLUGIN_NAME
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ── ScreenGui ───────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AIAssistantGui"
screenGui.Parent = widget

-- ── Main Frame ──────────────────────────────────────────────────────────

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- ── Helper to create UI elements ────────────────────────────────────────

local function createLabel(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, textSize: number, color: Color3, transparency: number?, font: Enum.Font?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = transparency or 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = font or Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function createTextBox(parent: Instance, name: string, placeholder: string, size: UDim2, position: UDim2, textSize: number): TextBox
	local box = Instance.new("TextBox")
	box.Name = name
	box.Size = size
	box.Position = position
	box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	box.BorderSizePixel = 0
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = textSize
	box.Font = Enum.Font.Gotham
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.Parent = parent
	return box
end

local function createButton(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, bgColor: Color3, textSize: number?): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = bgColor
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = textSize or 14
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = true
	btn.Parent = parent
	return btn
end

-- ── Title Bar ───────────────────────────────────────────────────────────

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = createLabel(
	titleBar, "TitleLabel", Constants.PLUGIN_NAME,
	UDim2.new(1, -100, 1, 0), UDim2.new(0, 12, 0, 0),
	16, Color3.fromRGB(255, 255, 255), 1, Enum.Font.GothamBold
)

-- Tier badge (hidden until authenticated)
local tierBadge = Instance.new("TextLabel")
tierBadge.Name = "TierBadge"
tierBadge.Size = UDim2.new(0, 70, 0, 20)
tierBadge.Position = UDim2.new(1, -84, 0.5, -10)
tierBadge.BackgroundColor3 = Color3.fromRGB(64, 64, 64)
tierBadge.BorderSizePixel = 0
tierBadge.Text = ""
tierBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
tierBadge.TextSize = 11
tierBadge.Font = Enum.Font.GothamBold
tierBadge.Visible = false
tierBadge.Parent = titleBar

-- ── Scrollable Content Area ─────────────────────────────────────────────

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ContentScroll"
scrollFrame.Size = UDim2.new(1, 0, 1, -36)
scrollFrame.Position = UDim2.new(0, 0, 0, 36)
scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 520)
scrollFrame.Parent = mainFrame

local padding = 12
local elementWidth = 1
local currentY = padding

-- ── Section: API Key ────────────────────────────────────────────────────

createLabel(
	scrollFrame, "ApiKeyHeader", "API Key",
	UDim2.new(elementWidth, -padding*2, 0, 18),
	UDim2.new(0, padding, 0, currentY),
	13, Color3.fromRGB(200, 200, 200), 1, Enum.Font.GothamBold
)
currentY += 20

local apiKeyBox = createTextBox(
	scrollFrame, "ApiKeyBox", "Paste your API key here...",
	UDim2.new(elementWidth, -padding*2, 0, 32),
	UDim2.new(0, padding, 0, currentY),
	13
)
currentY += 38

local connectButton = createButton(
	scrollFrame, "ConnectButton", "Connect",
	UDim2.new(0, 90, 0, 28),
	UDim2.new(0, padding, 0, currentY),
	Color3.fromRGB(0, 140, 200),
	13
)
currentY += 36

-- Connect status label
local connectStatusLabel = createLabel(
	scrollFrame, "ConnectStatus", "",
	UDim2.new(elementWidth, -padding*2, 0, 16),
	UDim2.new(0, padding + 96, 0, currentY - 28),
	11, Color3.fromRGB(180, 180, 180), 1
)

-- ── Divider ─────────────────────────────────────────────────────────────

local divider1 = Instance.new("Frame")
divider1.Name = "Divider1"
divider1.Size = UDim2.new(elementWidth, -padding*2, 0, 1)
divider1.Position = UDim2.new(0, padding, 0, currentY)
divider1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
divider1.BorderSizePixel = 0
divider1.Parent = scrollFrame
currentY += 12

-- ── Section: Generate Code ──────────────────────────────────────────────

createLabel(
	scrollFrame, "GenerateHeader", "Generate Code",
	UDim2.new(elementWidth, -padding*2, 0, 18),
	UDim2.new(0, padding, 0, currentY),
	13, Color3.fromRGB(200, 200, 200), 1, Enum.Font.GothamBold
)
currentY += 22

local queryBox = createTextBox(
	scrollFrame, "QueryBox", "Describe the Luau code you need...",
	UDim2.new(elementWidth, -padding*2, 0, 60),
	UDim2.new(0, padding, 0, currentY),
	13
)
queryBox.TextWrapped = true
queryBox.MultiLine = true
queryBox.TextYAlignment = Enum.TextYAlignment.Top
currentY += 66

local generateButton = createButton(
	scrollFrame, "GenerateButton", "Generate",
	UDim2.new(0, 100, 0, 28),
	UDim2.new(0, padding, 0, currentY),
	Color3.fromRGB(0, 170, 100),
	13
)
currentY += 36

-- Generate status
local generateStatusLabel = createLabel(
	scrollFrame, "GenerateStatus", "",
	UDim2.new(elementWidth, -padding*2, 0, 16),
	UDim2.new(0, padding + 106, 0, currentY - 28),
	11, Color3.fromRGB(180, 180, 180), 1
)

-- ── Divider 2 ──────────────────────────────────────────────────────────

local divider2 = Instance.new("Frame")
divider2.Name = "Divider2"
divider2.Size = UDim2.new(elementWidth, -padding*2, 0, 1)
divider2.Position = UDim2.new(0, padding, 0, currentY)
divider2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
divider2.BorderSizePixel = 0
divider2.Parent = scrollFrame
currentY += 12

-- ── Section: Code Output ────────────────────────────────────────────────

createLabel(
	scrollFrame, "OutputHeader", "Generated Code",
	UDim2.new(elementWidth, -padding*2, 0, 18),
	UDim2.new(0, padding, 0, currentY),
	13, Color3.fromRGB(200, 200, 200), 1, Enum.Font.GothamBold
)
currentY += 22

-- Copy button (hidden until code is generated)
local copyButton = createButton(
	scrollFrame, "CopyButton", "Copy",
	UDim2.new(0, 60, 0, 24),
	UDim2.new(0, padding, 0, currentY),
	Color3.fromRGB(70, 70, 70),
	11
)
copyButton.Visible = false
currentY += 30

-- Code output label
local codeOutputLabel = createLabel(
	scrollFrame, "CodeOutput", "Generated code will appear here...",
	UDim2.new(elementWidth, -padding*2, 0, 180),
	UDim2.new(0, padding, 0, currentY),
	12, Color3.fromRGB(160, 220, 160), 0
)
codeOutputLabel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
codeOutputLabel.TextXAlignment = Enum.TextXAlignment.Left
codeOutputLabel.TextYAlignment = Enum.TextYAlignment.Top
codeOutputLabel.Font = Enum.Font.RobotoMono
currentY += 190

-- ── Error display label ─────────────────────────────────────────────────

local errorLabel = createLabel(
	scrollFrame, "ErrorLabel", "",
	UDim2.new(elementWidth, -padding*2, 0, 40),
	UDim2.new(0, padding, 0, currentY),
	11, Color3.fromRGB(255, 120, 120), 1
)
errorLabel.Visible = false

-- Update canvas to fit content
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, currentY + 40)

-- ── Event Handlers ──────────────────────────────────────────────────────

-- Tier badge colors
local tierColors = {
	free = Color3.fromRGB(100, 100, 100),
	hobbyist = Color3.fromRGB(0, 160, 100),
	pro = Color3.fromRGB(0, 120, 200),
	studio = Color3.fromRGB(180, 100, 0),
}

local function updateTierBadge(tier: string)
	local displayName = tier:gsub("^%l", string.upper) -- Capitalize
	tierBadge.Text = displayName
	tierBadge.BackgroundColor3 = tierColors[tier] or tierColors.free
	tierBadge.Visible = true
end

local function setStatus(label: TextLabel, text: string, isError: boolean?)
	label.Text = text
	if isError then
		label.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		label.TextColor3 = Color3.fromRGB(180, 180, 180)
	end
end

local function hideError()
	errorLabel.Visible = false
	errorLabel.Text = ""
end

local function showError(message: string)
	errorLabel.Text = message
	errorLabel.Visible = true
end

-- Connect button: validate API key
connectButton.MouseButton1Click:Connect(function()
	hideError()
	local key = apiKeyBox.Text:gsub("^%s+", ""):gsub("%s+$", "") -- trim

	if key == "" then
		setStatus(connectStatusLabel, "Please enter an API key", true)
		return
	end

	setStatus(connectStatusLabel, "Validating...", false)
	connectButton.Text = "..."
	connectButton.Interactable = false

	-- Use a coroutine/deferred call to avoid blocking the UI
	task.spawn(function()
		local result = _http:validateKey(key)

		if result.success and result.data then
			if result.data.valid then
				_isAuthenticated = true
				_tier = result.data.tier or "free"
				_http:setApiKey(key)
				updateTierBadge(_tier)

				local creditsStr = ""
				if result.data.creditsRemaining then
					creditsStr = string.format(" | %d credits remaining", result.data.creditsRemaining)
				end
				setStatus(connectStatusLabel, "Connected! Tier: " .. _tier .. creditsStr, false)
			else
				_isAuthenticated = false
				_tier = "free"
				_http:setApiKey("")
				tierBadge.Visible = false
				setStatus(connectStatusLabel, "Invalid API key", true)
			end
		else
			_isAuthenticated = false
			_http:setApiKey("")
			tierBadge.Visible = false
			local errMsg = result.error and result.error.message or "Connection failed"
			setStatus(connectStatusLabel, errMsg, true)
		end

		connectButton.Text = "Connect"
		connectButton.Interactable = true
	end)
end)

-- Generate button: send query to backend
generateButton.MouseButton1Click:Connect(function()
	hideError()
	local query = queryBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

	if query == "" then
		setStatus(generateStatusLabel, "Enter a query first", true)
		return
	end

	if not _isAuthenticated then
		setStatus(generateStatusLabel, "Connect with an API key first", true)
		return
	end

	setStatus(generateStatusLabel, "Generating...", false)
	generateButton.Text = "..."
	generateButton.Interactable = false

	task.spawn(function()
		local req = {
			query = query,
			contextType = "module",
			topK = Constants.DEFAULT_TOP_K,
			model = Constants.DEFAULT_MODEL,
		}

		local result = _http:generate(req)

		if result.success and result.data then
			_generatedCode = result.data.code
			codeOutputLabel.Text = _generatedCode
			copyButton.Visible = true

			local uncertainNote = if result.data.isUncertain then " (AI uncertain)" else ""
			setStatus(generateStatusLabel, string.format(
				"Done! %d chars, %.0fms%s",
				#_generatedCode,
				result.data.totalTimeMs,
				uncertainNote
			), false)
		else
			_generatedCode = ""
			codeOutputLabel.Text = "Generation failed."
			copyButton.Visible = false

			local errMsg = result.error and result.error.message or "Unknown error"
			if result.error and result.error.statusCode == 402 then
				showError("No credits left. Upgrade your tier at " .. Constants.API_BASE_URL .. "/#pricing")
				setStatus(generateStatusLabel, "Out of credits — upgrade to continue", true)
			else
				showError(errMsg)
				setStatus(generateStatusLabel, "Generation failed", true)
			end
		end

		generateButton.Text = "Generate"
		generateButton.Interactable = true
	end)
end)

-- Copy button: copy generated code to clipboard
copyButton.MouseButton1Click:Connect(function()
	if _generatedCode ~= "" then
		pcall(function()
			local clipboardService = game:GetService("Storable") -- fallback, actual clipboard is platform-specific
		end)
		-- Roblox plugins can use setclipboard via plugin: function
		pcall(function()
			plugin:SetClipboard(_generatedCode)
		end)
		copyButton.Text = "Copied!"
		task.delay(1.5, function()
			copyButton.Text = "Copy"
		end)
	end
end)

-- ── Toolbar button toggle ──────────────────────────────────────────────

local button = Toolbar:CreateButton(
	"Open",
	"Open the Roblox AI Code Assistant panel",
	"rbxassetid://0", -- TODO: replace with plugin icon asset ID
	"AI Assistant"
)

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- ── Cleanup ─────────────────────────────────────────────────────────────

Plugin.Unloading:Connect(function()
	widget:Destroy()
end)

print("[Roblox AI Code Assistant] Plugin loaded — v" .. Constants.PLUGIN_VERSION)
