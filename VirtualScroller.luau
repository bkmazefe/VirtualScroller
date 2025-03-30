--!nonstrict
local Fusion = require("@Packages/Fusion")
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local peek = Fusion.peek

--[[
see also:
- https://blog.logrocket.com/virtual-scrolling-core-principles-and-basic-implementation-in-react/
- https://github.com/WICG/virtual-scroller
--]]

--[[
	Grid layout implementation of the original demo made by BoatBomber
]]

--- @class VirtualScroller

--- @within VirtualScroller
--- @interface VirtualScrollerProps
--- .AnchorPoint Vector2?
--- .Position UDim2?
--- .Size UDim2?
--- .Visible boolean?
--- .ItemCount Fusion.StateObject<number>
--- .ItemHeight Fusion.Value<any, number>
--- .ItemWidthScale Fusion.Value<any, number>
--- .CanvasPosition Fusion.Value<any, Vector2>
--- .Deviation number?
--- .RenderItem (use: Fusion.Use, scope: any, index: number) -> Instance?
--- ._debug boolean?
export type VirtualScrollerProps = {
  AnchorPoint: Vector2?,
  Position: UDim2?,
  Size: UDim2?,
  Visible: boolean?,
  ItemCount: Fusion.StateObject<number>,
  ItemHeight: Fusion.Value<any, number>,
  ItemWidthScale: Fusion.Value<any, number>,
  CanvasPosition: Fusion.Value<any, Vector2>,
  Deviation: number?,
  RenderItem: (use: Fusion.Use, scope: any, index: number) -> Instance?,
  _debug: boolean?,
}

--- @param scope typeof(Fusion:scoped())
--- @param props VirtualScrollerProps
--- @return ScrollingFrame
return function(scope: any, props: VirtualScrollerProps): ScrollingFrame
  local window_size = scope:Value(Vector2.new())
  local canvas_position = props.CanvasPosition

  local num_items = props.ItemCount
  local item_height = props.ItemHeight
  local item_width_scale = props.ItemWidthScale

  local deviation = props.Deviation or 1

  local horizontal_fit = scope:Computed(function(use)
    return 1 / use(item_width_scale)
  end)

  local items = scope:Computed(function(use)
    local number_of_items = use(num_items)
    local canvas_pos, window_size, height = use(canvas_position), use(window_size), use(item_height)

    local min_index = 0
    local max_index = -1

    if number_of_items > 0 then
      min_index = 1 + math.floor((canvas_pos.y / height) * use(horizontal_fit))
      max_index = math.ceil(((canvas_pos.y + window_size.y) / height) * use(horizontal_fit))
      -- Add extra on either side for seamless load
      local diff = (max_index - min_index) * deviation
      min_index = math.clamp(min_index - diff, 1, number_of_items)
      max_index = math.clamp(max_index + diff, 1, number_of_items)
    end

    local items = {}
    for i = min_index, max_index do
      items[i] = true
    end

    return items
  end)

  local full_canvas_size = scope:Computed(function(use)
    return UDim2.fromOffset(0, math.ceil(use(num_items) / use(horizontal_fit)) * use(item_height))
  end)

  local cell_size = scope:Computed(function(use)
    return UDim2.new(use(item_width_scale), 0, 0, use(item_height))
  end)

  local Frame
  Frame = scope:New("ScrollingFrame")({
    ClipsDescendants = not props._debug,
    AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
    Visible = props.Visible == nil and true or props.Visible,
    Size = props.Size or UDim2.fromScale(1, 1),
    Position = props.Position or UDim2.new(),
    BackgroundTransparency = 1,
    ScrollBarImageColor3 = Color3.fromRGB(45, 45, 45),
    ScrollBarThickness = 4,
    VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,

    CanvasSize = full_canvas_size,
    CanvasPosition = canvas_position,

    [OnChange("AbsoluteWindowSize")] = function()
      window_size:set(Frame.AbsoluteWindowSize)
    end,

    [OnChange("CanvasPosition")] = function()
      -- Exit if the canvas hasn't moved enough to warrant rendering new items
      local distance = (peek(canvas_position) - Frame.CanvasPosition).Magnitude
      local minimum = peek(item_height)

      if distance < minimum then
        return
      end

      canvas_position:set(Frame.CanvasPosition)
    end,

    [Children] = {
      scope:ForPairs(items, function(use, scope, i)
        return i,
          scope:New("Frame")({
            Name = "Index_" .. i,
            LayoutOrder = i,
            Size = cell_size,
            Position = scope:Computed(function(use)
              local horizontal_fit = use(horizontal_fit)
              local width_scale = 1 / horizontal_fit
              local item_height = use(item_height)

              return UDim2.new(
                width_scale * ((i - 1) % horizontal_fit),
                0,
                0,
                math.floor((i - 1) / horizontal_fit) * item_height
              )
            end),
            BackgroundTransparency = props._debug and 0.5 or 1,
            BackgroundColor3 = Color3.fromRGB(math.random(10, 255), math.random(10, 255), math.random(10, 255)),

            [Children] = props.RenderItem(use, scope, i),
          })
      end, Fusion.doCleanup),
    },
  })

  return Frame
end
