function add_project(name)
	project (name)
		targetname (name)
		language "C++"
		kind "StaticLib"
	
		includedirs {
			"include/" .. name,
			"source/" .. name,
			"include/",
			"source/",
		}
		files {
			"include/" .. name .. "/**.h*",

			"source/" .. name .. "/**.h*",
			"source/" .. name .. "/**.c*",
		}
end