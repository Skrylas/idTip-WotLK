
local hooksecurefunc, select, RAID_CLASS_COLORS, UnitIsUnit, UnitExists, UnitClass, UnitName, UnitAura, UnitGUID, GetGlyphSocketInfo, tonumber, strfind =
      hooksecurefunc, select, RAID_CLASS_COLORS, UnitIsUnit, UnitExists, UnitClass, UnitName, UnitAura, UnitGUID, GetGlyphSocketInfo, tonumber, strfind

local types = {
	spell		= "Spell ID:",
	item		= "Item ID:",
	unit		= "NPC ID:",
	quest		= "Quest ID:",
	talent		= "Talent ID:",
	achievement	= "Achievement ID:",
	criteria	= "Criteria ID:",
	ability		= "Ability ID:",
}

local function addLine(tooltip, id, type)
  -- Check if we already added to this tooltip. Happens on the talent frame
  for i = 1, 15 do
    local f = _G[tooltip:GetName() .. "TextLeft" .. i]
    if f and f:GetText() == type then return end
  end

  tooltip:AddDoubleLine(type, "|cffffffff" .. id)
  tooltip:Show()
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
local function handleAura(self, ...)
  local _, rank, _, _, _, _, _, source, _, _, id = UnitAura(...)
  if not id then return end
  local leftText = "ID: |cffffffff"..id.."|r"..((rank and rank:match("%d+")) and " |cffaaaaaa("..rank..")|r" or "")
  local rightText = ""
  local r, g, b = 1, 0.82, 0
  if source then
    local owner = UnitIsUnit(source,"pet") and "player" or source:gsub("[pP][eE][tT]","")
    if UnitExists(owner) then
      local classColor = RAID_CLASS_COLORS[(select(2, UnitClass(owner)))]
      if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
      end
      rightText = (owner==source and "%s" or "%s (%s)"):format(UnitName(owner), UnitName(source))
    end
  end
  self:AddDoubleLine(leftText, rightText, 1,0.82,0, r,g,b)
  self:Show()
end

hooksecurefunc(GameTooltip, "SetUnitBuff", handleAura)
hooksecurefunc(GameTooltip, "SetUnitDebuff", handleAura)
hooksecurefunc(GameTooltip, "SetUnitAura", handleAura)

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
hooksecurefunc("SelectQuestLogEntry", function()
  if not (QuestLogFrame:IsVisible() and QuestLogHighlightFrame:IsMouseOver()) then return end
  local index = GetQuestLogSelection()
  if not index then return end
  local link = GetQuestLink(index)
  if not link then return end
  local id = tonumber(link:match(":(%d+):"))
  if not id then return end
  GameTooltip:SetOwner(QuestLogScrollFrame, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", QuestLogScrollFrame, "TOPRIGHT", 0, 0)
  addLine(GameTooltip, id, types.quest)
end)
