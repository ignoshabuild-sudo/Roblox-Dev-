--!strict
-- Plugin bootstrap — loaded by Roblox Studio when the plugin is activated.
-- Sets up the toolbar button and placeholder widget.

local Plugin = plugin -- Roblox injects the `plugin` global

local Toolbar = Plugin:CreateToolbar("AI Assistant")
local Constants = require(script.Parent.Shared.Constants)

local button = Toolbar:CreateButton(
	"Open",
	"Open the Roblox AI Code Assistant panel",
	"rbxassetid://0", -- TODO: replace with plugin icon asset ID
	"AI Assistant"
)

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

-- ── Placeholder UI ──────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AIAssistantGui"
screenGui.Parent = widget

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = Constants.PLUGIN_NAME
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Version badge
local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "VersionLabel"
versionLabel.Size = UDim2.new(0, 48, 0, 18)
versionLabel.Position = UDim2.new(1, -60, 0.5, -9)
versionLabel.BackgroundColor3 = Color3.fromRGB(64, 64, 64)
versionLabel.Text = "v" .. Constants.PLUGIN_VERSION
versionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
versionLabel.TextSize = 11
versionLabel.Font = Enum.Font.Gotham
versionLabel.Parent = titleBar

-- Placeholder content area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, 0, 1, -36)
contentArea.Position = UDim2.new(0, 0, 0, 36)
contentArea.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame

local placeholderLabel = Instance.new("TextLabel")
placeholderLabel.Name = "PlaceholderLabel"
placeholderLabel.Size = UDim2.new(1, -32, 1, -32)
placeholderLabel.Position = UDim2.new(0, 16, 0, 16)
placeholderLabel.BackgroundTransparency = 1
placeholderLabel.Text = "Roblox AI Code Assistant\n\nPowered by RAG-grounded LLM generation\n\nComing soon..."
placeholderLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
placeholderLabel.TextSize = 14
placeholderLabel.Font = Enum.Font.Gotham
placeholderLabel.TextWrapped = true
placeholderLabel.Parent = contentArea

-- ── Toolbar button toggle ───────────────────────────────────────────────

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- ── Cleanup ─────────────────────────────────────────────────────────────

Plugin.Unloading:Connect(function()
	widget:Destroy()
end)

print("[Roblox AI Code Assistant] Plugin loaded — v" .. Constants.PLUGIN_VERSION)
