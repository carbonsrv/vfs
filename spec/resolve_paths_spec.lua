describe("carbonvfs", function()
	local vfs = dofile("init.lua")
	describe("should resolve relative paths to absolute given", function()
		local pathpairs = {}
		pathpairs[{"/base", ".."}] = "/"
		pathpairs[{"/test", "is/tasty"}] = "/test/is/tasty"
		pathpairs[{"/a/path", "../very/complicated/../amazing/path"}] = "/a/very/amazing/path"
		pathpairs[{"/irrelevant", "/noodles"}] = "/noodles"
		pathpairs[{"/samedir", "."}] = "/samedir"
		pathpairs[{"/samedir", ""}] = "/samedir"

		for pair, expected in pairs(pathpairs) do 
			it(pair[1] .. " and " .. pair[2], function()
				assert.equals(vfs.abspath(pair[2], pair[1]), expected)
			end)
		end
	end)
end)
