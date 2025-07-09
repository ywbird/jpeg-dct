local vec2 = require("lib.nvec")

---@alias Vec2 NVec

local BLOCK_X = 60
local BLOCK_Y = 60
local G_X = 600
local G_Y = 60
local PX_GAP = 2
local PX_SIZE = 60

function love.load()
  font_galmuri_mono = love.graphics.newFont("assets/fonts/GalmuriMono11.ttf", 12)
  love.graphics.setFont(font_galmuri_mono)

  block = {}
  G = {}
  B = {}
  for x = 1, 8 do
    block[x] = {}
    G[x] = {}
    B[x] = {}
    for y = 1, 8 do
      block[x][y] = -128
      G[x][y] = 0
      B[x][y] = 0
    end
  end

  Q = {
    { 16, 12, 14, 14, 18, 24, 49, 72 },
    { 11, 12, 13, 17, 22, 35, 64, 92 },
    { 10, 14, 16, 22, 37, 55, 78, 95 },
    { 16, 19, 24, 29, 56, 64, 87, 98 },
    { 24, 26, 40, 51, 68, 81, 103, 112 },
    { 40, 58, 57, 87, 109, 104, 121, 100 },
    { 51, 60, 69, 80, 103, 113, 120, 103 },
    { 61, 55, 56, 62, 77, 92, 101, 99 },
  }

  -- stylua: ignore
  zigzag_indices = {
    {1,1},{1,2},{2,1},{3,1},{2,2},{1,3},{1,4},{2,3},
    {3,2},{4,1},{5,1},{4,2},{3,3},{2,4},{1,5},{1,6},
    {2,5},{3,4},{4,3},{5,2},{6,1},{7,1},{6,2},{5,3},
    {4,4},{3,5},{2,6},{1,7},{1,8},{2,7},{3,6},{4,5},
    {5,4},{6,3},{7,2},{8,1},{8,2},{7,3},{6,4},{5,5},
    {4,6},{3,7},{2,8},{3,8},{4,7},{5,6},{6,5},{7,4},
    {8,3},{8,4},{7,5},{6,6},{5,7},{4,8},{5,8},{6,7},
    {7,6},{8,5},{8,6},{7,7},{6,8},{7,8},{8,7},{8,8}
  }

  B_ARR = {}
  BLOCK_ARR = {}

  RAW = ""
  COMP = ""
end

function love.update(dt)
  if love.mouse.isDown(1) or love.mouse.isDown(2) then
    local x = love.mouse.getX()
    local y = love.mouse.getY()
    local bx = math.floor((x - BLOCK_X) / PX_SIZE) + 1
    local by = math.floor((y - BLOCK_Y) / PX_SIZE) + 1
    if 0 < bx and bx <= 8 and 0 < by and by <= 8 then
      block[bx][by] = block[bx][by] + 255 * 5 * (love.mouse.isDown(1) and 1 or -1) * dt
      if block[bx][by] < -128 then
        block[bx][by] = -128
      end
      if block[bx][by] > 127 then
        block[bx][by] = 127
      end
    end

    calc_G()
    calc_B()

    RAW = ""
    COMP = ""
    B_ARR = {}
    iterate_2d(function(x, y)
      RAW = RAW .. lpad(tostring(math.floor(block[x][y])), 3) .. ","
      local z = zigzag_indices[8 * (x - 1) + y]
      COMP = COMP .. lpad(tostring(math.floor(B[z[1]][z[2]])), 3) .. ","
      table.insert(B_ARR, math.floor(B[z[1]][z[2]]))
    end, function(_)
      RAW = RAW .. "\n"
      COMP = COMP .. "\n"
    end)
  end
end

function love.draw()
  iterate_2d(function(x, y)
    local c = (block[x][y] + 128) / 255
    love.graphics.setColor(c, c, c)
    love.graphics.rectangle( --
      "fill",
      BLOCK_X + PX_SIZE * (x - 1) + PX_GAP / 2,
      BLOCK_Y + PX_SIZE * (y - 1) + PX_GAP / 2,
      PX_SIZE - PX_GAP,
      PX_SIZE - PX_GAP
    )
    love.graphics.setColor(1, 1 - c, 1 - c)
    love.graphics.print( --
      math.floor(block[x][y])
        .. "(" --
        .. math.floor(block[x][y] + 128)
        .. ")"
        .. "\n"
        .. math.floor(G[x][y] * 100) / 100
        .. "\n"
        .. math.floor(B[x][y] * 100) / 100,
      BLOCK_X + PX_SIZE * (x - 1) + PX_GAP / 2 + 3,
      BLOCK_Y + PX_SIZE * (y - 1) + PX_GAP / 2 + 3
    )
  end)

  love.graphics.setColor(1, 0, 0)

  love.graphics.rectangle( --
    "line",
    BLOCK_X - PX_GAP,
    BLOCK_Y - PX_GAP,
    8 * PX_SIZE + PX_GAP * 2,
    8 * PX_SIZE + PX_GAP * 2
  )

  love.graphics.print(RAW .. "\n\n" .. COMP .. "\n\n" .. tablestring(B_ARR), G_X, G_Y)
end

function love.keypressed(k)
  if k == "q" then
    love.event.quit()
  end
end

function calc_G()
  local a = function(x)
    return x == 0 and (1 / math.sqrt(2)) or 1
  end

  iterate_2d(function(u, v)
    u = u - 1
    v = v - 1
    local b = 0
    iterate_2d(function(x, y)
      x = x - 1
      y = y - 1

      b = b
        + block[x + 1][y + 1] --
          * math.cos(((2 * x + 1) * u * math.pi) / 16)
          * math.cos(((2 * y + 1) * v * math.pi) / 16)
    end)
    G[u + 1][v + 1] = 1 / 4 * a(u) * a(v) * b
  end)
end

function calc_B()
  iterate_2d(function(x, y)
    B[x][y] = math.floor(G[x][y] / Q[x][y] + 0.5)
  end)
end

---comment
---@param func function(x: number, y: number): void
---@param between nil|function(x: number): void
---@param w number|nil
---@param h number|nil
function iterate_2d(func, between, w, h)
  w = w or 8
  h = h or 8
  for x = 1, w do
    if between ~= nil then
      between(x)
    end
    for y = 1, h do
      func(x, y)
    end
  end
end

---@param str string
---@param c integer
---@return string
function srep(str, c)
  local res = ""
  for _ = 0, c do
    res = res .. str
  end
  return res
end

---@param t table
---@param w number|nil
---@return string
function tablestring(t, w)
  w = w or 40
  local result = {}
  local line = 1
  result[1] = "{ "
  for i = 1, #t do
    if #(result[line] .. t[i]) >= w then
      line = line + 1
      result[line] = ""
    end
    local a = t[i]
    result[line] = result[line] .. a .. ", "
  end
  result[line] = result[line] .. " }"

  local result_string = ""

  for _, st in ipairs(result) do
    result_string = result_string .. st .. "\n"
  end

  return result_string
end

---@param s string
---@param l integer
---@param c string|nil
---@return string
---@return boolean
function lpad(s, l, c)
  local res = srep(c or " ", l - #s) .. s
  return res, res ~= s
end

---@param s string
---@param l integer
---@param c string|nil
---@return string
---@return boolean
function rpad(s, l, c)
  local res = s .. srep(c or " ", l - #s)

  return res, res ~= s
end
