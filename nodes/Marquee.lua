--- @class
--- @extends Control
local Marquee = {}
local MarqueeC = gdclass(Marquee)

--- @classType Marquee
export type Marquee = Control & typeof(Marquee) & {
    --- @property
    --- @range 0 120
    --- @default 60.0
    scrollSpeed: number,

    text: Label,
}

function Marquee.SetText(self: Marquee, text: string)
    self.text.text = text
end

--- @registerMethod
function Marquee._Ready(self: Marquee)
    self.text = self:GetNode("Text") :: Label
end

--- @registerMethod
function Marquee._Process(self: Marquee, delta: number)
    self.text.size = self.text.customMinimumSize

    local oldPos = self.text.position
    local sizeX = self.text.size.x

    if sizeX > self.size.x then
        local newX = oldPos.x - self.scrollSpeed * delta
        if newX <= -sizeX then
            newX = self.size.x
        end

        self.text.position = Vector2.new(newX, oldPos.y)
    else
        self.text.position = Vector2.new(0, oldPos.y)
    end
end

return MarqueeC
