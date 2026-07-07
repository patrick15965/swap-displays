-- BEGIN swap-displays
-- Enforces a stable left-to-right layout and toggles the two externals.
-- Lid open:    [built-in] [external A] [external B]
-- Lid closed:              [external A] [external B]
-- Each invocation swaps A and B by declaring a new primary and re-placing.
local function isBuiltIn(screen)
	local name = screen:name() or ""
	return name:find("Built%-in") ~= nil
end

function swapExternalDisplays()
	local screens = hs.screen.allScreens()
	local builtIn, externals = nil, {}
	for _, s in ipairs(screens) do
		if isBuiltIn(s) then
			builtIn = s
		else
			table.insert(externals, s)
		end
	end

	if #externals < 2 then
		hs.alert.show("Need 2 external displays")
		return
	end

	table.sort(externals, function(x, y)
		return x:frame().x < y:frame().x
	end)
	local currentLeft, currentRight = externals[1], externals[2]

	-- New order: built-in (if present), then swap of the two externals.
	local order = {}
	if builtIn then
		table.insert(order, builtIn)
	end
	table.insert(order, currentRight)
	table.insert(order, currentLeft)

	-- Snapshot widths before any mutation.
	local widths = {}
	for i, s in ipairs(order) do
		widths[i] = s:frame().w
	end

	-- Park non-primary screens far to the right first so subsequent placements
	-- never collide with a screen still occupying a target slot.
	local park = 100000
	for i = 2, #order do
		order[i]:setOrigin(park, 0)
		park = park + widths[i]
	end

	-- Anchor the first screen as primary; macOS forces it to (0, 0).
	order[1]:setPrimary()

	-- Chain-place each remaining screen at its target slot.
	local x = widths[1]
	for i = 2, #order do
		order[i]:setOrigin(x, 0)
		x = x + widths[i]
	end

	hs.alert.show("Swapped external displays")
end

hs.urlevent.bind("swapDisplays", function()
	swapExternalDisplays()
end)
-- END swap-displays
