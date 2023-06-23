--- @class
--- @extends Control
local KskLogo = {}
local KskLogoC = gdclass(KskLogo)

--- @classType KskLogo
export type KskLogo = Control & typeof(KskLogo) & {
    logoMat: ShaderMaterial,
    tween: Tween?,
}

local PROGRESS_PARAM = "shader_parameter/progress"
local TRANSITION_DURATION = 0.3

--- @registerMethod
function KskLogo._Ready(self: KskLogo)
    local logo = self:GetNode("Logo") :: ColorRect
    self.logoMat = assert(logo.material) :: ShaderMaterial

    logo.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    logo.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
end

function KskLogo.beginTween(self: KskLogo)
    return self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
end

--- @registerMethod
function KskLogo._OnMouseEntered(self: KskLogo)
    if self.tween then
        self.tween:Kill()
    end

    local tween = self:beginTween()
    tween:TweenProperty(self.logoMat, PROGRESS_PARAM, 1, TRANSITION_DURATION)
    self.tween = tween
end

--- @registerMethod
function KskLogo._OnMouseExited(self: KskLogo)
    if self.tween then
        self.tween:Kill()
    end

    local tween = self:beginTween()
    tween:TweenProperty(self.logoMat, PROGRESS_PARAM, 0, TRANSITION_DURATION)
    self.tween = tween
end

return KskLogoC
