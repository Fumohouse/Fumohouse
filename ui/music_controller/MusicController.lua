local Marquee = require("../../nodes/Marquee")
local Song = require("../../music/Song")

local MusicPlayerM = require("../../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MusicControllerImpl = {}
local MusicController = gdclass(nil, Control)
    :RegisterImpl(MusicControllerImpl)

type MusicControllerT = {
    marquee: Marquee.Marquee,
    playButton: TextureButton,
    seekBar: HSlider,

    wasPaused: boolean,
    isSeeking: boolean,
}

export type MusicController = Control & MusicControllerT & typeof(MusicControllerImpl)

local playIcon = assert(load("res://assets/textures/ui/icons/play-fill.svg")) :: Texture2D
local pauseIcon = assert(load("res://assets/textures/ui/icons/pause-fill.svg")) :: Texture2D

function MusicControllerImpl.updatePaused(self: MusicController)
    local isPaused = MusicPlayer.streamPaused

    self.playButton.textureNormal = if isPaused then playIcon else pauseIcon
    self.wasPaused = isPaused
end

function MusicControllerImpl.updateSong(self: MusicController, song: Song.Song?)
    if song then
        local artistName = if song.artist.nameUnicode == "" then song.artist.nameRomanized else song.artist.nameUnicode
        local songName = if song.nameUnicode == "" then song.nameRomanized else song.nameUnicode
        self.marquee:SetText(`{artistName} - {songName}`)
    else
        self.marquee:SetText("<no song playing>")
    end
end

MusicController:RegisterMethod("updateSong")
    :Args({ name = "song", type = Enum.VariantType.OBJECT, hint = Enum.PropertyHint.RESOURCE_TYPE, hintString = "Song" })

function MusicControllerImpl._OnPrevNext(self: MusicController, advanceBy: integer)
    MusicPlayer:AdvancePlaylist(advanceBy)
end

MusicController:RegisterMethodAST("_OnPrevNext")

function MusicControllerImpl._Ready(self: MusicController)
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

    self:updateSong(nil)
    MusicPlayer.songChanged:Connect(Callable.new(self, "updateSong"))
end

MusicController:RegisterMethod("_Ready")

function MusicControllerImpl._OnPlayPressed(self: MusicController)
    MusicPlayer.streamPaused = not MusicPlayer.streamPaused
    self:updatePaused()
end

MusicController:RegisterMethod("_OnPlayPressed")

function MusicControllerImpl._OnSeekStarted(self: MusicController)
    self.isSeeking = true
end

MusicController:RegisterMethod("_OnSeekStarted")

function MusicControllerImpl._OnSeekEnded(self: MusicController, changed: boolean)
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

MusicController:RegisterMethodAST("_OnSeekEnded")

function MusicControllerImpl._Process(self: MusicController, delta: number)
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

MusicController:RegisterMethodAST("_Process")

return MusicController
