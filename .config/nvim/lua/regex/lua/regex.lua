-- execute: lua "<script>" <file>
local file = io.open(arg[1])
if file ~= nil then
  local pattern = file:read()
  if pattern ~= nil then
    local pos = #pattern
    for line in file:lines() do
      local index = 1
      while true do
        local s, e = string.find(line, pattern, index)
        if s == nil then
          break
        end
        print((s + pos) .. '-' .. (e + pos))
        index = e + 1
      end
      pos = pos + #line + 1
    end
  end

  file:close()
end
