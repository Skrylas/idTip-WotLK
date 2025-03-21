local hooksecurefunc, select, UnitBuff, UnitDebuff, UnitAura, UnitGUID, GetGlyphSocketInfo, tonumber, strfind =
      hooksecurefunc, select, UnitBuff, UnitDebuff, UnitAura, UnitGUID, GetGlyphSocketInfo, tonumber, strfind

local types = {
	spell		= "SpellID:",
	item		= "ItemID:",
	unit		= "NPC ID:",
	quest		= "QuestID:",
	talent		= "TalentID:",
	achievement	= "AchievementID:",
	criteria	= "CriteriaID:",
	ability		= "AbilityID:",
}

local function addLine(tooltip, id, type, source)
    local found = false

    -- Check if we already added to this tooltip. Happens on the talent frame
    for i = 1,15 do
        local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
        local text
        if frame then text = frame:GetText() end
        if text and text == type then found = true break end
    end

    if not found then
      if source then
        tooltip:AddDoubleLine(type.." |cffffffff" .. id, source)
      else
        tooltip:AddDoubleLine(type, "|cffffffff" .. id)
      end
        tooltip:Show()
    end
end

-- All types, primarily for detached tooltips
local function onSetHyperlink(self, link)
    local type, id = string.match(link,"^(%a+):(%d+)")
    if not type or not id then return end
    if type == "spell" or type == "enchant" or type == "trade" then
        addLine(self, id, types.spell)
    elseif type == "talent" then
        addLine(self, id, types.talent)
    elseif type == "quest" then
        addLine(self, id, types.quest)
    elseif type == "achievement" then
        addLine(self, id, types.achievement)
    elseif type == "item" then
        addLine(self, id, types.item)
    end
end

hooksecurefunc(ItemRefTooltip, "SetHyperlink", onSetHyperlink)
hooksecurefunc(GameTooltip, "SetHyperlink", onSetHyperlink)

-- Spells
hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
    local caster, _, _, id = select(8, UnitAura(...))
    if caster then
		  local name = UnitName(caster)
      if id then 
        addLine(self, id, types.spell, name)
      end
		else
      if id then 
        addLine(self, id, types.spell)
      end
		end
end)

hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self,...)
  local caster, _, _, id = select(8, UnitAura(...))
  if caster then
    local name = UnitName(caster)
    if id then 
      addLine(self, id, types.spell, name)
    end
  else
    if id then 
      addLine(self, id, types.spell)
    end
  end
end)

hooksecurefunc(GameTooltip, "SetUnitAura", function(self,...)
  local caster, _, _, id = select(8, UnitAura(...))
  if caster then
    local name = UnitName(caster)
    if id then 
      addLine(self, id, types.spell, name)
    end
  else
    if id then 
      addLine(self, id, types.spell)
    end
  end
end)

hooksecurefunc("SetItemRef", function(link, ...)
    local id = tonumber(link:match("spell:(%d+)"))
    if id then addLine(ItemRefTooltip, id, types.spell) end
end)

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
    local id = select(3, self:GetSpell())
    if id then addLine(self, id, types.spell) end
end)

-- NPCs
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
  local unit = select(2, self:GetUnit())
  if unit then
    local id = tonumber((UnitGUID(unit)):sub(-10, -7), 16)
    if id > 0 then addLine(GameTooltip, id, types.unit) end
  end
end)

-- Items
local function attachItemTooltip(self)
  local link = select(2, self:GetItem())
  if link then
    local id = string.match(link, "item:(%d*)")
    if (id == "" or id == "0") and TradeSkillFrame ~= nil and TradeSkillFrame:IsVisible() and GetMouseFocus().reagentIndex then
      local selectedRecipe = TradeSkillFrame.RecipeList:GetSelectedRecipeID()
      for i = 1, 8 do
        if GetMouseFocus().reagentIndex == i then
          id = C_TradeSkillUI.GetRecipeReagentItemLink(selectedRecipe, i):match("item:(%d+):") or nil
          break
        end
      end
    end
    if id then
      addLine(self, id, types.item)
    end
  end
end

GameTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)

-- Achievement Frame Tooltips
local f = CreateFrame("frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, what)
	if what == "Blizzard_AchievementUI" then
		for i,button in ipairs(AchievementFrameAchievementsContainer.buttons) do
			button:HookScript("OnEnter", function()
			GameTooltip:SetOwner(button, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
			addLine(GameTooltip, button.id, types.achievement)
			GameTooltip:Show()
		end)
			button:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		      local hooked = {}
      hooksecurefunc("AchievementButton_GetCriteria", function(index, renderOffScreen)
        local frame = _G["AchievementFrameCriteria" .. (renderOffScreen and "OffScreen" or "") .. index]
        if frame and not hooked[frame] then
          frame:HookScript("OnEnter", function(self)
            local button = self:GetParent() and self:GetParent():GetParent()
            if not button or not button.id then return end
            local criteriaid = select(10, GetAchievementCriteriaInfo(button.id, index))
            if criteriaid then
              GameTooltip:SetOwner(button:GetParent(), "ANCHOR_NONE")
              GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
              addLine(GameTooltip, button.id, types.achievement)
              addLine(GameTooltip, criteriaid, types.criteria)
              GameTooltip:Show()
            end
          end)
          frame:HookScript("OnLeave", function()
            GameTooltip:Hide()
          end)
          hooked[frame] = true
        end
      end)
    end
	end
end)

-- Quests
hooksecurefunc("SelectQuestLogEntry", function(self)
local index = GetQuestLogSelection()
	if QuestLogFrame:IsVisible() then
	if not index then return end
	local link = GetQuestLink(index)
	if not link then return end

	local id = tonumber(link:match(":(%d+):"))
	local f = CreateFrame("frame")
		GameTooltip:SetOwner(QuestLogScrollFrame, "ANCHOR_NONE");
		GameTooltip:SetPoint("TOPLEFT", QuestLogScrollFrame, "TOPRIGHT", 0, 0)
		addLine(GameTooltip, id, types.quest)
		GameTooltip:Show()
		f:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
    end
end)