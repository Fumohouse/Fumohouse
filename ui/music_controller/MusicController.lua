local Marquee = require("../../nodes/Marquee")
local Song = require("../../music/Song")
local MenuUtils = require("../navigation/MenuUtils.mod")

local MusicPlayerM = require("../../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

--- @class
--- @extends Control
local MusicController = {}
local MusicControllerC = gdclass(MusicController)

--- @classType MusicController
export type MusicController = Control & typeof(MusicController) & {
    marquee: Marquee.Marquee,
    playButton: TextureButton,
    seekBar: HSlider,

    wasPaused: boolean,
    isSeeking: boolean,

    tween: Tween?,
}

local playIcon = assert(load("res://assets/textures/ui/icons/play-fill.svg")) :: Texture2D
local pauseIcon = assert(load("res://assets/textures/ui/icons/pause-fill.svg")) :: Texture2D

function MusicController.updatePaused(self: MusicController)
    local isPaused = MusicPlayer.streamPaused

    self.playButton.textureNormal = if isPaused then playIcon else pauseIcon
    self.wasPaused = isPaused
end

--- @registerMethod
function MusicController.updateSong(self: MusicController, song: Song.Song?)
    if song then
        local artistName = if song.artist.nameUnicode == "" then song.artist.nameRomanized else song.artist.nameUnicode
        local songName = if song.nameUnicode == "" then song.nameRomanized else song.nameUnicode
        self.marquee:SetText(`{artistName} - {songName}`)
    else
        self.marquee:SetText("<no song playing>")
    end
end

--- @registerMethod
function MusicController._OnPrevNext(self: MusicController, advanceBy: integer)
    MusicPlayer:AdvancePlaylist(advanceBy)
end

--- @registerMethod
function MusicController._Ready(self: MusicController)
    self.marquee = self:GetNode("%Marquee") :: Marquee.Marquee
    self.playButton = self:GetNode("%PlayPause") :: TextureButton
    self.seekBar = self:GetNode("%SeekBar") :: HSlider

    self.playButton.pressed:Connect(Callable.new(self, "_OnPlayPressed"))
    self.seekBar.dragStarted:Connect(Callable.new(self, "_OnSeekStarted"))
    self.seekBar.dragEnded:Connect(Callable.new(self, "_OnSeekEnded"))

    local onPrevNext = Callable.new(self, "_OnPrevNext")

    local prevButton = self:GetNode("%Previous") :: TextureButton
    prevButton.pressed:Connect(onPrevNext:Bind(-1))

    local nextButton = self:GetNode("%Next") :: TextureButton
    nextButton.pressed:Connect(onPrevNext:Bind(1))

    self.wasPaused = MusicPlayer.streamPaused
    self:updatePaused()

    self:updateSong(MusicPlayer.currentSong)
    MusicPlayer.songChanged:Connect(Callable.new(self, "updateSong"))
end

--- @registerMethod
function MusicController._OnPlayPressed(self: MusicController)
    MusicPlayer.streamPaused = not MusicPlayer.streamPaused
    self:updatePaused()
end

--- @registerMethod
function MusicController._OnSeekStarted(self: MusicController)
    self.isSeeking = true
end

--- @registerMethod
function MusicController._OnSeekEnded(self: MusicController, changed: boolean)
    if MusicPlayer.stream then
        -- HACK: Seek does nothing when paused
        local wasPaused = MusicPlayer.streamPaused
        MusicPlayer.streamPaused = false

        -- math.min: prevent loop when seeking to 1
        MusicPlayer:Seek(MusicPlayer.stream:GetLength() * math.min(self.seekBar.value, 0.999))

        MusicPlayer.streamPaused = wasPaused
    else
        self.seekBar.value = 0
    end

    self.isSeeking = false
end

--- @registerMethod
function MusicController._Process(self: MusicController, delta: number)
    if MusicPlayer.streamPaused ~= self.wasPaused then
        self:updatePaused()
    end

    if MusicPlayer.stream then
        if not self.isSeeking then
            self.seekBar.value = MusicPlayer:GetPlaybackPosition() / MusicPlayer.stream:GetLength()
        end
    else
        self.seekBar.value = 0
    end
end

function MusicController.Hide(self: MusicController)
    self.scale = Vector2.new(0, 1)
    self.visible = false
end

function MusicController.Transition(self: MusicController, vis: boolean)
    if self.tween then
        self.tween:Kill()
    end

    self.visible = true

    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)

    tween:TweenProperty(self, "scale", if vis then Vector2.ONE else Vector2.new(0, 1), MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION)

    self.tween = tween

    coroutine.wrap(function()
        if not vis and wait_signal(tween.finished) then
            self.visible = false
        end
    end)()
end

return MusicControllerC
