local LinkButtonImpl = {}
local LinkButton = gdclass(nil, Button)
    :Permissions(Enum.Permissions.OS)
    :RegisterImpl(LinkButtonImpl)

type LinkButtonT = {
    link: string,
}

export type LinkButton = Button & LinkButtonT & typeof(LinkButtonImpl)

LinkButton:RegisterProperty("link", Enum.VariantType.STRING)

function LinkButtonImpl._OnPressed(self: LinkButton)
    if self.link == "" then
        return
    end

    -- TODO: Link whitelist?
    assert(strext.startswith(self.link, "https://"), "invalid link")
    OS.GetSingleton():ShellOpen(self.link)
end

LinkButton:RegisterMethod("_OnPressed")

function LinkButtonImpl._Ready(self: LinkButton)
    self.pressed:Connect(Callable.new(self, "_OnPressed"))
end

LinkButton:RegisterMethod("_Ready")

return LinkButton
