-- All UI below is actually for testing and showcase only, main thing to develop is UIOverflowBox, UIScrollBox and it's proper behaviour
-- Scrollbars, dropdowns, carousels can be implemented by developer on demand

function G.FUNCS.scrollbar(e)
	e.states.drag.can = true
	if G.CONTROLLER and G.CONTROLLER.dragging.target and (G.CONTROLLER.dragging.target == e) then
		local scrollbar_overflow = e.config.scrollbar_content
		local scrollbar_track = e.UIBox

		if not e.config.scroll_dir or e.config.scroll_dir == "w" then
			local percent = (G.CURSOR.T.x - e.parent.T.x - G.ROOM.T.x) / (scrollbar_overflow.T.w - e.T.w)
			percent = math.max(0, math.min(1, percent))
			scrollbar_overflow.scroll_progress.x = percent
			scrollbar_track.UIRoot.children[1].config.minw = percent * (scrollbar_overflow.T.w - e.T.w)
			scrollbar_track:recalculate()
		elseif e.config.scroll_dir == "h" then
			local percent = (G.CURSOR.T.y - e.parent.T.y - G.ROOM.T.y) / (scrollbar_overflow.T.h - e.T.h)
			percent = math.max(0, math.min(1, percent))
			scrollbar_overflow.scroll_progress.y = percent
			scrollbar_track.UIRoot.children[1].config.minh = percent * (scrollbar_overflow.T.h - e.T.h)
			scrollbar_track:recalculate()
		end
	end
end

--

function create_scrollbar(options)
	local scrollbar_content = UIScrollBox({
		definition = options.definition or {},
		config = {},
		overflow_config = {
			h = options.h,
			w = options.w,
			maxw = options.maxw,
			maxh = options.maxh,
			-- TODO: draw stencil properly, maybe?
			r = options.r,
		},
	})

	local scrollbar_track = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { colour = { 1, 1, 1, 0.3 }, r = 0.25 },
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
						scrollbar_content = scrollbar_content,
						scroll_dir = "w",

						id = "track_item",
						minh = 0.25,
						minw = 0.25,
						colour = G.C.MULT,
						r = 0,
						offset = {
							y = 0,
						},
					},
				},
			},
		},
		config = {},
	})
	local v_scrollbar_track = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { colour = { 1, 1, 1, 0.3 }, r = 0.25 },
			nodes = {
				{
					n = G.UIT.R,
					config = {
						minh = 0,
					},
				},
				{
					n = G.UIT.R,
					config = {
						collideable = true,
						func = "scrollbar",
						scrollbar_content = scrollbar_content,
						scroll_dir = "h",

						id = "track_item",
						minh = 0.25,
						maxh = 0.25,
						minw = 0.25,
						colour = G.C.MULT,
						r = 0,
						offset = {
							x = 0,
						},
					},
				},
			},
		},
		config = {},
	})

	return {
		n = G.UIT.R,
		nodes = {
			{
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
									object = scrollbar_content,
								},
							},
						},
					},
					{
						n = G.UIT.R,
						config = {
							align = "cm",
						},
						nodes = {},
					},
					{
						n = G.UIT.R,
						config = {
							-- align = "cm",
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
			},
			{
				n = G.UIT.C,
				nodes = {
					{
						n = G.UIT.O,
						config = {
							object = v_scrollbar_track,
						},
					},
				},
			},
		},
	}
end

-- Testing field

-- local test_card_area = CardArea(0, 0, G.CARD_W, G.CARD_H, {
-- 	highlight_limit = 0,
-- 	limit = 1,
-- 	type = "title",
-- })
-- local test_card = create_card("Jokers", test_card_area, nil, nil, nil, nil, "j_joker")
-- test_card_area:emplace(test_card)

-- local inner_scrollbar = create_scrollbar({
-- 	h = 2,
-- 	maxw = 5,
-- 	r = 0.25,
-- 	definition = {
-- 		n = G.UIT.ROOT,
-- 		config = { colour = G.C.CLEAR, instance_type = "NODE" },
-- 		nodes = {
-- 			{
-- 				n = G.UIT.R,
-- 				config = {
-- 					minh = 1,
-- 					minw = 10,
-- 					colour = G.C.CHIPS,
-- 				},
-- 				nodes = {
-- 					{
-- 						n = G.UIT.T,
-- 						config = {
-- 							colour = G.C.WHITE,
-- 							text = "A very long text hid",
-- 							scale = 0.5,
-- 						},
-- 						nodes = {},
-- 					},
-- 					{
-- 						n = G.UIT.O,
-- 						config = {
-- 							object = test_card_area,
-- 						},
-- 					},
-- 				},
-- 			},
-- 		},
-- 	},
-- })

local hand_card_area_2 = CardArea(0, 0, G.CARD_W * 5, G.CARD_H, {
	highlight_limit = 0,
	card_limit = 4,
	type = "title",
})
local hand_card_area = CardArea(0, 0, G.CARD_W * 5, G.CARD_H, {
	highlight_limit = 0,
	card_limit = 4,
	type = "title",
})

