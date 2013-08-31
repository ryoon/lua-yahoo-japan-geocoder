-- Yahoo! Japan geocoder

--[[
MIT style license

Copyright (c) 2013 Ryo ONODERA

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

--[[
This program is written for lua 5.2, luasocket 3.0rc1, and lua-expat 20130831.

Detail specification about Yahoo! Japan Geocoder API is found at
http://developer.yahoo.co.jp/webapi/map/openlocalplatform/v1/geocoder.html .
Causion: This page is written in Japanese.
]]

local io = require("io")
local http = require("socket.http")
local ltn12 = require("ltn12")
local lxp = require("lxp")

-- CONSTANTS
-- APPID is granted to individual by Yahoo! Japan. Do not disclose this!
APPID = "YOUR-APPID"

-- base URL for Yahoo! Japan Geoder API
BASEURL = "http://geo.search.olp.yahooapis.jp/OpenLocalPlatform/V1/geoCoder"

-- Search level, possibly ge, le, eq
LEVEL = "le"

-- Encode string to URL style.
function urlencode(string)
    string = string.gsub(string, "\n", "\r\n")
    -- Match string is processed anonymous function, and replaced.
    string = string.gsub(string, "([^%w %-%_%.%~])",
	function (c) return string.format ("%%%02X", string.byte(c)) end)
    string = string.gsub(string, " ", "+")

    return string
end


-- Composite GET URL.
function compositeurl(address)
    url = BASEURL.."?".."appid="..APPID.."&".."ar="..LEVEL.."&".."query="..urlencode(address)

    return url
end


-- Get GeoCoder XML via Yahoo! Japan Geocoder API.
function getgeocodexml(url)
    -- Prepare empty table.
    local xml = {}

    -- Get GeoCoder XML, and put it to table.
    response, status, header = http.request {
	url = url,
	sink = ltn12.sink.table(xml)
}

    return xml
end


-- Parse CSV and put elements to table, cvs.
function cvsparse(string)
    -- Prepare empty table.
    local csv = {}
    -- Split with comma.
    -- XXX ELEMENT1, ELEMET2, ELEMENT3 is given, return " ELEMENTS2"
    -- XXX or " ELEMENT3". This is ugly, but cating to float help you.
    for element in string.gmatch(string..",", "([^,]*),") do
	table.insert(csv, element)
    end

    return csv
end

-- Get Coordinates from its tag.
function getcoordinates(address)
    local coordinates = {}

    callbacks = {
	StartElement = function(parser, name)
	    if name == "Coordinates" then
		callbacks.CharacterData = function(parser, string)
		    table.insert(coordinates, string)
		end
	    end
	end,

	EndElement = function(parser, name)
	    if name == "Coordinates" then
		callbacks.CharacterData = false
	    end
	end,

	CharacterData = false
    }

    p = lxp.new(callbacks)

    p:parse(table.concat(getgeocodexml(compositeurl(address))))
    p:parse("\n")
    p:parse()
    p:close()

    return coordinates
end



function main()

	-- If you have header, please fix start line number.
	local count = 1
	while true do
		-- Read from stdin.
		local line = io.read()

		-- Detect End of File.
		if line == nil
			then break
		end

		local elements = cvsparse(line)

		address = elements[1]

		-- Select first coordinates.
		local coordinates = cvsparse(getcoordinates(address)[1])
		latitude = coordinates[1]
		longitude = coordinates[2]

		io.write(string.format("%s, %f, %f\n", address, latitude, longitude))


		count = count + 1
	end
end


-- start
main()

