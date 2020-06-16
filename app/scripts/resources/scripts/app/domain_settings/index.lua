--	Domain variables for fusionpbx
--	Version: MPL 1.1

--	The contents of this file are subject to the Mozilla Public License Version
--	1.1 (the "License"); you may not use this file except in compliance with
--	the License. You may obtain a copy of the License at
--	http://www.mozilla.org/MPL/

--	Software distributed under the License is distributed on an "AS IS" basis,
--	WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
--	for the specific language governing rights and limitations under the
--	License.


--set defaults
expire = "3600";

--get the variables
domain_name = session:getVariable("domain_name");

--includes
local cache = require"resources.functions.cache"

--include json library
local json = require "resources.functions.lunajson";

--prepare the api object
api = freeswitch.API();

--define the trim function
require "resources.functions.trim";

--set the cache key
key = "app:dialplan:outbound:domain_vars:" .. domain_name;
local vars = {};
--get the destination number
value, err = cache.get(key);
if (err == 'NOT FOUND') then

	--connect to the database
	local Database = require "resources.functions.database";
	local dbh = Database.new('system');

	--select data from the database
	local sql = "SELECT domain_setting_subcategory, domain_setting_value ";
	sql = sql .. "FROM v_domain_settings JOIN v_domains ON v_domain_settings.domain_uuid = v_domains.domain_uuid ";
	sql = sql .. "WHERE domain_setting_enabled = 'true' ";
	sql = sql .. "AND domain_name = :domain_name ";
	local params = {domain_name = domain_name};
	if (debug["sql"]) then
		freeswitch.consoleLog("notice", "SQL:" .. sql .. "; params: " .. json.encode(params) .. "\n");
	end
	dbh:query(sql, params, function(row)
		--set the local variables
		vars[row.domain_setting_subcategory]=row.domain_setting_value;
		--set the outbound caller id
		session:execute("set", row.domain_setting_subcategory.."="..row.domain_setting_value);
	end);
	value = json.encode(vars);
	ok, err = cache.set(key, value, expire);
	freeswitch.consoleLog("notice", "[app:dialplan:outbound:domain_vars] " .. value .. " source: database\n".."ok = "..json.encode(ok)..", err = "..json.encode(err).."\n");
else
	--parse the cache
	local key_pairs = json.decode(value);
	for k,v in pairs(key_pairs) do
		session:execute("set", k.."="..v);
	end

	--send to the console
	freeswitch.consoleLog("notice", "[app:dialplan:outbound:domain_vars] " .. value .. " source: cache\n");
end
