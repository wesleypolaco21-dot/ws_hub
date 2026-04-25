-- WSHUB_TP3_Fixed_Responsive.lua
-- Fully responsive GUI fix

local function convertToScale(guiObject)
    local parent = guiObject.Parent
    if not parent then return end

    local parentSize = parent.AbsoluteSize
    if parentSize.X == 0 or parentSize.Y == 0 then return end

    local absSize = guiObject.AbsoluteSize
    guiObject.Size = UDim2.new(
        absSize.X / parentSize.X, 0,
        absSize.Y / parentSize.Y, 0
    )

    local absPos = guiObject.AbsolutePosition
    local parentPos = parent.AbsolutePosition

    guiObject.Position = UDim2.new(
        (absPos.X - parentPos.X) / parentSize.X, 0,
        (absPos.Y - parentPos.Y) / parentSize.Y, 0
    )
end

local function applyResponsiveFix(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("ImageLabel") then

            convertToScale(obj)

            obj.AnchorPoint = Vector2.new(0.5, 0.5)

            local aspect = Instance.new("UIAspectRatioConstraint")
            aspect.AspectRatio = 1.5
            aspect.Parent = obj

            local sizeConstraint = Instance.new("UISizeConstraint")
            sizeConstraint.MinSize = Vector2.new(200, 150)
            sizeConstraint.MaxSize = Vector2.new(800, 600)
            sizeConstraint.Parent = obj
        end
    end
end

-- RUN
applyResponsiveFix(script.Parent)
