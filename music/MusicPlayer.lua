local Song = require("Song")
local Playlist = require("Playlist")

--- @class
--- @extends AudioStreamPlayer
local MusicPlayer  = {}
local MusicPlayerC = gdclass(MusicPlayer)

type PlaylistPosition = {
    position: number,
    time: number,
}

export type MusicPlayer = AudioStreamPlayer & typeof(MusicPlayer) & {
    --- @signal
    songChanged: SignalWithArgs<(song: Song.Song) -> ()>,

    playlists: {[string]: Playlist.Playlist},
    currentSong: Song.Song?,
    currentPlaylist: string,

    playlistPosition: number,
    savedPositions: {[string]: PlaylistPosition},

    volume: number,
    tween: Tween?,
}

MusicPlayer.BUS = "Music"

function MusicPlayer._Init(self: MusicPlayer)
    self.playlists = {}
    self.currentPlaylist = ""
    self.savedPositions = {}
end

--- @registerMethod
function MusicPlayer._Ready(self: MusicPlayer)
    self.bus = MusicPlayer.BUS
    self.finished:Connect(Callable.new(self, "_OnFinished"))
    self.volume = self.volumeDb
end

function MusicPlayer.resetClip(self: MusicPlayer)
    self:Stop()
    self.stream = nil

    self.currentSong = nil
    self.songChanged:Emit(nil)
end

function MusicPlayer.playImmediate(self: MusicPlayer, song: Song.Song, seek: number)
    local wasPaused = self.streamPaused

    if self.currentSong and song.id == self.currentSong.id then
        self:Play(seek)
        self.streamPaused = wasPaused
        return
    end

    self:resetClip()

    local stream = load(song.path) :: AudioStream?
    assert(stream, `Failed to load audio stream: {song.path}`)

    self.stream = stream
    self:Play(seek)
    self.streamPaused = wasPaused

    self.currentSong = song

    self.songChanged:Emit(song)
end

function MusicPlayer.play(self: MusicPlayer, song: Song.Song, transitionOut: boolean, transitionIn: boolean, seek: number)
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

    if not wait_signal(tween1.finished) then
        return
    end

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

function MusicPlayer.savePlaylistState(self: MusicPlayer)
    if self.currentPlaylist ~= "" then
        self.savedPositions[self.currentPlaylist] = {
            position = self.playlistPosition,
            time = self:GetPlaybackPosition(),
        }
    end
end

function MusicPlayer.continuePlaylist(self: MusicPlayer, playlistId: string)
    local position = self.savedPositions[playlistId]
    local playlist = self.playlists[playlistId]

    if position then
        self.playlistPosition = position.position

        coroutine.wrap(function()
            self:play(playlist.songs:Get(self.playlistPosition) :: Song.Song, true, true, position.time)
        end)()
    else
        self.playlistPosition = 0

        coroutine.wrap(function()
            self:play(playlist.songs:Get(0) :: Song.Song, true, false, 0)
        end)()
    end

    self.currentPlaylist = playlistId
end

function MusicPlayer.SwitchPlaylist(self: MusicPlayer, playlistId: string)
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

function MusicPlayer.AdvancePlaylist(self: MusicPlayer, steps: number)
    if steps == 0 or self.currentPlaylist == "" then
        return
    end

    local playlist = self.playlists[self.currentPlaylist]

    self.playlistPosition += steps

    if self.playlistPosition >= playlist.songs:Size() then
        self.playlistPosition -= playlist.songs:Size()
    elseif self.playlistPosition < 0 then
        self.playlistPosition += playlist.songs:Size()
    end

    self:play(playlist.songs:Get(self.playlistPosition) :: Song.Song, false, false, 0)
end

function MusicPlayer.LoadPlaylists(self: MusicPlayer, playlists: TypedArray<Playlist.Playlist>)
    self:SwitchPlaylist("")

    table.clear(self.playlists)
    table.clear(self.savedPositions)

    for _, playlist: Playlist.Playlist in playlists do
        assert(not self.playlists[playlist.id], `A playlist with id {playlist.id} already exists.`)
        self.playlists[playlist.id] = playlist
    end
end

--- @registerMethod
function MusicPlayer._OnFinished(self: MusicPlayer)
    self:AdvancePlaylist(1)
end

return MusicPlayerC
