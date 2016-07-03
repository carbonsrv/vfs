-- Carbon SQL database backend.

local function splitpath(path) -- returns dirpath, filename
	local dirpath, filename = string.match(path, "^(.*)/(.-)$")
	if dirpath == "" then
		dirpath = nil
	end
	return dirpath, filename
end

return {
	sql = function(drivename, db, options)
		local cwd = "/"

		if not options then
			error("VFS: Backend SQL: Need options. Maybe read the wiki?")
		end

		-- Since most databases are different compared to others, make everything an option
		local tablename = options.tablename
		if not tablename then
			error("VFS: Backend SQL: Need options.tablename")
		end

		-- Interfacing
		local sql_transactions = true
		if options.dostransaction ~= nil then
			sql_transactions = options.dotransaction
		end
		local sql_esc = options.esc or "$N"

		-- Types operators
		local sqlop_equals = options.equals_operator or "=="
		local sqltype_string = options.type_string or "string"
		local sqltype_number = options.type_number or "float64"
		local table_signature = "(filename "..sqltype_string..", dirpath "..sqltype_string..", modtime "..sqltype_number..", size "..sqltype_number..", content "..sqltype_string..")"
		local table_elms = "(filename, dirpath, modtime, size, content)"

		-- Helpers
		local function getpath(path)
			return vfs.abspath(path or ".", cwd)
		end
		local escn = 1
		local function esc()
			local r = string.gsub(sql_esc, "N", tostring(escn))
			escn = escn + 1
			return r
		end
		local function trans(fn)
			if sql_transactions then
				local res
				assert(db:begin(function()
					res = table.pack(fn())
					return true
				end))
				return table.unpack(res, 1, res.n)
			end
			return fn()
		end

		-- Updating methods
		local function delete(dirpath, filename)
			escn = 1
			if filename then
				return db:exec("DELETE FROM "..tablename.." WHERE filename "..sqlop_equals.." "..esc().." AND dirpath "..sqlop_equals.." "..esc(), filename, (dirpath or "/"))
			end
			return db:exec("DELETE FROM "..tablename.." WHERE dirpath "..sqlop_equals.." "..esc(), (dirpath or "/"))
		end
		local function deleteany(dirpath, filename)
			dirpath = dirpath or "/"
			local _, err = delete(dirpath..filename)
			if err then return false, err end
			_, err = delete(dirpath, filename)
			if err then return false, err end
			return true
		end
		local function add(dirpath, filename, content)
			escn = 1
			return db:exec("INSERT INTO "..tablename.." "..table_elms.." VALUES ("..esc()..", "..esc()..", "..esc()..", "..esc()..", "..esc()..")", filename, (dirpath or "/"), unixtime(), #content, content)
		end
		local function query(dirpath, filename)
			escn = 1
			if filename then
				return db:query("SELECT * FROM "..tablename.." WHERE filename "..sqlop_equals.." "..esc().." AND dirpath "..sqlop_equals.." "..esc(), filename, (dirpath or "/"))
			end
			return db:query("SELECT * FROM "..tablename.." WHERE dirpath "..sqlop_equals.." "..esc(), (dirpath or "/"))
		end

		-- Prepare db
		trans(function()
			assert(db:exec("CREATE TABLE IF NOT EXISTS "..tablename.." "..table_signature))
		end)

		-- Actual VFS backend
		return {
			-- Stubs
			mkdir = function() return true end,

			-- generic functions
			chdir = function(loc) cwd = vfs.abspath(loc, cwd) return cwd end,
			getcwd = function(loc) return cwd end,

			-- Real things
			write = function(loc, str)
				local dirpath, filename = splitpath(getpath(loc))
				if filename then
					return trans(function()
						local _, err = delete(dirpath, filename)
						if err then
							return nil, err
						end
						return add(dirpath, filename, str)
					end)
				end
				return nil, "Failed splitting path!"
			end,
			exists = function(loc)
				local dirpath, filename = splitpath(getpath(loc))
				if filename then
					local rows, err = query(dirpath, filename)
					if err then
						return false, err
					end

					if not rows then
						return false, nil
					end

					return rows.n >= 1, nil
				end
				return false, "Failed splitting path!"
			end,
			read = function(loc)
				local dirpath, filename = splitpath(getpath(loc))
				if filename then
					local rows, err = query(dirpath, filename)
					if err then
						return nil, err
					end

					local row = rows[1]
					if row then -- found file
						return row.content, nil
					end
					return nil, "No such file"
				end
				return nil, "Failed splitting path!"
			end,
			size = function(loc)
				local dirpath, filename = splitpath(getpath(loc))
				if filename then
					local rows, err = query(dirpath, filename)
					if err then
						return nil, err
					end

					local row = rows[1]
					if row then -- found file
						return row.size, nil
					end
					return nil, "No such file"
				end
				return nil, "Failed splitting path!"
			end,
			modtime = function(loc)
				local dirpath, filename = splitpath(getpath(loc))
				if filename then
					local rows, err = query(dirpath, filename)
					if err then
						return nil, err
					end

					local row = rows[1]
					if row then -- found file
						return row.modtime, nil
					end
					return nil, "No such file"
				end
				return nil, "Failed splitting path!"
			end,
			delete = function(loc)
				local dirpath, filename = splitpath(getpath(loc))
				if filename then
					return trans(function()
						return deleteany(dirpath, filename)
					end)
				end
				return nil, "Failed splitting path!"
			end,
			list = function(loc)
				if loc then
					local rows, err = query(loc)
					if err then
						return nil, err
					end

					if rows.n == 0 then
						return nil, "No such directory"
					end

					local res = {}
					for n=1, rows.n do
						res[n] = rows[n].filename
					end

					return res, nil
				end
				return nil, "No filename given!"
			end,
		}
	end
}
