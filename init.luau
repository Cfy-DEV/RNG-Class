type Item = {
	Name: string,
	Chance: number,
}

export type RNG = {
	Range: number,
	ReturnNil: boolean,
	Items: { [number]: Item },

	AddItem: (self: RNG, item: any, percentage: number) -> (),
	Roll: (self: RNG) -> any?,
}

local module = {}
local RNG = {}
RNG.__index = RNG

--[[
Creates a new object with RNG class.

    Store items with certain chances
    Roll within given range
]]
function module.new(): RNG
	local self = setmetatable({}, RNG)

	self.Range = 10000
	self.ReturnNil = false
	self.Items = {}

	return self
end

--[[
Adds a new item to the RNG container.
]]
function RNG:AddItem(item, percentage)
	assert(percentage >= 0 and percentage <= 100, "Percentage must be between 0 and 100")
	table.insert(self.Items, { Name = item, Chance = percentage })
	table.sort(self.Items, function(a, b)
		return a.Chance > b.Chance
	end)
end

--[[
Rolls items relative to their percentage and returns whatever the result was.
]]
function RNG:Roll()
	if #self.Items == 0 then
		return nil
	end

	local perc = (math.random(0, self.Range) / self.Range) * 100

	for i = #self.Items, 1, -1 do
		local item = self.Items[i]

		if item.Chance >= perc then
			return item.Name
		end
	end

	if self.ReturnNil then
		return nil
	else
		return self.Items[1].Name
	end
end

return module
