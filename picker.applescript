on run
    set itemsFile to "/tmp/clipboard-picker-items.txt"
    set resultFile to "/tmp/clipboard-picker-result.txt"

    try
        set itemsContent to read POSIX file itemsFile as UTF8
    on error
        try
            set itemsContent to read POSIX file itemsFile
        on error errMsg
            return
        end try
    end try

    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to linefeed
    set itemList to text items of itemsContent
    set AppleScript's text item delimiters to oldDelims

    set cleanList to {}
    repeat with anItem in itemList
        if (anItem as text) is not "" then
            set end of cleanList to (anItem as text)
        end if
    end repeat

    if (count of cleanList) is 0 then
        activate
        display dialog "Historico de clipboard vazio." with title "Clipboard History" buttons {"OK"} default button "OK" with icon note
        return
    end if

    set pickerMode to item 1 of cleanList
    set displayItems to rest of cleanList

    if pickerMode is "paste" then
        set promptText to "Selecione um item para colar:"
        set okButton to "Colar"
    else
        set promptText to "Selecione um item para EXCLUIR:"
        set okButton to "Excluir"
    end if

    activate
    set chosen to choose from list displayItems with title "Clipboard History" with prompt promptText OK button name okButton cancel button name "Cancelar" default items {item 1 of displayItems}

    if chosen is false then
        do shell script "echo 'CANCEL' > " & quoted form of resultFile
    else
        do shell script "echo " & quoted form of (item 1 of chosen as text) & " > " & quoted form of resultFile
    end if
end run
