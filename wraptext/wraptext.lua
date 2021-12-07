-- https://en.wikipedia.org/wiki/Line_breaking_rules_in_East_Asian_languages
-- Some of these rules I don't know how to follow, but some basics can be done at least

local utf8 = require("wraptext.utf8")
local M = {}

local zero_width_char = "\xe2\x80\x8b" -- \226\128\139
-- zero_width_char = "*" -- debug

local simplified_chinese_no_start = "!%),.:;?]}¢°·'\"†‡›℃∶、。〃〆〕〗〞﹚﹜！＂％＇），．：；？！］｝～"
local simplified_chinese_no_end = "$(£¥·'\"〈《「『【〔〖〝﹙﹛＄（．［｛￡￥"

-- the encoding of the end of the below line is weird on GitHub/browser, but looks fine in text editor
local traditional_chinese_no_start = "!),.:;?]}¢·–— '\"• 、。〆〞〕〉》」︰︱︲︳﹐﹑﹒﹓﹔﹕﹖﹘﹚﹜！），．：；？︶︸︺︼︾﹀﹂﹗］｜｝､"
local traditional_chinese_no_end = "([{£¥'\"‵〈《「『〔〝︴﹙﹛（｛︵︷︹︻︽︿﹁﹃﹏"

local japanese_no_start = ")]｝〕〉》」』】〙〗〟'\"｠»ヽヾーァィゥェォッャュョヮヵヶぁぃぅぇぉっ"
	  japanese_no_start = japanese_no_start .. "ゃゅょゎゕゖㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ々〻‐゠–〜? ! ‼ ⁇ ⁈ ⁉・、:;,。."
local japanese_no_end = "([｛〔〈《「『【〘〖〝'\"｟«"
local japanese_no_split = "012345679—...‥〳〴〵"

local korean_no_start = "!%),.:;?]}¢°'\"†‡℃〆〈《「『〕！％），．：；？］｝"
local korean_no_end = "$([\\{£¥'\"々〇〉》」〔＄（［｛｠￥￦ #"

local no_start = simplified_chinese_no_start .. traditional_chinese_no_start .. japanese_no_start .. korean_no_start
local no_end = simplified_chinese_no_end .. traditional_chinese_no_end .. japanese_no_end .. korean_no_end
local no_split = japanese_no_split

local function utf8_split_chunk(text, size)
	size = size or 1
	local s = {}
	for i=1, utf8.len(text), size do
		table.insert(s, utf8.sub(text, i, i + size - 1))
	end
	return s
end

local function check_line_break(previous_byte, current_byte, next_byte)
	if current_byte == utf8.byte("…") and next_byte == utf8.byte("…") then return false end
	if current_byte == utf8.byte("—") and next_byte == utf8.byte("—") then return false end

	-- these are sticky? they bind two things together
	local no_splits = utf8_split_chunk(no_split)
	for k,v in ipairs(no_splits) do
		local byte = utf8.byte(v)
		if current_byte == byte or next_byte == byte then
			--print("no_splits", byte, utf8.char(byte))
			return false
		end
	end

	-- these are the ends of a thing !
	local no_starts = utf8_split_chunk(no_start)
	for k,v in ipairs(no_starts) do
		local byte = utf8.byte(v)
		if next_byte == byte then
			--print("no_starts")
			return false
		end
	end

	-- these are the starts of a thing $
	local no_ends = utf8_split_chunk(no_end)
	for k,v in ipairs(no_ends) do
		local byte = utf8.byte(v)
		if current_byte == byte then
			--print("no_ends")
			return false
		end
	end
	
	-- below should be final line
	if current_byte > 1024 then return true end -- skip codes below 1024
end

local function merge_chunks(text_table, char)
	local s = ""
	for k,v in ipairs(text_table) do
		s = s .. v

		local previous_byte = -1
		local current_byte = tonumber(utf8.byte(text_table[k]))
		local next_byte =  -1

		if k > 1 then
			previous_byte = tonumber(utf8.byte(text_table[k-1]))
		end
		if k < #text_table then
			next_byte = tonumber(utf8.byte(text_table[k+1]))
		end

		--print(v, previous_byte, current_byte, next_byte)

		
		if k < #text_table then
			if check_line_break(previous_byte, current_byte, next_byte) then -- only add zero width above 1024 char byte code
				s = s .. char
				--print("true")
			--else
				--print("false")
			end
		end
	end
	return s
end


function M.filter(text)
	return merge_chunks(utf8_split_chunk(text, 1), zero_width_char)
end


return M