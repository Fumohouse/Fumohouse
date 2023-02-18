local AutosizeRichTextImpl = {}
local AutosizeRichText = gdclass("AutosizeRichText", RichTextLabel)
    :RegisterImpl(AutosizeRichTextImpl)

export type AutosizeRichText = RichTextLabel

function AutosizeRichTextImpl._Ready(self: AutosizeRichText)
    self.finished:Connect(Callable.new(self, "_OnFinishedLoading"))
end

AutosizeRichText:RegisterMethod("_Ready")

function AutosizeRichTextImpl._OnFinishedLoading(self: AutosizeRichText)
    self.customMinimumSize = Vector2.new(
        self:GetContentWidth(),
        self:GetContentHeight()
    )
end

AutosizeRichText:RegisterMethod("_OnFinishedLoading")

return AutosizeRichText
