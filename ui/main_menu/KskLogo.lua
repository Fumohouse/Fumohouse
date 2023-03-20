local KskLogoImpl = {}
local KskLogo = gdclass(nil, Control)
    :RegisterImpl(KskLogoImpl)

export type KskLogo = Control & typeof(KskLogoImpl) & {
    logoMat: ShaderMaterial,
    tween: Tween?,
}

local PROGRESS_PARAM = "shader_parameter/progress"
local TRANSITION_DURATION = 0.3

function KskLogoImpl._Ready(self: KskLogo)
    local logo = self:GetNode("Logo") :: ColorRect
    self.logoMat = assert(logo.material) :: ShaderMaterial

    logo.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    logo.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
end

KskLogo:RegisterMethod("_Ready")

function KskLogoImpl.beginTween(self: KskLogo)
    return self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
end

function KskLogoImpl._OnMouseEntered(self: KskLogo)
    if self.tween then
        self.tween:Kill()
    end

    local tween = self:beginTween()
    tween:TweenProperty(self.logoMat, PROGRESS_PARAM, 1, TRANSITION_DURATION)
    self.tween = tween
end

KskLogo:RegisterMethod("_OnMouseEntered")

function KskLogoImpl._OnMouseExited(self: KskLogo)
    if self.tween then
        self.tween:Kill()
    end

    local tween = self:beginTween()
    tween:TweenProperty(self.logoMat, PROGRESS_PARAM, 0, TRANSITION_DURATION)
    self.tween = tween
end

KskLogo:RegisterMethod("_OnMouseExited")

return KskLogo
