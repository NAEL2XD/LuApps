local oldCopied = ""
local oldMadeCopied = ""

function create()
    oldCopied = clipboardItem
    oldMadeCopied = clipboardItem
    make()
end

function update(elapsed)
    if clipboardItem ~= oldMadeCopied then
        make()
        oldMadeCopied = clipboardItem
    end

    if keyPressed("SPACE") then
        setClipboardText("Hello, world!")
    elseif keyPressed("ENTER") then
        setClipboardText(oldCopied)
        exit()
    end
end

function make()
    clearConsole()

    print("Currently Copied Clipboard: " .. clipboardItem)
    print("Press SPACE to set the copied clipboard to \"Hello, World!\"")
    print("Press ENTER to leave the application and storing back the old copied clipboard.")
    print("Note that it does not support copying system files.")
end