local LinkButtonImpl = {}
local LinkButton = gdclass(nil, Button)
    :Permissions(Enum.Permissions.OS)
    :RegisterImpl(LinkButtonImpl)

export type LinkButton = Button & typeof(LinkButtonImpl) & {
    link: string,
}

LinkButton:RegisterProperty("link", Enum.VariantType.STRING)

function LinkButtonImpl._OnPressed(self: LinkButton)
    if self.link == "" then
        return
    end

    -- TODO: Link whitelist?
    assert(String.BeginsWith(self.link, "https://"), "invalid link")
    OS.singleton:ShellOpen(self.link)
end

LinkButton:RegisterMethod("_OnPressed")

function LinkButtonImpl._Ready(self: LinkButton)
    self.pressed:Connect(Callable.new(self, "_OnPressed"))
end

LinkButton:RegisterMethod("_Ready")

return LinkButton
