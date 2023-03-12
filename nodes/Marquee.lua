local MarqueeImpl = {}
local Marquee = gdclass(nil, Control)
    :RegisterImpl(MarqueeImpl)

type MarqueeT = {
    scrollSpeed: number,

    text: Label,
}

export type Marquee = Control & MarqueeT & typeof(MarqueeImpl)

Marquee:RegisterProperty("scrollSpeed", Enum.VariantType.FLOAT)
    :Range(0, 120)
    :Default(60)

function MarqueeImpl.SetText(self: Marquee, text: string)
    self.text.text = text
end

function MarqueeImpl._Ready(self: Marquee)
    self.text = self:GetNode("Text") :: Label
end

Marquee:RegisterMethod("_Ready")

function MarqueeImpl._Process(self: Marquee, delta: number)
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

Marquee:RegisterMethodAST("_Process")

return Marquee
