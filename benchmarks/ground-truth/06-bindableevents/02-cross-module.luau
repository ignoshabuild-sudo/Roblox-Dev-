-- context: module
-- apis: BindableEvent, Instance.new, Event, Connect, Fire
local Signal = {}
Signal.__index = Signal

function Signal.new(): {Fire: (...any) -> (), Connect: (callback: (...any) -> ()) -> RBXScriptConnection}
local self = setmetatable({}, Signal)
self._event = Instance.new("BindableEvent")
return self
end

function Signal:Fire(...: any)
self._event:Fire(...)
end

function Signal:Connect(callback: (...any) -> ()): RBXScriptConnection
return self._event.Event:Connect(callback)
end

return Signal
</EOF>

cat > "$T/06-bindableevents/02-cross-module.yaml" << 'EOF'
id: "06-bindableevents-02-cross-module"
category: "bindableevents"
context_type: "module"
prompt: "Create a ModuleScript that wraps BindableEvent into a reusable Signal class with Fire and Connect methods, supporting variadic arguments."
ground_truth: "02-cross-module.luau"
expected_apis:
  - "Instance.new"
  - "BindableEvent"
  - "Event"
  - "Connect"
  - "Fire"
  - "setmetatable"
expected_patterns:
  - "bindable-fire"
  - "module-return"
  - "oop-pattern"
