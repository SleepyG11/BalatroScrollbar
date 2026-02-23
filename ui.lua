--

-- All UI below is actually for testing and showcase only, main thing to develop is UIOverflowBox and it's proper behaviour
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
	r = 0.25,
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
				inner_scrollbar,
			},
		},
	},
}
