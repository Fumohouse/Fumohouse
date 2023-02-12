local Utils = {}

function Utils.GetBuildString()
	return "Prototype Stage"
end

-- https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
function Utils.LerpWeight(delta: number, factor: number?)
    local factorA = if factor == nil then 5e-6 else factor
    return 1 - factorA ^ delta
end

return Utils
