--##

---@param uri string @ The uri of file
---@param text string @ The content of file
---@param diffs Diff[] @ The diffs to add more diffs to
local function replace(uri, text, diffs)
  -- rename `global` so we can tell them apart!
  local this_mod = uri:match("mods[\\/]([^\\/]+)[\\/]")
  if this_mod then
    local scenario = uri:match("scenarios[\\/]([^\\/]+)[\\/]")
    if scenario then
      this_mod = this_mod.."__"..scenario
    end
    this_mod = this_mod:gsub("[^a-zA-Z0-9_]","_")
    local global_name = "__"..this_mod.."__global"

    local global_matches = {}
    ---@type number
    for start, finish in text:gmatch("%f[a-zA-Z0-9_]()global()%s*[=.%[]") do
      global_matches[start] = finish
    end
    -- remove matches that where `global` is actually indexing into something (`.global`)
    for start in text:gmatch("%.%s*()global%s*[=.%[]") do
      global_matches[start] = nil
    end
    -- `_ENV.global` and `_G.global` now get removed because of this, we can add them back in
    -- with the code bellow, but it's a 66% performance cost increase for hardly any gain
    -- for start, finish in text:gmatch("_ENV%.%s*()global()%s*[=.%[]") do
    --   global_matches[start] = finish
    -- end
    -- for start, finish in text:gmatch("_G%.%s*()global()%s*[=.%[]") do
    --   global_matches[start] = finish
    -- end

    local diffs_count = #diffs
    for start, finish in pairs(global_matches) do
      diffs_count = diffs_count + 1
      diffs[diffs_count] = {
        start  = start,
        finish = finish - 1,
        text = global_name,
      }
    end

    -- and "define" it at the start of any file that used it
    if next(global_matches) then
      diffs_count = diffs_count + 1
      diffs[diffs_count] = {
        start  = 1,
        finish = 0,
        text = global_name.."={}\n",
      }
    end
  end
end

return {
  replace = replace,
}
