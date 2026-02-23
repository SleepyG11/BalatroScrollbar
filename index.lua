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

local old_love_draw = love.draw
function love.draw(...)
	stack:prepare()
	return old_love_draw(...)
end

---

-- Overflow UIBox, element which limits maximum size of content inside of it and if it exceeds, crop it and prevent any colliding events on it
UIOverflowBox = UIBox:extend()
function UIOverflowBox:init(args, ...)
	UIBox.init(self, args, ...)
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
-- Logic for calculating proper box size made via patch

---

-- Collision check
function Node:inside_overflow_boundaries(point)
	if self.overflow_check_timer == G.TIMERS.REAL then
		return self.ARGS.overflow_check_result or false
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
