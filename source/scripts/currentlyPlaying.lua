local gfx <const> = playdate.graphics

local hidden_y = 400
local shown_y = -100

local expand_y = -360
local expand_scroll = 0

local transition_time = 250


local currently_playing_rectangle = playdate.geometry.rect.new(20, 160, 360, 600)

Currently_playing_opened = false
Currently_playing_expanded = false

local currently_playing_animator = gfx.animator.new(transition_time, hidden_y, shown_y, playdate.easingFunctions.inOutQuad)
currently_playing_animator:currentValue()

function ToggleCurrentlyPlaying()
    if Currently_playing_opened then
        currently_playing_animator = gfx.animator.new(transition_time, currently_playing_animator:currentValue(), hidden_y, playdate.easingFunctions.inOutQuad)
        currently_playing_animator:reset()
        playdate.timer.performAfterDelay(transition_time, function ()
            Currently_playing_opened = false
            Currently_playing_expanded = false
        end)
    else
        currently_playing_animator = gfx.animator.new(transition_time, currently_playing_animator:currentValue(), shown_y, playdate.easingFunctions.inOutQuad)
        currently_playing_animator:reset()
        Currently_playing_opened = true
    end

end

function OpenCurrentlyPlaying()
    Currently_playing_opened = true
    Currently_playing_expanded = false
    currently_playing_animator = gfx.animator.new(transition_time, currently_playing_animator:currentValue(), shown_y, playdate.easingFunctions.inOutQuad)
    currently_playing_animator:reset()
end


function ExpandCurrentlyPlaying()
    if Currently_playing_expanded then
        return
    end
    Currently_playing_expanded = true
    expand_scroll = 0
    currently_playing_animator = gfx.animator.new(transition_time, currently_playing_animator:currentValue(), expand_y, playdate.easingFunctions.inOutQuad)
    currently_playing_animator:reset()

    Playlist_browser:setSelectedRow(1)
end

function RetractCurrentlyPlaying(byCrank)
    if not byCrank and Currently_playing_expanded and expand_scroll ~= 0 then
        return
    end
    Currently_playing_expanded = false
    currently_playing_animator = gfx.animator.new(transition_time, currently_playing_animator:currentValue(), shown_y, playdate.easingFunctions.inOutQuad)
    currently_playing_animator:reset()
end

function ScrollCurrentlyPlayingBy(factor)

    if currently_playing_animator:ended() then
        expand_scroll = 0
    end

    
    if not Currently_playing_expanded and factor >= 30 then
        ExpandCurrentlyPlaying()
    end 

    if factor <= -30 and Currently_playing_expanded then
        RetractCurrentlyPlaying(true)
    end

    expand_scroll = math.max(math.min(expand_scroll, 400), 0)
end

function HandleCurrentlyPlayingInputs()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        if Currently_playing_expanded then
            SkipToPlaylist()
            return
        end

        if FilePlayer:isPlaying() then
            FilePlayer:pause()
        else
            FilePlayer:play()
        end
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        ToggleCurrentlyPlaying()
    end

    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        RewindPlayer()
    end

    if playdate.buttonJustPressed(playdate.kButtonRight) then
        FastForward()
    end

    if playdate.buttonJustPressed(playdate.kButtonDown) then
        ExpandCurrentlyPlaying()
    end

    if playdate.buttonJustPressed(playdate.kButtonUp) then
        if Playlist_browser:getSelectedRow() == 1 then
            RetractCurrentlyPlaying()
            return
        end
        Playlist_browser:selectPreviousRow(true)
    end

    if playdate.buttonJustPressed(playdate.kButtonDown) then
        if not currently_playing_animator:ended() then
            return
        end
        Playlist_browser:selectNextRow(true)

    end

    ScrollCurrentlyPlayingBy(playdate.getCrankChange())
    

end

local true_scroll = 0


function DrawCurrentlyPlaying(playingSongInfo)
    gfx.pushContext()
        true_scroll = expand_scroll
        if not Currently_playing_expanded then
            true_scroll = 0
        end
        gfx.setDrawOffset(0, currently_playing_animator:currentValue() - true_scroll)
        -- Container
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(currently_playing_rectangle, 10)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(3)
        gfx.drawRoundRect(currently_playing_rectangle, 10)

        -- Track information
        gfx.pushContext()
            gfx.setFontFamily(Roobert)
            gfx.drawTextAligned(string.format("*%s*", playingSongInfo.title), 200, 170, kTextAlignment.center)
        gfx.popContext()

        Icons:getImage(1):draw(50, 200)
        gfx.drawText(playingSongInfo.album or "Unknown album", 74, 200)
        Icons:getImage(3):draw(50, 220)
        gfx.drawText(playingSongInfo.artist or "Unknwon artist", 74, 220)
        Icons:getImage(4):draw(50, 240)
        gfx.drawText(string.format("%s",playingSongInfo.year or "????"), 74, 240)


        -- Button prompts
        gfx.drawText("Ⓐ", 100, 270)
        if FilePlayer:isPlaying() then
            Icons:getImage(5):draw(120, 271)
        else
            Icons:getImage(6):draw(120, 271)
        end

        gfx.drawText("Ⓑ", 140, 270)
        Icons:getImage(10):draw(160, 271)

        gfx.drawText("🎣", 180, 270)
        Icons:getImage(11):draw(200, 271)

        gfx.drawText("⬅️", 220, 270)
        Icons:getImage(9):draw(240, 272)

        gfx.drawText("➡️", 260, 270)
        Icons:getImage(8):draw(280, 272)
        -- Progress bar

        gfx.setLineWidth(2)
        gfx.drawRoundRect(100, 300, 200, 20, 10)
        
        local progress = FilePlayer:getOffset() / FilePlayer:getLength()
        gfx.fillRoundRect(100, 300, 5 + progress * 195, 20, 10)
        local playedMins, playedSecs = SecsToMinSecs(FilePlayer:getOffset())
        local totalMins, totalSecs = SecsToMinSecs(playingSongInfo.duration)
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.drawTextAligned(string.format("%02i:%02i / %02i:%02i", playedMins, playedSecs, totalMins, totalSecs), 200, 302, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        -- Upcoming in the Playlist

        if not Currently_playing_expanded and currently_playing_animator:ended() then
            return
        end

        gfx.pushContext()
            gfx.setFontFamily(Roobert)
            gfx.drawTextAligned("*Playlist*", 200, 360, kTextAlignment.center)
        gfx.popContext()


        if #Playlist > 0 then
            Playlist_browser:drawInRect(50, 380, 350, 220)
        end


    gfx.popContext()
end