---Extracts ID3 Metadata from a File
---@param file _File
---@param filepath string
function Extract_id3_metadata(file, filepath)
    local metadata =  {
        title = "",
        artist = "Unknown artist",
        album = "Unknown album",
        year = "????",
        comments = "",
        genreID = 0
    }
    file:seek(-128, playdate.file.kSeekFromEnd)
    if file:read(3) ~= "TAG" then -- Expect the ID3 header "TAG"
        metadata.title = string.match(filepath, '(.+)%.mp3')
        return metadata
    end

    metadata.title = trim_str(file:read(30))
    metadata.artist = trim_str(file:read(30))
    metadata.album = trim_str(file:read(30))
    metadata.year = file:read(4)
    metadata.comments = trim_str(file:read(30))
    -- print(file:read(1))
    -- metadata.genreID = 0

    return metadata
end

function trim_str(buffer)
    local null_pos = buffer:find("\0")  -- Find first null character
    if null_pos then
        return buffer:sub(1, null_pos - 1)  -- Return substring before null
    end
    return buffer  -- Return original if no nulls found
end


function SecsToMinSecs(duration)
    local mins = duration // 60
    local secs = math.ceil(duration % 60)
    return mins, secs
end