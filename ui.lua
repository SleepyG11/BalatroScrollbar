local StencilStack = Object:extend()

function StencilStack:new()
	self.level = 0
	self.stack = {}
end
function StencilStack:prepare()
	self.level = 0
	self.stack = {}
	love.graphics.setStencilTest()
end
function StencilStack:push(stencil_fn)
	local parent = self.level
	local child = parent + 1

	love.graphics.setStencilTest("equal", parent)
	love.graphics.stencil(function()
		stencil_fn(false)
	end, "increment", 1, true)
	love.graphics.setStencilTest("equal", child)

	self.level = child
	self.stack[#self.stack + 1] = stencil_fn
end
function StencilStack:pop()
	local stencil_fn = self.stack[#self.stack]
	if not stencil_fn then
		return
	end

	local child = self.level
	local parent = child - 1

	love.graphics.setStencilTest("equal", child)
	love.graphics.stencil(function()
		stencil_fn(true)
	end, "decrement", 1, true)

	self.stack[#self.stack] = nil
	self.level = parent

	love.graphics.setStencilTest("equal", parent)
end

local stack = StencilStack()

-- Since element is not ready yet, use DebugPlus for developing it
-- watch config_tab Mods/BalatroScrollbar/ui.lua

UIOverflowBox = UIBox:extend()

function UIOverflowBox:init(args)
	self.__id = args.id
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

	UIBox.init(self, args)

	self.h_percent = 0
	self.v_percent = 0
end
function UIOverflowBox:update(dt)
	UIBox.update(self, dt)
	self.h_percent = math.max(0, math.min(1, self.h_percent))
	self.v_percent = math.max(0, math.min(1, self.v_percent))
	self.content.config.offset.x = -1 * (self.content.T.w - self.T.w) * self.h_percent
	self.content.config.offset.y = -1 * (self.content.T.h - self.T.h) * self.v_percent
end
function UIOverflowBox:move(...)
	if not self.FRAME then
		print("NOT INITIALIZED", self.__id)
	end
	UIBox.move(self, ...)
end
function UIOverflowBox:draw(...)
	-- UIBox.draw(self, ...)
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
		stack:push(function(exit)
			local self = self.UIRoot
			prep_draw(self, 1)
			love.graphics.scale(1 / G.TILESIZE)
			love.graphics.setColor(0, 0, 0, 1)
			if self.config.r and self.VT.w > 0.01 then
				self:draw_pixellated_rect("fill", 0)
			else
				love.graphics.rectangle("fill", 0, 0, self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE)
			end
			love.graphics.pop()
		end)
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
		stack:pop()
	end

	if self.children.alert then
		self.children.alert:draw()
	end

	self:draw_boundingrect()
end
-- TODO: fix maxh = h, maxw = w
function UIOverflowBox:calculate_xywh(node, _T, recalculate, _scale)
	local x, y = UIBox.calculate_xywh(self, node, _T, recalculate, _scale)
	return self.config.w or math.min(x, self.config.maxw or math.huge),
		self.config.h or math.max(y, self.config.maxh or math.huge)
end

function Node:inside_overflow_boundaries(point)
	if self.overflow_check_timer == G.TIMERS.REAL then
		return self.ARGS.overflow_check_result
	end
	self.overflow_check_timer = G.TIMERS.REAL
	local element = self
	while element.parent do
		element = element.parent
		if element:is(UIOverflowBox) and not Node.collides_with_point(element, point) then
			self.ARGS.overflow_check_result = false
			return false
		end
	end
	self.ARGS.overflow_check_result = true
	return true
end

if not G.love_draw_ref then
	G.love_draw_ref = love.draw
end

function love.draw(...)
	stack:prepare()
	G.love_draw_ref(...)
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
	local scrollbar_content = UIOverflowBox({
		id = "inner",
		definition = options.definition or {},
		config = {
			h = options.h,
			w = options.w,
			r = options.r,
		},
	})
	local scrollbar_overflow = UIOverflowBox({
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
	w = 3,
	definition = {
		n = G.UIT.ROOT,
		config = { colour = G.C.CLEAR, instance_type = "NODE" },
		nodes = {
			{
				n = G.UIT.R,
				config = {
					minh = 1,
					minw = 20,
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
					h = 3,
					w = 5,
					r = 0.5,
					definition = {
						n = G.UIT.ROOT,
						config = { colour = G.C.CLEAR, instance_type = "NODE" },
						nodes = {
							{
								n = G.UIT.R,
								config = {
									minh = 1,
									minw = 20,
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
