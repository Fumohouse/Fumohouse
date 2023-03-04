local Utils = {
    stageColor = Color.FromHsv(203 / 360, 1, 0.7),
    stageName = "Prototype",
    stageAbbrev = "PRO",
    version = "2023/03/01",
}

function Utils.GetBuildString()
    return `{Utils.stageName} {Utils.version}`
end

-- https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
function Utils.LerpWeight(delta: number, factor: number?)
    local factorA = if factor == nil then 5e-6 else factor
    return 1 - factorA ^ delta
end

return Utils
