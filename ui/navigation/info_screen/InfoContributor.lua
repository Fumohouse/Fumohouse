--- @class
--- @extends Control
local InfoContributor = {}
local InfoContributorC = gdclass(InfoContributor)

export type InfoContributor = Control & typeof(InfoContributor) & {
    --- @property
    name: string,
    --- @property
    role: string,

    --- @property
    --- @multiline
    description: string,

    --- @property
    nameButton: LinkButton,
    --- @property
    roleText: Label,

    --- @property
    infoPopup: Window,
    --- @property
    infoTitle: Label,
    --- @property
    infoText: RichTextLabel,
}

--- @registerMethod
function InfoContributor._Ready(self: InfoContributor)
    self.nameButton.text = self.name
    self.roleText.text = self.role

    self.nameButton.pressed:Connect(Callable.new(self, "_OnLinkPressed"))
end

--- @registerMethod
function InfoContributor._OnLinkPressed(self: InfoContributor)
    self.infoPopup.size = Vector2i.new(500, 300)

    self.infoTitle.text = self.name
    self.infoText.text = self.description

    self.infoPopup.visible = true
end

return InfoContributorC
