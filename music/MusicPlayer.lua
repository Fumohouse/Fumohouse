local Song = require("Song")
local Playlist = require("Playlist")

local MusicPlayerImpl = {}
local MusicPlayer = gdclass(nil, AudioStreamPlayer)
    :RegisterImpl(MusicPlayerImpl)

type PlaylistPosition = {
    position: number,
    time: number,
}

type MusicPlayerT = {
    songChanged: Signal,

    playlists: {[string]: Playlist.Playlist},
    currentSong: Song.Song?,
    currentPlaylist: string,

    playlistPosition: number,
    savedPositions: {[string]: PlaylistPosition},

    volume: number,
    tween: Tween?,
}

export type MusicPlayer = AudioStreamPlayer & MusicPlayerT & typeof(MusicPlayerImpl)

MusicPlayer:RegisterSignal("songChanged")
    :Args({ name = "song", type = Enum.VariantType.OBJECT, hint = Enum.PropertyHint.RESOURCE_TYPE, hintString = "Song" })

MusicPlayerImpl.BUS = "Music"

function MusicPlayerImpl._Init(obj: AudioStreamPlayer, tbl: MusicPlayerT)
    tbl.playlists = {}
    tbl.currentPlaylist = ""
    tbl.savedPositions = {}
end

function MusicPlayerImpl._Ready(self: MusicPlayer)
    self.bus = MusicPlayer.BUS
    self.finished:Connect(Callable.new(self, "_OnFinished"))
    self.volume = self.volumeDb
end

MusicPlayer:RegisterMethod("_Ready")

function MusicPlayerImpl.resetClip(self: MusicPlayer)
    self:Stop()
    self.stream = nil

    self.currentSong = nil
    self.songChanged:Emit(nil)
end

function MusicPlayerImpl.playImmediate(self: MusicPlayer, song: Song.Song, seek: number)
    if self.currentSong and song.id == self.currentSong.id then
        self:Play(seek)
        return
    end

    local wasPaused = self.streamPaused
    self:resetClip()

    local stream = load(song.path) :: AudioStream?
    assert(stream, `Failed to load audio stream: {song.path}`)

    self.stream = stream
    self:Play(seek)
    self.streamPaused = wasPaused

    self.currentSong = song

    self.songChanged:Emit(song)
end

function MusicPlayerImpl.play(self: MusicPlayer, song: Song.Song, transitionOut: boolean, transitionIn: boolean, seek: number)
    if not transitionOut then
        self:playImmediate(song, seek)
        return
    end

    local TRANSITION_DURATION = 0.5

    -- Some funny business with tweens and yielding behavior
    if self.tween then
        self.tween:Kill()
    end

    local tween1 = self:CreateTween()
    tween1:TweenProperty(self, "volume_db", -100, TRANSITION_DURATION)

    self.tween = tween1

    wait_signal(tween1.finished)

    if transitionIn then
        if self.tween and tween1 ~= self.tween then
            self.tween:Kill()
        end

        local tween2 = self:CreateTween()
        tween2:TweenProperty(self, "volume_db", self.volume, TRANSITION_DURATION)

        self.tween = tween2
    else
        self.volumeDb = self.volume
    end

    self:playImmediate(song, seek)
end

function MusicPlayerImpl.savePlaylistState(self: MusicPlayer)
    if self.currentPlaylist ~= "" then
        self.savedPositions[self.currentPlaylist] = {
            position = self.playlistPosition,
            time = self:GetPlaybackPosition(),
        }
    end
end

function MusicPlayerImpl.continuePlaylist(self: MusicPlayer, playlistId: string)
    local position = self.savedPositions[playlistId]
    local playlist = self.playlists[playlistId]

    if position then
        self.playlistPosition = position.position

        coroutine.wrap(function()
            MusicPlayer.play(self, playlist.songs:Get(self.playlistPosition) :: Song.Song, true, true, position.time)
        end)()
    else
        self.playlistPosition = 1

        coroutine.wrap(function()
            MusicPlayer.play(self, playlist.songs:Get(1) :: Song.Song, true, false, 0)
        end)()
    end

    self.currentPlaylist = playlistId
end

function MusicPlayerImpl.SwitchPlaylist(self: MusicPlayer, playlistId: string)
    if self.currentPlaylist == playlistId then
        return
    end

    if self.currentPlaylist ~= "" then
        self:savePlaylistState()
    end

    if playlistId == "" then
        self:resetClip()
        self.currentPlaylist = ""
        return
    end

    self:continuePlaylist(playlistId)
end

function MusicPlayerImpl.AdvancePlaylist(self: MusicPlayer, steps: number)
    if steps == 0 then
        return
    end

    local playlist = self.playlists[self.currentPlaylist]

    self.playlistPosition += steps

    if self.playlistPosition > playlist.songs:Size() then
        self.playlistPosition -= playlist.songs:Size()
    elseif self.playlistPosition < 1 then
        self.playlistPosition += playlist.songs:Size()
    end

    coroutine.wrap(function()
        MusicPlayer.play(self, playlist.songs:Get(self.playlistPosition) :: Song.Song, false, false, 0)
    end)()
end

function MusicPlayerImpl.LoadPlaylists(self: MusicPlayer, playlists: TypedArray<Playlist.Playlist>)
    self:SwitchPlaylist("")

    table.clear(self.playlists)
    table.clear(self.savedPositions)

    for _, playlist: Playlist.Playlist in playlists do
        assert(not self.playlists[playlist.id], `A playlist with id {playlist.id} already exists.`)
        self.playlists[playlist.id] = playlist
    end
end

function MusicPlayerImpl._OnFinished(self: MusicPlayer)
    self:AdvancePlaylist(1)
end

MusicPlayer:RegisterMethod("_OnFinished")

return MusicPlayer
