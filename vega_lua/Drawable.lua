require "Vector2"
--[[
--- A drawable node. Create your own instance with the "new" function.
-- The coordinates are from the top/left to the bottom/right. All transforms
-- are relative to the parent node.
-- @field position a Vector2 with the position of the Drawable.
-- @field size a Vector2 with the size of the Drawable, it is (1, 1) by default.
-- @field origin the origin pivot, it is (0, 0) by default.
-- @field scale the scale, it is (1, 1) by default.
-- @field childrenorigin the origin point of the children, relative to the origin pivot. It is (0, 0) by default.
-- @field rotation the rotation.
-- @field visibility the visibility, where 0 is full transparent and 1 is full opaque. It is 1 by default.
-- @field isrelativex set to true to make the x coordinate of the position relative to the size of the parent.
-- @field isrelativey set to true to make the y coordinate of the position relative to the size of the parent.
-- @field isrelativewidth set to true to make the x coordinate of the size relative to the size of the parent.
-- @field isrelativeheigth set to true to make the y coordinate of the size relative to the size of the parent.
-- @field isrelativeoriginx set to true to make the x coordinate of the origin relative to the size of the Drawable.
-- @field isrelativeoriginy set to true to make the y coordinate of the origin relative to the size of the Drawable.
-- @field children the children list. Please do not modify this list. Use the addchild and removechild functions instead.
-- @field parent the parent Drawable. It is nil until this Drawable is added to another Drawable with the addchild function.
Drawable = {
	position = Vector2.zero,
	size = Vector2.one,
	origin = Vector2.zero,
	scale = Vector2.one,
	childrenorigin = Vector2.zero,
	rotation = 0,
	visibility = 1,
	isrelativex = false,
	isrelativey = false,
	isrelativewidth = false,
	isrelativeheigth = false,
	isrelativeoriginx = false,
	isrelativeoriginy = false,
	children = {}
}

--- Creates a new instance of the Drawable.
-- @param o the new table, can be nil.
function Drawable:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o;
end

--- Returns the position, relative to the parent size.
-- @return a Vector2 with the relative position.
function Drawable:getrelativeposition()
	Vector2 rp = Vector2.new(self.position)
	if (self.parent) then
		if not isrelativex then rp.x = self.position.x / self.parent:getabsolutesize().x end
		if not isrelativey then rp.y = self.position.y / self.parent:getabsolutesize().y end
	end
	return rp
end

--- Returns the size, relative to the parent size.
-- @return a Vector2 with the relative size.
function Drawable:getrelativesize()
	Vector2 rs = Vector2.new(self.size)
	if (self.parent) then
		if not isrelativewidth then rs.x = self.size.x / self.parent:getabsolutesize().x end
		if not isrelativeheigth then rs.y = self.size.y / self.parent:getabsolutesize().y end
	end
	return rs
end

--- Returns the origin, relative to the size.
-- @return a Vector2 with the relative origin.
function Drawable:getrelativeorigin()
	Vector2 ro = Vector2.new(self.origin)
	if not isrelativeoriginx then ro.x = self.origin.x / self:getabsolutesize().x end
	if not isrelativeoriginy then ro.y = self.origin.y / self:getabsolutesize().y end
	return ro
end

--- Returns the absolute position (useful if isrelativepositionx or isrelativepositiony is true).
-- @return a Vector2 with the absolute position.
function Drawable:getabsoluteposition()
	Vector2 ap = Vector2.new(self.position)
	if (self.parent) then
		if isrelativex then ap.x = self.position.x * self.parent:getabsolutesize().x end
		if isrelativey then ap.y = self.position.y * self.parent:getabsolutesize().y end
	end
	return ap
end

--- Returns the absolute size (useful if isrelativewidth or isrelativeheigth is true).
-- @return a Vector2 with the absolute position.
function Drawable:getabsolutesize()
	Vector2 as = Vector2.new(self.size)
	if (self.parent) then
		if isrelativewidth then as.x = self.size.x * self.parent:getabsolutesize().x end
		if isrelativeheigth then as.y = self.size.y * self.parent:getabsolutesize().y end
	end
	return as
end

--- Returns the absolute origin (useful if isrelativeoriginx or isrelativeoriginy is true).
-- @return a Vector2 with the absolute origin.
function Drawable:getabsoluteorigin()
	Vector2 ao = Vector2.new(self.origin)
	if isrelativeoriginx then ao.x = self.origin.x * self:getabsolutesize().x end
	if isrelativeoriginy then ao.y = self.origin.y * self:getabsolutesize().y end
	return ao
end

function Drawable:getmatrix()
end

function Drawable:getglobalmatrix()
end

--- Adds the child to the end of the children list. It does nothing if the parent of the
-- object is already a child of this Drawable. If the Drawable is child of another Drawable,
-- it is first removed from the current parent.
-- @param child the Drawable to add.
function Drawable:addchild(child)
	self:insertchildat(child, #children)
end

--- Same of addchild, but the child can be added at any index of the children list.
-- @param child the Drawable to add.
-- @param index the index. If less than 1, then the child is added in the index 1. If greater than
-- list size, then the child is added in the end of the list.
function Drawable:insertchildat(child, index)
	if type(child) ~= "table" then error "The child argument of insertchildat function must be a table." end
	if type(index) ~= "number" then error "The index argument of insertchildat function must be a number." end
	if index < 1 then index = 1 end
	if index > #self.children + 1 then index = #self.children + 1 end
	if child.parent ~= self then
		if (child.parent) then child.parent:removechild(child) end
		self.children[index] = child
		child.parent = self
	end
end

--- Removes the child from the children list.
-- @param child the child to be removed.
function Drawable:removechild(child)
	if child and child.parent == self then
		for key, value in ipair(self.children) do
			if (value == child) then
				table.remove(self.children, key)
				break
			end
		end
	end
end

--- Removes this Drawable from its parent.
function Drawable:removefromparent()
	if self.parent then self.parent:removechild(self) end
end
]]--
