-- context: module
-- apis: require, ModuleScript, table
type InventoryItem = {
name: string,
quantity: number,
rarity: string,
}

type Inventory = {
items: {InventoryItem},
addItem: (self: Inventory, item: InventoryItem) -> (),
removeItem: (self: Inventory, name: string) -> boolean,
getTotalItems: (self: Inventory) -> number,
}

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(): Inventory
local self = setmetatable({
items = {},
}, Inventory)
return self
end

function Inventory:addItem(item: InventoryItem)
table.insert(self.items, item)
end

function Inventory:removeItem(name: string): boolean
for i, item in ipairs(self.items) do
if item.name == name then
table.remove(self.items, i)
return true
end
end
return false
end

function Inventory:getTotalItems(): number
return #self.items
end

return Inventory
</EOF>

cat > "$T/05-modulescripts/02-typed-module.yaml" << 'EOF'
id: "05-modulescripts-02-typed-module"
category: "modulescripts"
context_type: "module"
prompt: "Create a typed ModuleScript for an Inventory system using Luau OOP patterns. Include types for InventoryItem and Inventory with addItem, removeItem, and getTotalItems methods."
ground_truth: "02-typed-module.luau"
expected_apis:
  - "require"
  - "setmetatable"
  - "table.insert"
  - "table.remove"
  - "ipairs"
expected_patterns:
  - "module-return"
  - "typed-functions"
  - "oop-pattern"
