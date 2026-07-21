-- context: server
-- apis: Lighting, GetService, Bloom, ColorCorrection, Atmosphere, Instance.new
local Lighting = game:GetService("Lighting")

-- Configure ambient lighting
Lighting.Ambient = Color3.fromRGB(40, 40, 50)
Lighting.OutdoorAmbient = Color3.fromRGB(80, 90, 100)
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.GeographicLatitude = 41

-- Add Bloom effect
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 0.9
bloom.Parent = Lighting

-- Add ColorCorrection effect
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.05
colorCorrection.Contrast = 0.1
colorCorrection.Saturation = 0.15
colorCorrection.TintColor = Color3.fromRGB(255, 240, 220)
colorCorrection.Parent = Lighting
</EOF>

cat > "$T/13-lighting/01-ambient-bloom.yaml" << 'EOF'
id: "13-lighting-01-ambient-bloom"
category: "lighting"
context_type: "server"
prompt: "Create a server Script that configures Lighting with ambient color, outdoor ambient, brightness, and ClockTime. Add a BloomEffect and ColorCorrectionEffect with specific intensity/contrast settings."
ground_truth: "01-ambient-bloom.luau"
expected_apis:
  - "GetService"
  - "Lighting"
  - "BloomEffect"
  - "ColorCorrectionEffect"
  - "Instance.new"
  - "Color3.fromRGB"
expected_patterns:
  - "get-service"
  - "lighting-config"
  - "post-processing"
