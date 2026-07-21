-- context: module
-- apis: require, ModuleScript, table
local MathUtils = {}

function MathUtils.clamp(value: number, min: number, max: number): number
return math.max(min, math.min(max, value))
end

function MathUtils.lerp(a: number, b: number, t: number): number
return a + (b - a) * t
end

function MathUtils.round(value: number, decimals: number?): number
local mult = 10 ^ (decimals or 0)
return math.floor(value * mult + 0.5) / mult
end

return MathUtils
</EOF>

cat > "$T/05-modulescripts/01-basic-module.yaml" << 'EOF'
id: "05-modulescripts-01-basic-module"
category: "modulescripts"
context_type: "module"
prompt: "Create a ModuleScript called MathUtils that exports three utility functions: clamp(value, min, max), lerp(a, b, t), and round(value, decimals). Use strict typing."
ground_truth: "01-basic-module.luau"
expected_apis:
  - "require"
  - "math.max"
  - "math.min"
  - "math.floor"
expected_patterns:
  - "module-return"
  - "typed-functions"
