local ScreenBase = require("../navigation/ScreenBase")
local Appearance = require("../../character/appearance/Appearance")
local AppearanceManager = require("../../character/appearance/AppearanceManager")
local FaceStyleSelector = require("FaceStyleSelector")
local PartSelector = require("PartSelector")
local PartOptionsEditor = require("PartOptionsEditor")

local AppearancesM = require("../../character/appearance/Appearances")
local Appearances = gdglobal("Appearances") :: AppearancesM.Appearances

local PartDatabaseM = require("../../character/appearance/parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

--- @class
--- @extends ScreenBase
--- @permissions FILE
local CharacterEditor = {}
local CharacterEditorC = gdclass(CharacterEditor)

--- @classType CharacterEditor
export type CharacterEditor = ScreenBase.ScreenBase & typeof(CharacterEditor) & {
    --- @property
    nameEdit: LineEdit,

    --- @property
    presets: Control,
    --- @property
    appearanceManager: AppearanceManager.AppearanceManager,

    --- @property
    scaleEdit: HSlider,

    --- @property
    eyesSelector: FaceStyleSelector.FaceStyleSelector,
    --- @property
    eyeColorPicker: ColorPickerButton,
    --- @property
    eyebrowsSelector: FaceStyleSelector.FaceStyleSelector,
    --- @property
    mouthSelector: FaceStyleSelector.FaceStyleSelector,

    --- @property
    optionsEditorContainer: Control,

    partSelectors: {PartSelector.PartSelector},
    partOptions: {[string]: Dictionary},
    optionsEditors: {[string]: PartOptionsEditor.PartOptionsEditor},
    updatingFromAppearance: boolean,
}

local optionsEditorScene: PackedScene = assert(load("part_options_editor.tscn"))

function CharacterEditor._Init(self: CharacterEditor)
    self.partSelectors = {}
    self.partOptions = {}
    self.optionsEditors = {}
end

function CharacterEditor._Ready(self: CharacterEditor)
    ScreenBase._Ready(self)

    -- Initialize preview
    self.appearanceManager.appearance = Appearances.current

    -- Update name editor
    self.nameEdit.textChanged:Connect(Callable.new(self, "_OnNameEditChanged"))

    -- Initialize scale editor
    self.scaleEdit.valueChanged:Connect(Callable.new(self, "_OnScaleEditChanged"))

    -- Load presets
    local PRESETS_DIR = "res://resources/character_presets/"
    local dir = DirAccess.Open(PRESETS_DIR)
    assert(dir, "Failed to open presets directory")

    dir:ListDirBegin()

    local presets: {Appearance.Appearance} = {}
    local fileName = dir:GetNext()

    while fileName ~= "" do
        assert(not dir:CurrentIsDir())

        local preset = assert(load(PRESETS_DIR .. fileName)) :: Appearance.Appearance
        table.insert(presets, preset)

        fileName = dir:GetNext()
    end

    table.sort(presets, function(a, b)
        return a.name < b.name
    end)

    for _, preset in presets do
        local button = Button.new()
        button.name = preset.name
        button.text = preset.name
        button.alignment = Enum.HorizontalAlignment.LEFT
        button:AddThemeFontSizeOverride("font_size", 12)
        button.pressed:Connect(Callable.new(self, "_OnPresetPressed"):Bind(preset))

        self.presets:AddChild(button)
    end

    -- Initialize face editor
    self.eyesSelector.selectionChanged:Connect(Callable.new(self, "_OnFaceStyleChanged"))
    self.eyeColorPicker.colorChanged:Connect(Callable.new(self, "_OnEyeColorChanged"))
    self.eyebrowsSelector.selectionChanged:Connect(Callable.new(self, "_OnFaceStyleChanged"))
    self.mouthSelector.selectionChanged:Connect(Callable.new(self, "_OnFaceStyleChanged"))

    -- Initialize part selectors
    local PART_SELECTORS = {
        "%OutfitSelector",
        "%HairSelector",
        "%ShoesSelector",
        "%HatSelector",
        "%EarsSelector",
        "%TailSelector",
        "%AccessoriesSelector",
    }

    for _, path in PART_SELECTORS do
        local selector = self:GetNode(path) :: PartSelector.PartSelector
        table.insert(self.partSelectors, selector)

        selector.selectionChanged:Connect(Callable.new(self, "_OnPartSelectionChanged"))
    end

    -- Load
    self:updateFromAppearance()
end

function CharacterEditor.createOptionsEditor(self: CharacterEditor, id: string)
    local editor = optionsEditorScene:Instantiate() :: PartOptionsEditor.PartOptionsEditor
    editor.id = id

    editor.optionChanged:Connect(Callable.new(self, "_OnOptionChanged"):Bind(id))

    self.optionsEditorContainer:AddChild(editor)
    return editor
end

function CharacterEditor.updateOptions(self: CharacterEditor, fromAppearance: boolean?)
    local newEditors = {}

    for id: string, options: Dictionary? in Appearances.current.attachedParts do
        local partData = PartDatabase:GetPart(id)
        if not partData then
            continue
        end

        if fromAppearance then
            if options then
                self.partOptions[id] = options
            end
        elseif not self.partOptions[id] then
            local actualOptions = options or partData.optionsSchema
            if actualOptions:Size() > 0 then
                self.partOptions[id] = actualOptions
            end
        end

        if partData.optionsSchema:Size() > 0 then
            local editor = self.optionsEditors[id] or self:createOptionsEditor(id)
            editor:Update(self.partOptions[id])
            newEditors[id] = editor
        end
    end

    for id, editor in self.optionsEditors do
        if not newEditors[id] then
            editor:QueueFree()
        end
    end

    self.optionsEditors = newEditors
end

function CharacterEditor.updateFromAppearance(self: CharacterEditor)
    self.updatingFromAppearance = true

    local appearance = Appearances.current

    self.nameEdit.text = appearance.name

    self.appearanceManager:LoadAppearance()

    self.scaleEdit.value = appearance.scale

    self.eyesSelector:SetSelectionId(appearance.eyes)
    self.eyeColorPicker.color = appearance.eyesColor
    self.eyebrowsSelector:SetSelectionId(appearance.eyebrows)
    self.mouthSelector:SetSelectionId(appearance.mouth)

    for _, selector in self.partSelectors do
        local parts = appearance:GetPartsOfScope(selector.scope)
        selector:SetSelectionIds(parts)
    end

    self:updateOptions(true)

    self.updatingFromAppearance = false
end

--- @registerMethod
function CharacterEditor._OnNameEditChanged(self: CharacterEditor, new: string)
    Appearances.current.name = new
end

--- @registerMethod
function CharacterEditor._OnScaleEditChanged(self: CharacterEditor, value: number)
    Appearances.current.scale = value
    self.appearanceManager:LoadAppearance()
end

--- @registerMethod
function CharacterEditor._OnPresetPressed(self: CharacterEditor, preset: Appearance.Appearance)
    Appearances.current:CopyFrom(preset)
    self:updateFromAppearance()
end

--- @registerMethod
function CharacterEditor._OnFaceStyleChanged(self: CharacterEditor)
    if self.updatingFromAppearance then
        return
    end

    local appearance = Appearances.current
    appearance.eyes = self.eyesSelector:GetSelectionId()
    appearance.eyebrows = self.eyebrowsSelector:GetSelectionId()
    appearance.mouth = self.mouthSelector:GetSelectionId()

    self.appearanceManager:LoadAppearance()
end

--- @registerMethod
function CharacterEditor._OnEyeColorChanged(self: CharacterEditor, color: Color)
    if self.updatingFromAppearance then
        return
    end

    Appearances.current.eyesColor = color
    self.appearanceManager:LoadAppearance()
end

--- @registerMethod
function CharacterEditor._OnPartSelectionChanged(self: CharacterEditor)
    if self.updatingFromAppearance then
        return
    end

    local attachedParts = Dictionary.new()

    for _, selector in self.partSelectors do
        if selector.multiSelection then
            for _, id in selector:GetSelectionIds() do
                attachedParts:Set(id, self.partOptions[id])
            end
        elseif selector.selectedButton then
            local id = selector:GetSelectionIds()[1]
            attachedParts:Set(id, self.partOptions[id])
        end
    end

    Appearances.current.attachedParts = attachedParts
    self.appearanceManager:LoadAppearance()

    self:updateOptions()
end

--- @registerMethod
function CharacterEditor._OnOptionChanged(self: CharacterEditor, key: string, value: Variant, partId: string)
    local attachedParts = Appearances.current.attachedParts
    if not attachedParts:Has(partId) then
        return
    end

    local data = attachedParts:Get(partId)
    assert(typeof(data) == "Dictionary")

    data:Set(key, value)

    self.appearanceManager:LoadAppearance()
end

return CharacterEditorC
