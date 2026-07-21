-- context: server
-- apis: Instance.new, BindableEvent, Event, Connect, Fire
local bindableEvent = Instance.new("BindableEvent")

bindableEvent.Event:Connect(function(data: string)
print("Received via BindableEvent: " .. data)
end)

bindableEvent:Fire("Hello from another module!")
</EOF>

cat > "$T/06-bindableevents/01-fire-connect.yaml" << 'EOF'
id: "06-bindableevents-01-fire-connect"
category: "bindableevents"
context_type: "server"
prompt: "Create a server Script that creates a BindableEvent, connects a listener that prints received data, and then fires it with a test message."
ground_truth: "01-fire-connect.luau"
expected_apis:
  - "Instance.new"
  - "BindableEvent"
  - "Event"
  - "Connect"
  - "Fire"
expected_patterns:
  - "bindable-fire"
  - "event-connect"
