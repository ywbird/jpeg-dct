local function printtable(t)
  io.write("{\n")
  for key, value in pairs(t) do
    io.write(key .. ": ")
    if type(value) == "string" then
      io.write('"' .. value .. '"')
    elseif type(value) == "table" then
      printtable(value)
    else
      io.write(tostring(value))
    end
    io.write("\n")
  end
  io.write("}\n")
end

return printtable
