require (path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/script/helper")

function fetch_a_github_release(owner, name, tag, filename, include_path, source_path, lib_path)
	if not os.isfile(_MAIN_SCRIPT_DIR .. "/tmp/status/" .. name) then
		print ("Fail to locate '" .. name .. "'.")
		os.mkdir(_MAIN_SCRIPT_DIR .. "/tmp/")
		local address = "https://github.com/" .. owner .. "/" .. name .. "/releases/download/" .. tag .. "/" .. filename
		local archive_path = _MAIN_SCRIPT_DIR .. "/tmp/" .. filename
		print ("Fetch '" .. address .. "'.")
		local result_str, response_code = http.download(
			address, archive_path, { progress = _download_progress }
		)
		if response_code == 200 then
			if path.getextension(archive_path) == ".zip" then
				print ("Extract '" .. os.realpath(archive_path) .. "'.")
				zip.extract(archive_path, _MAIN_SCRIPT_DIR .. "/tmp/")

				local directory = path.replaceextension(archive_path, "")					
				if include_path then 
					copy_directory(directory .. "/" .. include_path, "include/" .. name .. "/")
				end
				if source_path then 
					copy_directory(directory .. "/" .. source_path, "source/" .. name .. "/")
				end
				if lib_path then 
					copy_directory(directory .. "/" .. lib_path, "lib/" .. name .. "/")
				end
			
				if os.isfile(directory .. "/" .. "LICENSE") then
					copy_file(directory .. "/" .. "LICENSE", "license/" .. name .. "/LICENSE")
				elseif os.isfile(directory .. "/" .. "LICENSE.md") then
					copy_file(directory .. "/" .. "LICENSE.md", "license/" .. name .. "/LICENSE.md")
				else
					print ("Unable to find the license file for '" .. name .. "'.")
					return
				end

				remove_directory(_MAIN_SCRIPT_DIR .. "/tmp/" .. name)
			
				os.mkdir (_MAIN_SCRIPT_DIR .. "/tmp/status")
				file = io.open(_MAIN_SCRIPT_DIR .. "/tmp/status/" .. name, "w")
				file:close()
			else
				print ("Unable to extract '" .. os.realpath(archive_path) .. "'.")
			end
		else
			print ("Fail to fetch the file: " .. result_str .. " (" .. response_code .. ").")
		end
	else
		print ("Build '" .. name .. "'.")
	end
end
