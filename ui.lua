-- This element is custom which can be built over UIOverflowBox
-- It will not be part of SMODS PR (probably)

UIScrollBox = UIOverflowBox:extend()
function UIScrollBox:init(args)
	self.content = UIBox({
		definition = args.definition or {},
		config = {
			align = "cm",
			offset = { x = 0, y = 0 },
		},
	})

	args.definition = {
		n = G.UIT.ROOT,
		config = { colour = G.C.CLEAR, r = args.config.r },
		nodes = {
			{
				n = G.UIT.O,
				config = {
					object = self.content,
				},
			},
		},
	}

	UIOverflowBox.init(self, args)

	self.h_percent = 0
	self.v_percent = 0
end
function UIScrollBox:update(dt)
	UIOverflowBox.update(self, dt)
	self.h_percent = math.max(0, math.min(1, self.h_percent))
	self.v_percent = math.max(0, math.min(1, self.v_percent))
	self.content.config.offset.x = -1 * (self.content.T.w - self.T.w) * self.h_percent
	self.content.config.offset.y = -1 * (self.content.T.h - self.T.h) * self.v_percent
end

--

-- All UI below is actually for testing and showcase only, main thing to develop is UIOverflowBox and it's proper behaviour
-- Scrollbars, dropdowns, carousels can be implemented by developer on demand

function G.FUNCS.scrollbar(e)
	e.states.drag.can = true
	if G.CONTROLLER and G.CONTROLLER.dragging.target and (G.CONTROLLER.dragging.target == e) then
		local scrollbar_overflow = e.config.scrollbar_content
		local scrollbar_content = scrollbar_overflow.content
		local scrollbar_track = e.config.scrollbar_track

		local percent = ((G.CURSOR.T.x - e.parent.T.x - G.ROOM.T.x) / e.T.w) / (scrollbar_content.T.w - 2 * e.T.w)
		percent = math.max(0, math.min(1, percent))
		scrollbar_overflow.h_percent = percent
		scrollbar_track.UIRoot.children[1].config.minw = percent * (scrollbar_overflow.T.w - e.T.w)
		scrollbar_track:recalculate()
	end
end

--

function create_scrollbar(options)
	local scrollbar_content = UIScrollBox({
		id = "inner",
		definition = options.definition or {},
		config = {
			h = options.h,
			w = options.w,
			r = options.r,
			maxw = options.maxw,
			maxh = options.maxh,
		},
	})
	local scrollbar_overflow = UIScrollBox({
		id = "outer",
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
			h = options.h,
			w = options.w,
			-- TODO: this one doesnt work (idk why), needs to be fixed
			maxh = options.maxh,
			maxw = options.maxw,
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

local inner_scrollbar = create_scrollbar({
	h = 2,
	maxw = 5,
	definition = {
		n = G.UIT.ROOT,
		config = { colour = G.C.CLEAR, instance_type = "NODE" },
		nodes = {
			{
				n = G.UIT.R,
				config = {
					minh = 1,
					minw = 10,
					colour = G.C.CHIPS,
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
})

return {
	n = G.UIT.ROOT,
	config = { align = "cm", padding = 0.1, colour = G.C.CLEAR },
	nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm", padding = 0.1, colour = G.C.BLACK, minw = 3 },
			nodes = {
				create_scrollbar({
					r = 0.5,
					maxw = 10,
					definition = {
						n = G.UIT.ROOT,
						config = { colour = G.C.CLEAR, instance_type = "NODE" },
						nodes = {
							{
								n = G.UIT.R,
								config = {
									minh = 1,
									minw = 11,
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
											object = UIBox({
												definition = {
													n = G.UIT.ROOT,
													config = { colour = G.C.CLEAR },
													nodes = {
														inner_scrollbar,
													},
												},
												config = {},
											}),
										},
									},
								},
							},
						},
					},
				}),
			},
		},
	},
}
