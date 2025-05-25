-- Since element is not ready yet, use DebugPlus for developing it
-- watch config_tab Mods/BalatroScrollbar/ui.lua

UIOverflowBox = UIBox:extend()

function UIOverflowBox:init(args)
	UIBox.init(self, args)
end
function UIOverflowBox:draw(...)
	if self.FRAME.DRAW >= G.FRAMES.DRAW and not G.OVERLAY_TUTORIAL then
		return
	end
	self.FRAME.DRAW = G.FRAMES.DRAW

	for k, v in pairs(self.children) do
		if k ~= "h_popup" and k ~= "alert" then
			v:draw()
		end
	end

	if self.states.visible then
		add_to_drawhash(self)
		self.UIRoot:draw_self()

		love.graphics.stencil(function()
			prep_draw(self, 1)
			love.graphics.scale(1 / G.TILESIZE)
			-- TODO: border-radius
			love.graphics.rectangle("fill", 0, 0, self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE)
			love.graphics.pop()
		end, "replace", 1)
		love.graphics.setStencilTest("greater", 0)

		self.UIRoot:draw_children()
		for k, v in ipairs(self.draw_layers) do
			if v.draw_self then
				v:draw_self()
			else
				v:draw()
			end
			if v.draw_children then
				v:draw_children()
			end
		end

		love.graphics.setStencilTest()
	end

	if self.children.alert then
		self.children.alert:draw()
	end

	self:draw_boundingrect()
end
-- TODO: fix maxh = h, maxw = w
function UIOverflowBox:calculate_xywh(node, _T, recalculate, _scale)
	local x, y = UIBox.calculate_xywh(self, node, _T, recalculate, _scale)
	return self.config.w or math.min(x, self.config.maxw), self.config.h or math.max(y, self.config.maxh)
end

--

function G.FUNCS.scrollbar(e)
	e.states.drag.can = true
	if G.CONTROLLER and G.CONTROLLER.dragging.target and (G.CONTROLLER.dragging.target == e) then
		local scrollbar_overflow = e.config.scrollbar_overflow
		local scrollbar_content = e.config.scrollbar_content
		local scrollbar_track = e.config.scrollbar_track

		local percent = ((G.CURSOR.T.x - e.parent.T.x - G.ROOM.T.x) / e.T.w) / (scrollbar_content.T.w - 2 * e.T.w)
		percent = math.max(0, math.min(1, percent))

		local max_value = scrollbar_content.T.w - scrollbar_overflow.T.w
		local new_value = max_value * percent
		scrollbar_content.config.offset.x = -new_value
		scrollbar_track.UIRoot.children[1].config.minw = percent * (scrollbar_overflow.T.w - e.T.w)
		scrollbar_overflow:recalculate()
		scrollbar_track:recalculate()
	end
end

--

function create_scrollbar(options)
	local scrollbar_content = UIBox({
		definition = options.definition or {},
		config = {
			align = "cm",
			offset = { x = 0, y = 0 },
		},
	})
	local scrollbar_overflow = UIOverflowBox({
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = scrollbar_content,
					},
				},
			},
		},
		config = {
			maxh = options.maxh,
			maxw = options.maxw,
			h = options.h,
			w = options.w,
		},
	})

	local scrollbar_track = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.UI.BACKGROUND_BLACK, minw = options.w, w = options.w },
			nodes = {
				{
					n = G.UIT.C,
					config = {
						minw = 0,
					},
				},
				{
					n = G.UIT.C,
					config = {
						collideable = true,
						func = "scrollbar",
						scrollbar_overflow = scrollbar_overflow,
						scrollbar_content = scrollbar_content,

						id = "track_item",
						minh = 0.25,
						minw = 0.25,
						colour = G.C.MULT,
						-- align = "bm",
						r = 0,
						offset = {
							x = 5,
							y = 0,
						},
					},
				},
			},
		},
		config = {},
	})
	scrollbar_track.definition.nodes[2].config.scrollbar_track = scrollbar_track

	return {
		n = G.UIT.C,
		config = {},
		nodes = {
			{
				n = G.UIT.R,
				config = {
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.O,
						config = {
							object = scrollbar_overflow,
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = {
					align = "cm",
					padding = 0.05,
				},
				nodes = {},
			},
			{
				n = G.UIT.R,
				config = {
					-- align = "cm",
					padding = 0.05,
				},
				nodes = {
					{
						n = G.UIT.O,
						config = {
							object = scrollbar_track,
						},
					},
				},
			},
		},
	}
end

-- Testing field

local test_card_area = CardArea(0, 0, G.CARD_W, G.CARD_H, {
	highlight_limit = 0,
	limit = 1,
	type = "title",
})
local test_card = create_card("Jokers", test_card_area, nil, nil, nil, nil, "j_joker")
test_card_area:emplace(test_card)

return {
	n = G.UIT.ROOT,
	config = { align = "cm", padding = 0.1, colour = G.C.CLEAR },
	nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm", padding = 0.1, r = 0.1, colour = G.C.BLACK, minw = 3 },
			nodes = {
				create_scrollbar({
					definition = {
						n = G.UIT.ROOT,
						config = { colour = G.C.CLEAR, instance_type = "NODE" },
						nodes = {
							{
								n = G.UIT.R,
								config = {
									minh = 1,
									minw = 20,
									r = 0.1,
									colour = G.C.MULT,
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											colour = G.C.WHITE,
											text = "A very long text hid",
											scale = 0.5,
										},
										nodes = {},
									},
									{
										n = G.UIT.O,
										config = {
											object = test_card_area,
										},
									},
								},
							},
						},
					},
					h = 3,
					w = 5,
				}),
			},
		},
	},
}
