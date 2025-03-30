local HttpService = game:GetService("HttpService")

local Fusion = require(game.ReplicatedStorage.Packages.Fusion)
local peek = Fusion.peek

local VirtualScroller = require(game.ReplicatedStorage.VirtualScroller)

local scope = Fusion:scoped()

local t = {}
for i=1,1000 do
	table.insert(t, HttpService:GenerateGUID(false))
end

local items = scope:Value(t)
local item_count = scope:Computed(function(use)
	return #use(items)
end)
local item_height = scope:Value(150)
local item_width_scale = scope:Value(0.25)

local function render_item(use: Fusion.Use, scope: any, index: number): Frame?
	local item = use(items)[index]
	
	if not index then
		return nil
	end
	
	return scope:New("Frame"){
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(math.random(0, 255), math.random(0,255), math.random(0, 255)),
		
		[Fusion.Children] = scope:New("TextLabel"){
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			TextStrokeTransparency = 0,
			Text = `Index: {index}, Item: {item}`,
			TextScaled = true,
		}
	}
end

scope:New("ScreenGui"){
	Parent = game:GetService("Players").LocalPlayer.PlayerGui,
	[Fusion.Children] = {
		scope:New("Frame"){
			Size = UDim2.fromScale(1, 1),
			[Fusion.Children] = VirtualScroller(scope, {
				AnchorPoint = nil, -- Vector2?
				Position = nil, -- UDim2?
				Size = nil, -- UDim2?
				Visible = true, -- boolean?
				ItemCount = item_count,  -- Fusion.StateObject<number>
				ItemHeight = item_height, -- Fusion.Value<any, number>
				ItemWidthScale = item_width_scale, -- Fusion.Value<any, number>
				CanvasPosition = scope:Value(Vector2.new()), -- Fusion.Value<any, Vector2>
				Deviation = nil, -- number? (default to 0)
				RenderItem = render_item, -- (use: Fusion.Use, scope: any, index: number) -> Instance?
				_debug = false -- boolean?
			})
		}
	}
}
