-- Stencil stack, to keep track of overflow containers inside of each other and render then properly
StencilStack = Object:extend()

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

---

-- Overflow UIBox, element which limits maximum size of content inside of it and if it exceeds, crop it and prevent any colliding events on it
-- Logic for calculating proper box size made via patch
-- TODO: check scale and outline
UIOverflowBox = UIBox:extend()
function UIOverflowBox:init(args)
	UIBox.init(self, args)
end
function UIOverflowBox:draw()
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
		-- Draw a stencil which will crop overflow; add it to a stack
		-- It fully replicates position, scale, rotation and border-rarius (`r` property)
		stack:push(function(exit)
			local root = self.UIRoot
			prep_draw(root, 1)
			love.graphics.scale(1 / G.TILESIZE)
			love.graphics.setColor(0, 0, 0, 1)
			if self.config.r and root.VT.w > 0.01 then
				root:draw_pixellated_rect("fill", 0)
			else
				love.graphics.rectangle("fill", 0, 0, root.VT.w * G.TILESIZE, root.VT.h * G.TILESIZE)
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

---

-- UIbox which uses UIOverflowBox box to render content with ability to move visible content area to imitate scrollbars
-- Both directions have own progress 0-1 which dictates how content aligned, where 0 is top/left edge and 1 is bottom/right edge
-- UIScrollBox does NOT renders actual scrollbar tracks, since progress can be dictated by various things such as: cursor position, time, events, etc.
-- So developer need render and handle controls for this element manually, if needed
UIScrollBox = UIOverflowBox:extend()
function UIScrollBox:init(args)
	self.scroll_progress = { x = 0, y = 0 }
	self.scroll_offset = { x = 0, y = 0 }

	self.content = UIBox(args)
	self.content_container = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = self.content,
					},
				},
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 0 },
		},
	})

	args.scroll_config = args.scroll_config or {}
	self.scroll_progress = args.scroll_config.progress or {}

	UIOverflowBox.init(self, {
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = self.content_container,
					},
				},
			},
		},
		config = args.overflow_config or {},
	})
end
-- Returns distance content overflows in both directions
function UIScrollBox:get_scroll_distance()
	return math.max(0, self.content_container.T.w - self.T.w), math.max(0, self.content_container.T.h - self.T.h)
end
-- Update offset to match progress
function UIScrollBox:update_scroll_offset()
	local dx, dy = self:get_scroll_distance()
	self.scroll_offset.x = dx * (self.scroll_progress.x or 0)
	self.scroll_offset.y = dy * (self.scroll_progress.y or 0)
end
-- Update progress to match offset
function UIScrollBox:update_scroll_progress()
	local dx, dy = self:get_scroll_distance()
	self.scroll_progress.x = (dx == 0 and 0) or ((self.offset.x or 0) / dx)
	self.scroll_progress.y = (dy == 0 and 0) or ((self.offset.y or 0) / dy)
end
-- Set new value for offset table
function UIScrollBox:set_scroll_offset(t)
	self.scroll_offset = t or {}
	self:update_scroll_progress()
end
-- Set new value for progress table
function UIScrollBox:set_scroll_progress(t)
	self.scroll_progress = t or {}
	self:update_scroll_offset()
end
-- Update offset according to progress and set offset every frame
function UIScrollBox:update_scroll()
	self:update_scroll_offset()
	self.content_container.config.offset.x = -(self.scroll_offset.x or 0)
	self.content_container.config.offset.y = -(self.scroll_offset.y or 0)
end

function UIScrollBox:update(dt)
	self:update_scroll()
	UIOverflowBox.update(self, dt)
end

---

-- Reetting stencil stack
local old_love_draw = love.draw
function love.draw(...)
	stack:prepare()
	return old_love_draw(...)
end
-- Collision check
function Node:inside_overflow_boundaries(point)
	if self.overflow_check_timer == G.TIMERS.REAL then
		return self.ARGS.overflow_check_result or false
	end
	self.overflow_check_timer = G.TIMERS.REAL
	local element = self
	while element.parent do
		element = element.parent
		if element.is and element:is(UIOverflowBox) and not Node.collides_with_point(element, point) then
			self.ARGS.overflow_check_result = false
			return false
		end
	end
	self.ARGS.overflow_check_result = true
	return true
end
