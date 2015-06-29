--------------------------------------------------------------------------------
-- test.lua, v0.3: Helper functions for testing functionality
-- This file is a part of Sailor project
-- Copyright (c) 2014-2015 Etiene Dalcol <dalcol@etiene.net>
-- License: MIT
-- http://sailorproject.org
--------------------------------------------------------------------------------
local M = {}

local page
local r

function M:prepare(write_func)	
	r = { uri = '', write = write_func, puts = write_func, headers_in = {}, headers_out = {} }
	page = sailor.init(r)
	return self
end

function M.load_fixtures(model_name)
	local db = require "sailor.db"

	local Model = sailor.model(model_name)
	local fixtures = require("tests.fixtures."..model_name) or {}
	local objects = {}
	db.connect()
	db.query('truncate table ' .. Model.db.table .. ';') -- Reseting current state
	db.close()
	for _,v in pairs(fixtures) do  -- loading fixtures
	  o = Model:new(v)
	  o:save(false)
	  table.insert(objects, o)
	end
	return objects
end

local function redirected(response, path)
	if response.status ~= 302 then return false end
	return (response.headers['Location']):match(path) and true or false
end

function M.request(path, data, additional_headers)
	local conf = require "conf.conf"
	data = data or {}
	local body = ''
	local function write(_,data) body = body .. data end
	conf.sailor.friendly_urls = false

	M:prepare(write)
	page.POST = data.post or {}
	page.GET = data.get or {}
	page.GET[conf.sailor.route_parameter] = path
	local status = sailor.route(page)
	
	return {status = status, body = body, headers = r.headers_out, redirected = redirected}
end

return M:prepare()
