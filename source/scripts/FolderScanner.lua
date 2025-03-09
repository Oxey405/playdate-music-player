local snd <const> = playdate.sound

local base_folder = '/Music'

function List_files_recursively(subfolder)
    local folder = subfolder or base_folder
    print("exploring " .. folder)
    local in_folder = playdate.file.listFiles(folder)
    for _, filepath in ipairs(in_folder) do

        local fullpath = folder .. "/" .. filepath
        print(fullpath)

        if playdate.file.isdir(fullpath) then
            List_files_recursively(fullpath)
        end
        if filepath:match('.%.mp3') == nil then
            goto continue
        end

        local file = playdate.file.open(fullpath, playdate.file.kFileRead)
        assert(file ~= nil, "Unexpected error when reading directory")
        
        local metadata = Extract_id3_metadata(file, filepath)
        local track = {
            filename = filepath,
            fullpath = fullpath,
            duration = snd.fileplayer.new(fullpath):getLength()
        }

        if metadata ~= nil then
            for key, value in pairs(metadata) do
                track[key] = value
            end
        end

        table.insert(Library, track)
        ::continue::
    end

    File_Browser:setNumberOfRows(#Library)

end
