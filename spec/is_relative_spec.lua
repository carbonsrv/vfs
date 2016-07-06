describe("carbonvfs", function()
	local vfs = dofile("init.lua")
	describe("should check if path is relative given", function()
		local paths = {}
		paths["/test"] = false
		paths[".."] = true
		paths["../a/"] = true
		paths["/butter"] = false
		
		for path, expected in pairs(paths) do
			it(path .. ", returning "..tostring(expected), function()
				assert.equals(vfs.is_relative(path), expected)
			end)
		end
	end)
end)
