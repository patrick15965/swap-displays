-- BEGIN swap-displays
-- Swap the arrangement of the two external displays.
function swapExternalDisplays()
	local screens = hs.screen.allScreens()
	local externals = {}
	for _, s in ipairs(screens) do
		if s ~= hs.screen.primaryScreen() or #screens == 2 then
			table.insert(externals, s)
		end
	end

	if #externals < 2 then
		externals = screens
	end
	if #externals < 2 then
		hs.alert.show("Need at least 2 displays")
		return
	end

	local a, b = externals[1], externals[2]
	local ax, ay = a:frame().x, a:frame().y
	local bx, by = b:frame().x, b:frame().y

	a:setOrigin(bx, by)
	b:setOrigin(ax, ay)

	hs.alert.show("Swapped displays")
end

hs.urlevent.bind("swapDisplays", function()
	swapExternalDisplays()
end)
-- END swap-displays
