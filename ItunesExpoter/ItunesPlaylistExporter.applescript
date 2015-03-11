-- This script will extract selected playlist from iTunes and will place them in a 
-- separate m3u file. There are options to replace path string and path separator.

set playlistNames to {}
set playlistKeyValue to {}
set selectKeyValue to {}
set resultRows to {}
set pathStr to ""
set replacementPathStr to ""
set replaceSlash to false
tell application "iTunes"
	repeat with playlistObj in playlists
		set plName to name of playlistObj
		set end of playlistNames to plName
		set end of playlistKeyValue to {pName:plName}
	end repeat
	--choose file
	set selectedPlaylistNames to choose from list playlistNames with multiple selections allowed
	repeat with selectedName in selectedPlaylistNames
		set plist to playlist (selectedName as string)
		set ptracks to get every track of plist
		set psongs to {}
		repeat with ptrack in ptracks
			set pName to name of ptrack
			set partist to artist of ptrack
			set pduration to round ((duration of ptrack) as integer)
			set plocation to POSIX path of (get location of ptrack as text)
			set end of psongs to {_artist:partist, _name:pName, _duration:pduration, _location:plocation}
		end repeat
		set end of resultRows to {plistname:selectedName, lst:psongs}
	end repeat
end tell

-- set replacement path string
set dialogRt to (display dialog "Place the path string that need to be removed from exported playlist's music file path or leave it empty." default answer "")
if button returned of dialogRt is "Ok" then
	set pathStr to text returned of dialogRt
	set dialogRt2 to (display dialog "Place the replacement path string for path '" & pathStr & "' or leave it empty." buttons {"Don't Replace", "Replace"} default answer "")
	if button returned of dialogRt2 is "Replace" then
		set replacementPathStr to text returned of dialogRt2
	end if
end if

--Replace / with \
set replaceSlashRt to (display dialog "Do you want to replace path separator '/' with '\\'?" buttons {"No", "Yes"})
if button returned of replaceSlashRt is "Yes" then
	set replaceSlash to true
end if


--output folder
set outputFolder to choose folder with prompt "Select playlist output folder"

--iterate through results containing playlist & song attributes
repeat with row in resultRows
	--create file
	--set folderPath to POSIX file (outputFolder)
	set fhld to createFile(outputFolder, (plistname of row as string) & ".m3u", true)
	set songList to lst of row
	writeToFile(fhld, "#EXTM3U", true)
	repeat with song in songList
		writeToFile(fhld, ("#EXTINF:" & (_duration of song) as string) & "," & _name of song & " - " & _artist of song, true)
		set strFrm to replaceString(_location of song, pathStr, replacementPathStr)
		if replaceSlash then
			writeToFile(fhld, replaceString(strFrm, "/", "\\"), true)
		else
			writeToFile(fhld, strFrm, true)
		end if
	end repeat
end repeat
log (count of selectKeyValue)

--create new file
on createFile(folderPath, fileName, createNew)
	tell application "Finder"
		try
			set filepath to (POSIX file ((POSIX path of folderPath) & fileName)) as alias
			if createNew then
				log "deleting file"
				delete filepath
			else
				return filepath
			end if
		on error number -1700
			log "doesnt"
		end try
		make new file at folderPath with properties {name:fileName}
	end tell
	return (POSIX file ((POSIX path of folderPath) & fileName)) as alias
end createFile

--write file content
on writeToFile(filepath, content, isNewLine)
	log "write to file"
	set openFileHdl to open for access filepath with write permission
	if isNewLine then
		write content & (ASCII character 10) to openFileHdl starting at eof
	else
		write content to openFileHdl starting at eof
	end if
	close access the openFileHdl
end writeToFile

-- replace string
on replaceString(maintext, searchStr, replaceStr)
	if length of maintext > 0 then
		set AppleScript's text item delimiters to the searchStr
		set the item_list to every text item of maintext
		set AppleScript's text item delimiters to the replaceStr
		set maintext to the item_list as string
		set AppleScript's text item delimiters to ""
	end if
	return maintext
end replaceString

