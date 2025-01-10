local utils = require 'imports.utils'
local store = require 'imports.store'
local dui = require 'imports.dui'
local config = require 'imports.config'
local indicator = config.defaultIndicatorSprite

local drawLoopRunning = false
local BuilderLoopRunning = false

LocalPlayer.state.interactBusy = false

lib.addKeybind({
    name = 'sleepless_interact:action',
    description = 'Interact',
    defaultKey = 'E',
    onPressed = function(self)
        if store.activeInteraction then
            store.activeInteraction:handleInteract()
        end
    end,
})

store.hidePerKeybind = false
local defaultShowKeyBind = config.defaultShowKeyBind
local showKeyBindBehavior = config.showKeyBindBehavior
local useShowKeyBind = config.useShowKeyBind
if useShowKeyBind then
    store.hidePerKeybind = true
    lib.addKeybind({
        name = 'sleepless_interact:toggle',
        description = 'show interactions',
        defaultKey = defaultShowKeyBind,
        onPressed = function(self)
            if cache.vehicle then return end
            if showKeyBindBehavior == "toggle" then
                store.hidePerKeybind = not store.hidePerKeybind
                if store.hidePerKeybind then
                    BuilderLoopRunning = false
                else
                    BuilderLoop()
                end
            else
                store.hidePerKeybind = false
                BuilderLoop()
            end
        end,
        onReleased = function(self)
            if showKeyBindBehavior == "toggle" or cache.vehicle then return end
            store.hidePerKeybind = true
            BuilderLoopRunning = false
        end
    })
end

local drawPrint = false

local function drawLoop()
    lib.requestStreamedTextureDict(indicator.dict)
    while next(store.nearby) do
        ---@type Interaction | nil
        local newActive = nil
        for i = 1, #store.nearby do
            local interaction = store.nearby[i]
            local active = false

            if not newActive and interaction:shouldBeActive() and utils.checkOptions(interaction) then
                newActive = interaction
                active = true
                if not store.activeInteraction or newActive.id ~= store.activeInteraction.id then
                    store.menuBusy = true
                    dui.updateMenu('updateInteraction', { id = newActive.id, options = interaction.DuiOptions })
                    SetTimeout(100, function()
                        store.menuBusy = false
                    end)
                end
                dui.handleDuiControls()
            end

            if interaction.isActive ~= active then
                interaction.isActive = active
            end

            interaction:drawSprite()
        end

        if (not newActive and store.activeInteraction) or (newActive and store.activeInteraction and store.activeInteraction.id ~= newActive.id) then
            store.activeInteraction.isActive = false
        end

        if store.activeInteraction and not newActive then
          dui.updateMenu('updateInteraction', nil)
        end

        store.activeInteraction = newActive

        if drawPrint then
            drawPrint = false
            print('yes draw loop is running')
        end
        Wait(0)
    end
    SetStreamedTextureDictAsNoLongerNeeded(indicator.dict)
    store.activeInteraction = nil
    drawLoopRunning = false
end

local builderPrint = false

function BuilderLoop()
    if BuilderLoopRunning then return end
    BuilderLoopRunning = true
    while BuilderLoopRunning do
        if utils.shouldHideInteractions() then
            store.nearby = {}
        else
            utils.checkEntities()
            local nearby = {}
            for i = 1, #store.Interactions do
                local interaction = store.Interactions[i]
                if interaction and interaction:shouldRender() and utils.checkOptions(interaction) then
                    nearby[#nearby + 1] = interaction
                end
            end

            table.sort(nearby, function(a, b)
                return a.currentDistance < b.currentDistance
            end)

            store.nearby = nearby

            if #store.nearby > 0 and not drawLoopRunning then
                drawLoopRunning = true
                CreateThread(drawLoop)
            end

            if builderPrint then
                builderPrint = false
                print('yes builder is running')
            end
        end
        Wait(500)
    end
    store.nearby = {}
end

RegisterNetEvent('onResourceStop', function(resourceName)
    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.resource == resourceName then
            store.globalIds[data.id] = nil
            table.remove(store.globalVehicle, i)
        end
    end


    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.resource == resourceName then
            store.globalIds[data.id] = nil
            table.remove(store.globalVehicle, i)
        end
    end


    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.resource == resourceName then
            store.globalIds[data.id] = nil
            table.remove(store.globalVehicle, i)
        end
    end
end)


RegisterCommand('checkInteractions', function(source, args, raw)
    print('==========================================================================================')
    lib.print.info('number of ALL interactions:', #store.Interactions)
    lib.print.info('number of NEARBY interactions:', #store.nearby)
    lib.print.info('is builder running?', BuilderLoopRunning)
    builderPrint = true
    Wait(1000)
    lib.print.info('is draw running?', drawLoopRunning)
    drawPrint = true
    lib.print.info(msgpack.unpack(msgpack.pack(store)))
    print('==========================================================================================')
end)

