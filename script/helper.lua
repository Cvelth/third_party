function download_progress(total, current)
	local ratio = current / total;
	ratio = math.min(math.max(ratio, 0), 1);
	local percent = math.floor(ratio * 100);
	print("Download progress (" .. percent .. "%/100%)")
end

function copy_file(from, to)
	if os.isfile(from) then
		os.mkdir (path.getdirectory(to))
		local ok, err = os.copyfile(from, to)
		if ok then
			--print ("Copy '" .. os.realpath(from) .. "' to '" .. os.realpath(to) .. "'.")
		else
			print (err)
		end
	end
end

function copy_directory(from, to)
	if os.isdir(from) then
		print ("Copy '" .. os.realpath(from) .. "' to '" .. os.realpath(to) .. "'.")
		local matches = os.matchfiles(from .. "/**")
		for id, file in pairs(matches) do
			copy_file(file, to .. path.getrelative(from, file))
		end
	else
		print ("Fail to copy a directory. It doesn't exist: '" .. from .. "'.")
	end
end

function remove_directory(name)
	if os.isdir(name) then
		local ok, err = os.rmdir(name)
		if ok then
			print ("Remove '" .. os.realpath(name) .. "'.")
		else
			print (err)
		end
	end
end

function add_library(name)
	path = os.findlib(name)
	if path then
		links { path }
	else
		print ("Fail to find '" .. path .. "'.")
	end
end
function add_include_dir(name)
	path = os.findheader(name)
	if path then
		include_dirs { path }
	else
		print ("Fail to find '" .. path .. "'.")
	end
end
function add_dependency(name)
	add_library(name)
	add_include_dir(name)
end