for i = 1, 8 do
	local test_card = create_card("Jokers", hand_card_area, nil, nil, nil, nil, "j_joker")
	hand_card_area:emplace(test_card)
	local test_card_2 = create_card("Jokers", hand_card_area_2, nil, nil, nil, nil, "j_joker")
	hand_card_area_2:emplace(test_card_2)
end

local hand_container = UIScrollBox({
	content = hand_card_area,
	progress = {
		y = 0.5,
		x = 0.5,
	},
	overflow = {
		config = {
			r = 0.25,
			maxh = 2,
			w = 10,
		},
	},
})
local hand_container_2 = UIScrollBox({
	content = hand_card_area_2,
	progress = {
		y = 0.5,
		x = 0.5,
	},
	overflow = {
		config = {
			r = 0.25,
			maxh = 2,
			w = 10,
		},
	},
})

local less_fun = function()
	local r = {}
	local lines = {
		"JOKERS",
		"MINIGAMES",
		"DECKS",
		"QUESTS",
		"VOUCHERS",
		"EXPLOSIONS",
		"SKIP TAGS",
		"CRASHES",
	}
	for i = 1, 2 do
		local rr = {}
		for _, line in ipairs(lines) do
			table.insert(rr, {
				n = G.UIT.C,
				config = { minw = 0.25 },
			})
			table.insert(rr, {
				n = G.UIT.C,
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = line,
							scale = 0.5,
							colour = G.C.MULT,
						},
					},
				},
			})
		end
		table.insert(r, {
			n = G.UIT.C,
			config = { id = i == 1 and "first_column" or nil },
			nodes = rr,
		})
	end
	return r
end
local top_line = UIScrollBox({
	content = {
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.CLEAR },
			nodes = less_fun(),
		},
		config = {},
	},
	overflow = {
		config = {
			w = 10,
		},
	},
	sync_mode = "offset",
	scroll_move = function(self, dt)
		if not self.text_size then
			local element = self:get_UIE_by_ID("first_column")
			self.text_size = element.T.w
		end
		self.scroll_offset.x = math.fmod((self.scroll_offset.x or 0) + dt * 1.5, self.text_size)
	end,
})

local no_fun = function()
	local r = {}
	for i = 1, 2 do
		local rr = {}
		for j = 1, 4 do
			table.insert(rr, {
				n = G.UIT.C,
				config = { minw = 0.25 },
			})
			table.insert(rr, {
				n = G.UIT.C,
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = "NO FUN ALLOWED",
							scale = 0.5,
							colour = G.C.MULT,
						},
					},
				},
			})
		end
		table.insert(r, {
			n = G.UIT.C,
			config = { id = i == 1 and "first_column" or nil },
			nodes = rr,
		})
	end
	return r
end
local bottom_line = UIScrollBox({
	content = {
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.CLEAR },
			nodes = no_fun(),
		},
		config = {},
	},
	overflow = {
		config = {
			w = 10,
		},
	},
	sync_mode = "offset",
	scroll_move = function(self, dt)
		if not self.text_size then
			local element = self:get_UIE_by_ID("first_column")
			self.text_size = element.T.w
		end
		self.scroll_offset.x = math.fmod((self.scroll_offset.x or 0) - dt * 1.5 + self.text_size, self.text_size)
	end,
})

return {
	n = G.UIT.ROOT,
	config = { align = "cm", padding = 0.1, colour = G.C.CLEAR },
	nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm", colour = { 0, 0, 0, 0.2 }, minw = 3, r = 0.25 },
			nodes = {
				{
					n = G.UIT.R,
					config = {
						r = 0.25,
					},
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = hand_container_2,
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{
							n = G.UIT.C,
							config = { r = 0.25, colour = { 0, 0, 0, 0.2 } },
							nodes = {
								{
									n = G.UIT.R,
									config = {
										colour = { 0, 0, 0, 0.2 },
									},
									nodes = {
										{
											n = G.UIT.O,
											config = {
												object = top_line,
											},
										},
									},
								},
								{ n = G.UIT.R, config = { minh = 0.1 } },
								{
									n = G.UIT.R,
									config = {
										align = "cm",
									},
									nodes = {
										{
											n = G.UIT.O,
											config = {
												object = DynaText({
													string = { "My Amazing Mod" },
													scale = 1,
													colours = { G.C.MONEY },
													shadow = true,
													bump = true,
													maxw = 6,
												}),
											},
										},
									},
								},
								{ n = G.UIT.R, config = { minh = 0.25 } },
								{
									n = G.UIT.R,
									config = {
										colour = { 0, 0, 0, 0.2 },
									},
									nodes = {
										{
											n = G.UIT.O,
											config = {
												object = bottom_line,
											},
										},
									},
								},
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = {
						r = 0.25,
					},
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = hand_container,
							},
						},
					},
				},
			},
		},
	},
}
