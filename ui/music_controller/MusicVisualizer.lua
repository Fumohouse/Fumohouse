local MusicPlayerM = require("../../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MusicVisualizerImpl = {}
local MusicVisualizer = gdclass(nil, Control)
    :Permissions(Enum.Permissions.INTERNAL)
    :RegisterImpl(MusicVisualizerImpl)

type MusicVisualizerT = {
    curve: Curve2D,
    spectrum: AudioEffectSpectrumAnalyzerInstance,
    histogram: {number},
}

export type MusicVisualizer = Control & MusicVisualizerT & typeof(MusicVisualizerImpl)

local POINTS = 25

local FREQ_LOW = 10
local FREQ_HIGH = 15000

local RANGE_LEN = (FREQ_HIGH - FREQ_LOW) / POINTS

local MIN_DB = -70
local MAX_DB = 50

function MusicVisualizerImpl._Ready(self: MusicVisualizer)
    self.curve = Curve2D.new()

    local bus = AudioServer.GetSingleton():GetBusIndex(MusicPlayerM.BUS)
    assert(bus >= 0)
    self.spectrum = assert(AudioServer.GetSingleton():GetBusEffectInstance(bus, 0)) :: AudioEffectSpectrumAnalyzerInstance

    self.histogram = {}
    for i = 1, POINTS do
        self.histogram[i] = 0
    end
end

MusicVisualizer:RegisterMethod("_Ready")

function MusicVisualizerImpl._Process(self: MusicVisualizer, delta: number)
    for i = 1, POINTS do
        local factor = 0

        if MusicPlayer.playing then
            local freqLow = FREQ_LOW + RANGE_LEN * (i - 1)
            local freqHigh = freqLow + RANGE_LEN

            local magnitude = self.spectrum:GetMagnitudeForFrequencyRange(freqLow, freqHigh):Length()
            factor = math.clamp(
                (linear_to_db(magnitude) - MIN_DB) / (MAX_DB - MIN_DB), 0, 1
            )
        end

        local smoothingFactor = if factor == 0 then 0.1 else 0.7
        self.histogram[i] = factor * smoothingFactor + self.histogram[i] * (1 - smoothingFactor)
    end

    self:QueueRedraw()
end

MusicVisualizer:RegisterMethodAST("_Process")

function MusicVisualizerImpl.getPoint(self: MusicVisualizer, i: number)
    local factor = math.max(self.histogram[i], 0.01)
    return Vector2.new((i - 1) / POINTS * self.size.x, self.size.y - factor * self.size.y)
end

function MusicVisualizerImpl._Draw(self: MusicVisualizer)
    self.curve:ClearPoints()

    local ctlOffset = Vector2.new(5, 0)

    for i = 1, POINTS do
        local vertex = self:getPoint(i)

        self.curve:AddPoint(
            vertex,
            -ctlOffset,
            ctlOffset
        )
    end

    local points = self.curve:Tessellate()
    points:PushBack(Vector2.new(self.size.x, self.size.y))
    points:PushBack(Vector2.new(0, self.size.y))

    self:DrawColoredPolygon(points, Color.WHITE)
end

MusicVisualizer:RegisterMethod("_Draw")

return MusicVisualizer
