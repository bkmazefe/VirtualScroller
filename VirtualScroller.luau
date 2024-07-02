local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fusion
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Value = Fusion.Value
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs

local New = Fusion.New
local Children = Fusion.Children
local OnChange = Fusion.OnChange

--[[
see also:
- https://blog.logrocket.com/virtual-scrolling-core-principles-and-basic-implementation-in-react/
- https://github.com/WICG/virtual-scroller
--]]

--[[
	Grid layout implementation of the original demo made by BoatBomber
]]

-- Component

export type props = {
	Visible: boolean?,
	Size: UDim2?,
	CanvasPosition: Fusion.Value<Vector2>,
	Position: UDim2?,
	ItemCount: Fusion.Value<number>,
	ItemHeight: Fusion.Value<number>,
	ItemWidthScale: Fusion.Value<number>,
	RenderItem: (index: number) -> Instance?,
	AnchorPoint: Vector2?,
	BorderSizePixel: number?,
	_debug: boolean?,
}

return function(props: props)
	local WindowSize = Value(Vector2.new())
	local CanvasPosition = props.CanvasPosition

	local numItems = props.ItemCount
	local itemHeight = props.ItemHeight
	local itemWidthScale = props.ItemWidthScale

	local Items = Computed(function()
		local canvasPos, windowSize, height, widthScale = CanvasPosition:get(), WindowSize:get(), itemHeight:get(), itemWidthScale:get()
		local horizontalFit = 1 / itemWidthScale:get()

		local minIndex = 0
		local maxIndex = -1
		if numItems:get() > 0 then
			minIndex = 1 + math.floor((canvasPos.y / height) * horizontalFit)
			maxIndex = math.ceil(((canvasPos.y + windowSize.y) / height) * horizontalFit)
			-- Add extra on either side for seamless load
			local diff = maxIndex - minIndex
			minIndex = math.clamp(minIndex - diff, 1, numItems:get())
			maxIndex = math.clamp(maxIndex + diff, 1, numItems:get())
		end

		-- Dict for stable keys
		local items = table.create(maxIndex - minIndex + 1)
		for i = minIndex, maxIndex do
			items[i] = true
		end

		return items
	end)

	local fullCanvasSize = Computed(function()
		local horizontalFit = 1 / itemWidthScale:get()
		return math.ceil(numItems:get() / horizontalFit) * itemHeight:get()
	end)

	local Frame
	Frame = New("ScrollingFrame")({
		ClipsDescendants = not props._debug,
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Visible = props.Visible == nil and true or props.Visible,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		BorderSizePixel = props.BorderSizePixel or 0,
		BorderColor3 = Color3.fromRGB(10,10,13),
		BackgroundColor3 = Color3.fromRGB(46, 46, 46),
		ScrollBarImageColor3 = Color3.fromRGB(64, 64, 64),
		ScrollBarThickness = 12,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		
		CanvasSize = Computed(function()
			return UDim2.fromOffset(0, fullCanvasSize:get())
		end),
		CanvasPosition = CanvasPosition,

		[OnChange("AbsoluteWindowSize")] = function()
			WindowSize:set(Frame.AbsoluteWindowSize)
		end,

		[OnChange("CanvasPosition")] = function()
			-- Exit if the canvas hasn't moved enough to warrant rendering new items
			local distance = (CanvasPosition:get(false) - Frame.CanvasPosition).Magnitude
			local minimum = itemHeight:get(false)

			if distance < minimum then
				return
			end

			CanvasPosition:set(Frame.CanvasPosition)
		end,

		[Children] = {
			ForPairs(Items, function(i)
				return i,
				New("Frame")({
					Name = "Index_" .. i,
					LayoutOrder = i,
					Size = Computed(function()
						return UDim2.new(itemWidthScale:get(), 0, 0, itemHeight:get())
					end),
					Position = Computed(function()
						local horizontalFit = 1 / itemWidthScale:get()
						return UDim2.new(itemWidthScale:get() * ((i - 1) % horizontalFit), 0, 0, math.floor((i - 1) / horizontalFit) * itemHeight:get())
					end),
					BackgroundTransparency = props._debug and 0.5 or 1,
					BackgroundColor3 = Color3.fromRGB(
						math.random(10, 255),
						math.random(10, 255),
						math.random(10, 255)
					),

					[Children] = props.RenderItem(i),
				})
			end, Fusion.cleanup),
		},
	})

	return Frame
end
