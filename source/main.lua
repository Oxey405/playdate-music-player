import 'CoreLibs/ui'
import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/animator'
import 'CoreLibs/math'
import 'CoreLibs/object'

import "scripts/parser.lua"
import "scripts/currentlyPlaying.lua"
import "scripts/FolderScanner.lua"
import "scripts/Playlist.lua"

local gfx <const> = playdate.graphics
local snd <const> = playdate.sound
Roobert = gfx.font.newFamily({
    [playdate.graphics.font.kVariantNormal] = "fonts/Roobert/Roobert-11-Medium",
    [playdate.graphics.font.kVariantBold] = "fonts/Roobert/Roobert-11-Bold",
    [playdate.graphics.font.kVariantItalic] = "fonts/Roobert/Roobert-11-Medium-Halved"
})

Icons = gfx.imagetable.new('images/icons')


local ticks_to_scoll <const> = 5

--- All the available tracks are stored here
Library = {
}

FilePlayer = snd.fileplayer.new()
Playing_song_index = 1

File_Browser = playdate.ui.gridview.new(300, 100)
File_Browser:setNumberOfColumns(1)
File_Browser:setNumberOfRows(#Library)
File_Browser:setCellPadding(50, 50, 4, 4)

function File_Browser:drawCell(section, row, column, selected, x, y, width, height)
    if selected then
        gfx.fillRoundRect(x, y, width, height, 10)
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
    else
        gfx.drawRoundRect(x, y, width, height, 10)
    end

    local song_info = Library[row]

    gfx.drawText(string.format("*%s*", song_info.title or song_info.filepath), x + 12, y + 8, Roobert)
    Icons:getImage(1):draw(x + 6, y + 30)
    gfx.drawText(song_info.album or "Unknown Album", x + 24, y + 30)
    Icons:getImage(3):draw(x + 6, y + 48)
    gfx.drawText(song_info.artist or "Unknwon Artist", x + 24, y + 48)
    local mins, secs = SecsToMinSecs(song_info.duration)
    Icons:getImage(4):draw(x + 6, y + 68)
    gfx.drawText(string.format("%02i:%02i - %s", mins, secs, song_info.year or "????"), x+24, y+68)
    gfx.drawText("▸ Ⓐ", x+width-42, y+height-24, Roobert)
end




local scroll_ticks = 0
local delta_tick = 0



playdate.datastore.write({}, "config", true)

if not playdate.file.exists('/Music') then
    playdate.file.mkdir('/Music')
end








function HandleLibraryBrowsing()
    if playdate.buttonJustPressed(playdate.kButtonUp) or delta_tick >= 1 then
        File_Browser:selectPreviousRow(true)
    end
    if playdate.buttonJustPressed(playdate.kButtonDown) or delta_tick <= -1 then
        File_Browser:selectNextRow(true)
    end    
    if playdate.buttonJustPressed(playdate.kButtonA) then
        Play_song()
    end
    if playdate.buttonJustPressed(playdate.kButtonB) then
        ToggleCurrentlyPlaying()
    end

    if playdate.buttonJustPressed(playdate.kButtonRight) then
        AddToPlaylist()
    end


end

function RewindPlayer()
    if FilePlayer:getRate() == 2 then
        FilePlayer:setRate(1)
        return
    end

    FilePlayer:setRate(0.5)
end

function FastForward()
    if FilePlayer:getRate() == 0.5 then
        FilePlayer:setRate(1)
        return
    end

    FilePlayer:setRate(2)
end

function HandleInputs()

    if not Currently_playing_opened then
        HandleLibraryBrowsing()
    else
        HandleCurrentlyPlayingInputs()
    end


end

function Play_song(from_playlist, force_interrupt)
    if Playing_song_index == File_Browser:getSelectedRow() and FilePlayer:isPlaying() then
        Playing_song_index = File_Browser:getSelectedRow()
        return
    end
    if not from_playlist then
        Playing_song_index = File_Browser:getSelectedRow()
    end
    local song = Library[Playing_song_index]
    FilePlayer:stop()
    FilePlayer = snd.fileplayer.new(song.fullpath)
    FilePlayer:load(song.fullpath)
    local success, error = FilePlayer:play()

    if success then
        OpenCurrentlyPlaying()
    end

    FilePlayer:setStopOnUnderrun(false)
    -- stop_fade:reset()
    -- should_stop = true

    FilePlayer:setFinishCallback(function ()
        if #Playlist ~= 0 and not force_interrupt then
            Playing_song_index = Playlist[1]
            table.remove(Playlist, 1)
            Playlist_browser:setNumberOfRows(#Playlist)
            Play_song(true)
        end 
    end)
end

function playdate.update()
    gfx.clear()
    playdate.drawFPS(0, 0)
    delta_tick = scroll_ticks - playdate.getCrankTicks(ticks_to_scoll)
    scroll_ticks = playdate.getCrankTicks(ticks_to_scoll)

    HandleInputs()

    gfx.pushContext()
        gfx.setFontFamily(Roobert)
        gfx.drawTextAligned("*Music Player*", 200, 0, kTextAlignment.center)
    gfx.popContext()
    File_Browser:drawInRect(0, 20, 400, 220)
    
    if Currently_playing_opened then
        DrawCurrentlyPlaying(Library[Playing_song_index])
    end

    playdate.timer.updateTimers()
end

List_files_recursively()
