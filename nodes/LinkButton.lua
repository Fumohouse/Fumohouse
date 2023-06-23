--- @class
--- @extends Button
--- @permissions OS
local LinkButton = {}
local LinkButtonC = gdclass(LinkButton)

--- @classType LinkButton
export type LinkButton = Button & typeof(LinkButton) & {
    --- @property
    link: string,
}

--- @registerMethod
function LinkButton._OnPressed(self: LinkButton)
    if self.link == "" then
        return
    end

    -- TODO: Link whitelist?
    assert(String.BeginsWith(self.link, "https://"), "invalid link")
    OS.singleton:ShellOpen(self.link)
end

--- @registerMethod
function LinkButton._Ready(self: LinkButton)
    self.pressed:Connect(Callable.new(self, "_OnPressed"))
end

return LinkButtonC
