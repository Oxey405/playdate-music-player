local gfx <const> = playdate.graphics

Playlist = {
}

Playlist_browser = playdate.ui.gridview.new(300, 80)
Playlist_browser:setNumberOfColumns(1)
Playlist_browser:setNumberOfRows(#Playlist)
Playlist_browser:setCellPadding(4, 4, 4, 4)

function Playlist_browser:drawCell(section, row, column, selected, x, y, width, height)
    if selected then
        gfx.fillRoundRect(x, y, width, height, 10)
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
    else
        gfx.drawRoundRect(x, y, width, height, 10)
    end

    local song_info = Library[Playlist[row]]

    if song_info == nil then
        return
    end

    gfx.drawText(string.format("*%s*", song_info.title or song_info.filepath), x + 4, y + 8, gfx.getSystemFont())
    Icons:getImage(1):draw(x + 6, y + 24)
    gfx.drawText(string.sub(song_info.album, 1, 30) or "Unknown Album", x + 24, y + 24)
    Icons:getImage(3):draw(x + 6, y + 40)
    gfx.drawText(string.sub(song_info.artist, 1, 30) or "Unknwon Artist", x + 24, y + 40)
    local mins = song_info.duration // 60
    local secs = math.ceil(song_info.duration - (mins * 60))
    Icons:getImage(4):draw(x + 6, y + 58)
    gfx.drawText(string.format("%02i:%02i - %s", mins, secs, song_info.year or "????"), x+24, y+58)
    gfx.drawText("Ⓐ Skip here", x+width-116, y+56, Roobert)
end


function AddToPlaylist()
    table.insert(Playlist, File_Browser:getSelectedRow())
    Playlist_browser:setNumberOfRows(#Playlist)

    if not FilePlayer:isPlaying() then
        PlayNextPlaylistSong()
    end
    print(#Playlist)
    printTable(Playlist)
end

function PlayNextPlaylistSong()
    Playing_song_index = table.remove(Playlist, 1)
    Play_song(true, true)
end

function SkipToPlaylist()
    local playlist_jump_index = Playlist_browser:getSelectedRow()
    Playing_song_index = Playlist[playlist_jump_index]
    Play_song(true, true)
    -- Remove previous tracks - the current one we're gonna play because it's getting removed when we switch
    for i = 1, playlist_jump_index - 1, 1 do
        table.remove(Playlist, 1)
    end

    print(#Playlist)
    printTable(Playlist)

    if #Playlist > 0 then
        Playlist_browser:setNumberOfRows(#Playlist)
    end
end

