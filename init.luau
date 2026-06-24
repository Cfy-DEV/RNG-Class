export type WeightedRNG = {
	RemoveItemOnRoll: boolean,
	TotalWeight: number,
	Items: { [string]: number },

	AddItem: (self: WeightedRNG, item: string, weight: number) -> (),
	RemoveItem: (self: WeightedRNG, item: string) -> boolean,
	Clean: (self: WeightedRNG) -> (),
	Roll: (self: WeightedRNG) -> string?,
}

export type PercentageItem = {
	Name: string,
	Chance: number,
}

export type PercentageRNG = {
	RemoveItemOnRoll: boolean,
	Range: number,
	ReturnNilWhenNone: boolean,
	Items: {
		Info: { PercentageItem },
		Names: { [string]: number },
	},

	AddItem: (self: PercentageRNG, item: string, percentage: number) -> (),
	RemoveItem: (self: PercentageRNG, item: string) -> boolean,
	Clean: (self: PercentageRNG) -> (),
	Roll: (self: PercentageRNG) -> string?,
}

export type RNGModule = {
	NewWeightedRNG: () -> WeightedRNG,
	NewPercentualRNG: () -> PercentageRNG,
}

local PercentageRNG = {}
PercentageRNG.__index = PercentageRNG

local WeightedRNG = {}
WeightedRNG.__index = WeightedRNG

--[[
Creates a new WeightedRNG object.

DO NOT CHANGE TOTALWEIGHT DIRECTLY!!!

Stores items associated with percentage weights and allows
rolling a random item based on these.

Example:

```lua
local rng = module.NewWeightedRNG()
rng:AddItem("One", 5)
rng:AddItem("Two", 4)
rng:AddItem("Three", 3)

print(rng:Roll())

rng:RemoveItem("One")

print(rng:Roll())
```
]]
function module.NewWeightedRNG() : WeightedRNG
	local self = setmetatable({}, WeightedRNG)

	self.RemoveItemOnRoll = false
	self.TotalWeight = 0
	self.Items = {}

	return self
end

--[[
Adds a new item to the WeightedRNG container.
]]
function WeightedRNG:AddItem(item, weight)
	if self.Items[item] then return end
	assert(typeof(item) == "string", "Item must be a string.")
	assert(typeof(weight) == "number", "Weight must be a number.")
	self.Items[item] = weight
	self.TotalWeight += weight
end

--[[
Removes given item from container.
]]
function WeightedRNG:RemoveItem(item)
	local weight = self.Items[item]
	if not weight then
		return false
	end

	self.TotalWeight -= weight
	self.Items[item] = nil
	return true
end

--[[
Clears the container.
]]
function WeightedRNG:Clean()
	table.clear(self.Items)
	self.TotalWeight = 0
end

--[[
Rolls the items in the container based off their weight.
]]
function WeightedRNG:Roll()
	local items = self.Items
	if self.TotalWeight <= 0 then
		warn("The weight cannot be equal or smaller then zero")
		return
	end

	local chosenItem

	local roll = math.random() * self.TotalWeight
	local cumulative = 0

	for item, weight in pairs(items) do
		cumulative += weight
		if roll <= cumulative then
			chosenItem = item
			break
		end
	end

	if self.RemoveItemOnRoll then
		self:RemoveItem(chosenItem)
	end

	return chosenItem
end

--[[
Creates a new PercentageRNG object.

Stores items associated with percentage chances and allows
rolling a random item based on those chances.

The bigger the range is, the more precise it will generate percentages.

Example:

```lua
local rng = module.NewPercentualRNG()

rng:AddItem("One", 20)
rng:AddItem("Two", 40)
rng:AddItem("Three", 60)

print(rng:Roll())

rng.Range = 10000

rng:RemoveItem("One")

rng:AddItem("Four", 75.02)
rng:AddItem("Five", 30.402)

print(rng:Roll())
```
]]
function module.NewPercentualRNG() : PercentageRNG
	local self = setmetatable({}, PercentageRNG)

	self.RemoveItemOnRoll = false
	self.Range = 100
	self.ReturnNilWhenNone = false
	self.Items = {
		Info = {},
		Names = {},
	}

	return self
end

--[[
Adds a new item to the PercentageRNG container.
]]
function PercentageRNG:AddItem(item, percentage)
	if self.Items.Names[item] then
		return
	end
	assert(typeof(item) == "string", "Item must be a string.")
	assert(typeof(percentage) == "number", "Percentage must be a number.")
	assert(percentage >= 0 and percentage <= 100, "Percentage must be between 0 and 100")
	self.Items.Names[item] = percentage
	table.insert(self.Items.Info, { Name = item, Chance = percentage })
	table.sort(self.Items.Info, function(a, b)
		return a.Chance < b.Chance
	end)
end

--[[
Cleans the item table.
]]
function PercentageRNG:Clean()
	table.clear(self.Items.Names)
	table.clear(self.Items.Info)
end

--[[
Rolls items relative to their percentage and returns whatever the result was.
]]
function PercentageRNG:Roll()
	local items = self.Items.Info

	if #items == 0 then
		warn("Trying to roll with 0 items")
		return nil
	end

	local itemGotten
	local perc = (math.random(0, self.Range) / self.Range) * 100

	for i = 1, #items do
		local item = items[i]
		if item.Chance >= perc then
			itemGotten = item.Name
			break
		end
	end

	if itemGotten ~= nil then
		if self.RemoveItemOnRoll then
			self:RemoveItem(itemGotten)
		end
	else
		if self.ReturnNilWhenNone then
			return nil
		else
			itemGotten = items[#items]["Name"]
		end
	end

	return itemGotten
end

function PercentageRNG:RemoveItem(item)
	self.Items.Names[item] = nil

	for i, v in ipairs(self.Items.Info) do
		if v.Name == item then
			table.remove(self.Items.Info, i)
			return true
		end
	end

	return false
end

return module