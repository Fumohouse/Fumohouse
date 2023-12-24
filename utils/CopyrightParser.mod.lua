local CopyrightParser = {}

export type CopyrightLicense = {
    id: string,
    text: string,
}

export type CopyrightFiles = {
    files: string,
    comment: string,
    copyright: string,
    license: string,
}

export type CopyrightFile = {
    files: {CopyrightFiles},
    licenses: {[string]: CopyrightLicense},
}

function CopyrightParser.Parse(text: string)
    local copyrightFile: CopyrightFile = {
        files = {},
        licenses = {},
    }

    local currentFiles: CopyrightFiles?
    local currentLicense: CopyrightLicense?

    local currentField: string?
    local currentString: string?

    local function pushField()
        if currentString then
            if currentFiles then
                if currentField == "Files" then
                    currentFiles.files = currentString
                elseif currentField == "Comment" then
                    currentFiles.comment = currentString
                elseif currentField == "Copyright" then
                    currentFiles.copyright = currentString
                elseif currentField == "License" then
                    currentFiles.license = currentString
                end
            elseif currentLicense then
                if currentField == "License" then
                    currentLicense.text = currentString
                end
            end
        end
    end

    local function pushCurrent()
        if currentFiles then
            table.insert(copyrightFile.files, currentFiles)
            currentFiles = nil
        elseif currentLicense then
            copyrightFile.licenses[currentLicense.id] = currentLicense
            currentLicense = nil
        end
    end

    for line in string.gmatch(text, "([^\r\n]*)\r?\n?") do
        local stripped = String.StripEdges(line)
        if #stripped == 0 or string.sub(stripped, 1, 1) == "#" then
            continue
        end

        if string.sub(line, 1, 1) == " " then
            if not currentString then
                continue
            end

            if stripped == "." then
                currentString ..= "\n\n"
                continue
            end

            if #currentString > 0 then
                if currentField == "Files" then
                    currentString ..= ", "
                elseif currentField == "Copyright" then
                    currentString ..= "\n"
                elseif string.sub(currentString, -1) ~= "\n" then
                    currentString ..= " "
                end
            end

            currentString ..= stripped
        else
            local i = string.find(stripped, ":")
            if not i then
                continue
            end

            pushField()

            local field = string.sub(stripped, 1, i - 1)
            local value = String.StripEdges(string.sub(stripped, i + 1))

            if field == "Files" then
                pushCurrent()
                currentFiles = {
                    files = "",
                    comment = "",
                    copyright = "",
                    license = "",
                }

                currentString = value
            elseif field == "License" and (not currentFiles or currentFiles.license ~= "") then
                pushCurrent()
                currentLicense = {
                    id = value,
                    text = "",
                }

                currentString = ""
            else
                currentString = value
            end

            currentField = field
        end
    end

    pushField()
    pushCurrent()

    return copyrightFile
end

return CopyrightParser
