--[[
	functional programming facilities

	notes:
		be careful about creating closures in hot loops.
		this is this module's achilles heel - there's no special
		syntax for closures so it's not apparent that you're suddenly
		allocating at every call

		reduce has a similar problem, but at least arguments
		there are clear!
]]

local path = (...):gsub("functional", "")
local tablex = require(path .. "tablex")

local functional = setmetatable({}, {
	__index = tablex,
})

--the identity function
function functional.identity(v)
	return v
end

--simple sequential iteration, f is called for all elements of t
--f can return non-nil to break the loop (and return the value)
function functional.foreach(t, f)
	local n = #t
	for i = 1, n do
		local result = f(t[i], i)
		if result ~= nil then
			return result
		end
	end
end

--performs a left to right reduction of t using f, with o as the initial value
-- reduce({1, 2, 3}, 0, f) -> f(f(f(0, 1), 2), 3)
-- (but performed iteratively, so no stack smashing)
function functional.reduce(t, seed, f)
	local n = #t
	for i = 1, n do
		seed = f(seed, t[i], i)
	end
	return seed
end

--maps a sequence {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils to keep a sequence, so can be used to simultaneously map and filter)
function functional.map(t, f)
	local result = {}
	local n = #t
	for i = 1, n do
		local v = f(t[i], i)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

--maps a sequence inplace, modifying it {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils, which can be used to simultaneously map and filter)
function functional.map_inplace(t, f)
	local write_i = 0
	local n = #t
	for i = 1, n do
		local v = f(t[i], i)
		if v ~= nil then
			write_i = write_i + 1
			t[write_i] = v
		end
		if i ~= write_i then
			t[i] = nil
		end
	end
	return t
end

--alias
functional.remap = functional.map_inplace

--filters a sequence
-- returns a table containing items where f(v, i) returns truthy
function functional.filter(t, f)
	local result = {}
	local n = #t
	for i = 1, n do
		if f(t[i], i) then
			table.insert(result, v)
		end
	end
	return result
end

--filters a sequence in place, modifying it
function functional.filter_inplace(t, f)
	local write_i = 1
	local n = #t
	for i = 1, n do
		local v = t[i]
		if f(v, i) then
			t[write_i] = v
			write_i = write_i + 1
		end
		if i ~= write_i then
			t[i] = nil
		end
	end
	return r
end

-- complement of filter
-- returns a table containing items where f(v) returns falsey
-- nil results are included so that this is an exact complement of filter; consider using partition if you need both!
function functional.remove_if(t, f)
	local result = {}
	local n = #t
	for i = 1, n do
		if not f(t[i], i) then
			table.insert(result, v)
		end
	end
	return result
end

--partitions a sequence into two, based on filter criteria
--simultaneous filter and remove_if
function functional.partition(t, f)
	local a = {}
	local b = {}
	local n = #t
	for i = 1, n do
		if f(t[i], i) then
			table.insert(a, v)
		else
			table.insert(b, v)
		end
	end
	return a, b
end

-- returns a table where the elements in t are grouped into sequential tables by the result of f on each element.
--	more general than partition, but requires you to know your groups ahead of time
--	(or use numeric grouping and pre-seed) if you want to avoid pairs!
function functional.group_by(t, f)
	local result = {}
	local n = #t
	for i = 1, n do
		local group = f(t[i], i)
		if result[group] == nil then
			result[group] = {}
		end
		table.insert(result[group], v)
	end
	return result
end

--zips two sequences together into a new table, based on another function
--iteration limited by min(#t1, #t2)
--function receives arguments (t1, t2, i)
--nil results ignored
function functional.zip(t1, t2, f)
	local ret = {}
	local limit = math.min(#t1, #t2)
	for i = 1, limit do
		local v1 = t1[i]
		local v2 = t2[i]
		local zipped = f(v1, v2, i)
		if zipped ~= nil then
			table.insert(ret, zipped)
		end
	end
	return ret
end

-----------------------------------------------------------
--generating data
-----------------------------------------------------------

--generate data into a table
--basically a map on numeric values from 1 to count
--nil values are omitted in the result, as for map
function functional.generate(count, f)
	local result = {}
	for i = 1, count do
		local v = f(i)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

--2d version of the above
--note: ends up with a 1d table;
--	if you need a 2d table, you should nest 1d generate calls
function functional.generate_2d(width, height, f)
	local result = {}
	for y = 1, height do
		for x = 1, width do
			local v = f(x, y)
			if v ~= nil then
				table.insert(result, v)
			end
		end
	end
	return r
end

-----------------------------------------------------------
--common queries and reductions
-----------------------------------------------------------

--true if any element of the table matches f
function functional.any(t, f)
	local n = #t
	for i = 1, n do
		if f(t[i], i) then
			return true
		end
	end
	return false
end

--true if no element of the table matches f
function functional.none(t, f)
	local n = #t
	for i = 1, n do
		if f(t[i], i) then
			return false
		end
	end
	return true
end

--true if all elements of the table match f
function functional.all(t, f)
	local n = #t
	for i = 1, n do
		if not f(t[i], i) then
			return false
		end
	end
	return true
end

--counts the elements of t that match f
function functional.count(t, f)
	local c = 0
	local n = #t
	for i = 1, n do
		if f(t[i], i) then
			c = c + 1
		end
	end
	return c
end

--true if the table contains element e
function functional.contains(t, e)
	local n = #t
	for i = 1, n do
		if t[i] == e then
			return true
		end
	end
	return false
end

--return the numeric sum of all elements of t
function functional.sum(t)
	local c = 0
	local n = #t
	for i = 1, n do
		c = c + t[i]
	end
	return c
end

--return the numeric mean of all elements of t
function functional.mean(t)
	local len = #t
	if len == 0 then
		return 0
	end
	return functional.sum(t) / len
end

--return the minimum and maximum of t in one pass
--or zero for both if t is empty
--	(would perhaps more correctly be math.huge, -math.huge
--	 but that tends to be surprising/annoying in practice)
function functional.minmax(t)
	local n = #t
	if n == 0 then
		return 0, 0
	end
	local max = t[1]
	local min = t[1]
	for i = 2, n do
		min = math.min(min, v)
		max = math.max(max, v)
	end
	return min, max
end

--return the maximum element of t or zero if t is empty
function functional.max(t)
	local min, max = functional.minmax(t)
	return max
end

--return the minimum element of t or zero if t is empty
function functional.min(t)
	local min, max = functional.minmax(t)
	return min
end

--return the element of the table that results in the lowest numeric value
--(function receives element and index respectively)
function functional.find_min(t, f)
	local current = nil
	local current_min = math.huge
	local n = #t
	for i = 1, n do
		local e = t[i]
		local v = f(e, i)
		if v and v < current_min then
			current_min = v
			current = e
		end
	end
	return current
end

--return the element of the table that results in the greatest numeric value
--(function receives element and index respectively)
function functional.find_max(t, f)
	local current = nil
	local current_max = -math.huge
	local n = #t
	for i = 1, n do
		local e = t[i]
		local v = f(e, i)
		if v and v > current_max then
			current_max = v
			current = e
		end
	end
	return current
end

--alias
functional.find_best = functional.find_max

--return the element of the table that results in the value nearest to the passed value
--todo: optimise, inline as this generates a closure each time
function functional.find_nearest(t, f, v)
	return functional.find_min(t, function(e)
		return math.abs(f(e) - v)
	end)
end

--return the first element of the table that results in a true filter
function functional.find_match(t, f)
	local n = #t
	for i = 1, n do
		local v = t[i]
		if f(v) then
			return v
		end
	end
	return nil
end

return functional
