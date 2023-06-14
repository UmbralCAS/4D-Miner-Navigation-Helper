-- Auto-attach to 4D Miner.
getAutoAttachList().add("4D Miner.exe")
-- Forms parameters
--- Stores whether or not the hotkeys are active.
local hotkeysCheckbox
local hotkeysActive = false
--- Hotkeys
---- Stores all of the hotkeys.
local hotkeys = {}
--- Waypoints
---- Stores the Waypoints
local waypoints = {}
---- Makes a waypoints
local newWaypointButton
---- Stores the waypoint buttons
local waypointButtons = {}

-- Configurations.
--- How many blocks to stride on a small step.
local smallStep = 1
--- How many blocks to stride on a large step.
local largeStep = 10

function loc(x, y, z, w)
    local location = {}
    location["player x"] = x
    location["player y"] = y
    location["player z"] = z
    location["player w"] = w
    return location
end

function teleport(destination)
  for axis, position in pairs(destination) do
    print(axis)
    AddressList.getMemoryRecordByDescription(axis).Value = position
  end
end

function FourTTeleportHome(sender)
  --- Create a table with the desination coordinates
  local destination = loc(100.5, 100, 100.5, 100.5)

  teleport(destination)
end

function onChangeHotkeysCheckbox(sender)
  hotkeysActive = sender.Checked
end

function stepAxis(axis, step)
  if hotkeysActive then
    local record = AddressList.getMemoryRecordByDescription(axis)
    record.Value = record.Value + step
  end
end

function hkToggleHotkeysActive()
  hotkeysActive = not hotkeysActive
  hotkeysCheckbox.Checked = hotkeysActive and 1 -- converts a boolean to 0 or 1
end

function onClose()
  print("Shutting Down...")

  for key, hotkey in pairs(hotkeys) do
    hotkey.destroy()
  end

  saveOpenedFile()
  closeCE()
end

function createWaypoint()
    local x = AddressList.getMemoryRecordByDescription("player x").Value
    local y = AddressList.getMemoryRecordByDescription("player y").Value
    local z = AddressList.getMemoryRecordByDescription("player z").Value
    local w = AddressList.getMemoryRecordByDescription("player w").Value
    local pos = loc(x, y, z, w)
    local key
  
    local modal = createForm(false)
      modal.setWidth(264)
      local edit = createEdit(modal)
        edit.setWidth(256)
        edit.setTop(4)
        edit.setLeft(4)
      local label = createLabel(modal)
        label.setCaption("Please name the waypoint.")
        label.setWidth(256)
        label.setTop(28)
        label.setLeft(4)
      local submitButton = createButton(modal)
        submitButton.setCaption("OK")
        submitButton.setWidth(96)
        submitButton.setTop(48)
        submitButton.setLeft(80)
        submitButton.OnClick = function () 
          key = edit.Text
          modal.ModalResult = 0
          modal.close()
      end
  
    modal.showModal()
    waypoints[key] = pos
    writeWaypoints()
  
  end

function readWaypoints()
  local path = "data/waypoints.dat"
  local file = io.open(path, "r")
  if not file then
    file = io.open(path, "w")
    file:close()
    file = io.open(path, "r")
  end
  local line = file:read("l")
  while line do
    local matches = string.gmatch(line, "[%w%.%_]+")
    local data = {}
    local i = 0
    for match in matches do
        data[i] = match
        i = i + 1
    end
    print(data)
    if data and #data == 4 then
        local label = data[0]
        local pos = loc(data[1], data[2], data[3], data[4])
        printf("%s = %f, %f, %f, %f", label, pos["player x"], pos["player y"], pos["player z"], pos["player w"])
        waypoints[label] = pos
    end
    line = file:read("l")
  end
  file:close()
end

function writeWaypoints()
    local file = io.open("data/waypoints.dat", "w")
    for key, pos in pairs(waypoints) do
        file:write(string.format("%s %f %f %f %f\n", key, pos["player x"], pos["player y"], pos["player z"], pos["player w"]))
    end
    file:close()
end

function updateWaypointsButtons(panel)
    -- Clean out old buttons
    for key, button in pairs(waypointButtons) do
        button.destroy()
    end
    readWaypoints()
    -- Make new buttons
    local i = 0
    local j = 0
    for key, pos in pairs(waypoints) do
        waypointButtons[key] = createButton(panel)
            waypointButtons[key].setCaption(key)
            waypointButtons[key].setWidth(108)
            waypointButtons[key].setTop(j * 20)
            waypointButtons[key].setLeft(i * 128)
            waypointButtons[key].OnClick = function () teleport(pos) end
        waypointButtons[i+j] = createButton(panel)
            waypointButtons[i+j].setCaption("X")
            waypointButtons[i+j].setWidth(20)
            waypointButtons[i+j].setTop(j * 20)
            waypointButtons[i+j].setLeft(i * 128 + 100)
            waypointButtons[i+j].OnClick = function () 
                waypoints[key] = nil
                writeWaypoints()
                updateWaypointsButtons(panel)
            end


        if i == 0 then
            i = 1
        else 
            i = 0
            j = j + 1
        end
    end
    panel.setHeight((j + 1) * 20 + 4)
end

function init()
  print("Initializing...")
  print("Registering Hotkeys")
  hotkeys.toggleActive = createHotkey(hkToggleHotkeysActive, {VK_CONTROL, VK_H})
  hotkeys.i = createHotkey(function () stepAxis("player z", smallStep) end, {VK_I})
  hotkeys.k = createHotkey(function () stepAxis("player z", -smallStep) end, {VK_K})
  hotkeys.j = createHotkey(function () stepAxis("player x", smallStep) end, {VK_J})
  hotkeys.l = createHotkey(function () stepAxis("player x", -smallStep) end, {VK_L})
  hotkeys.up = createHotkey(function () stepAxis("player y", smallStep) end, {VK_UP})
  hotkeys.down = createHotkey(function () stepAxis("player y", -smallStep) end, {VK_DOWN})
  hotkeys.left = createHotkey(function () stepAxis("player w", smallStep) end, {VK_LEFT})
  hotkeys.right = createHotkey(function () stepAxis("player w", -smallStep) end, {VK_RIGHT})
  print("Hokteys registered.")
  print("Loading Waypoints...")
  readWaypoints()
  print("Waypoints Loaded.")
  
  -- Generate the form
  local waypointButtonPanel

  local modForm = createForm(false)
  modForm.setOnClose(onClose)
    modForm.setHeight(264)
    modForm.setWidth(264)
    hotkeysCheckbox = createCheckBox(modForm)
      hotkeysCheckbox.Checked = false
      hotkeysCheckbox.OnChange = onChangeHotkeysCheckbox
      hotkeysCheckbox.setCaption("Enable Hotkeys.")
      hotkeysCheckbox.setTop(4)
      hotkeysCheckbox.setLeft(4)
    local waypointsPanel = createPanel(modForm)
        waypointsPanel.setHeight(236)
        waypointsPanel.setWidth(256)
        waypointsPanel.setTop(24)
        waypointsPanel.setLeft(4)
        newWaypointButton = createButton(waypointsPanel)
        newWaypointButton.OnClick = function ()
            local x = AddressList.getMemoryRecordByDescription("player x").Value
            local y = AddressList.getMemoryRecordByDescription("player y").Value
            local z = AddressList.getMemoryRecordByDescription("player z").Value
            local w = AddressList.getMemoryRecordByDescription("player w").Value
            local pos = loc(x, y, z, w)
            local key
            
            local modal = createForm(false)
                modal.setWidth(264)
                local edit = createEdit(modal)
                edit.setWidth(256)
                edit.setTop(4)
                edit.setLeft(4)
                local label = createLabel(modal)
                label.setCaption("Please name the waypoint.")
                label.setWidth(256)
                label.setTop(28)
                label.setLeft(4)
                local submitButton = createButton(modal)
                submitButton.setCaption("OK")
                submitButton.setWidth(96)
                submitButton.setTop(48)
                submitButton.setLeft(80)
                submitButton.OnClick = function () 
                    local replacements
                    key, replacements = string.gsub(edit.Text, "[^%w%.%_]", "_") -- replace magic characters
                    modal.ModalResult = 0
                    modal.close()
                end
            
            modal.showModal()
            waypoints[key] = pos
            writeWaypoints()
            updateWaypointsButtons(waypointButtonPanel)
        end
        newWaypointButton.setWidth(256)
        newWaypointButton.setCaption("New Waypoint")
        waypointButtonPanel = createPanel(waypointsPanel)
          waypointButtonPanel.setWidth(256)
          waypointButtonPanel.setTop(24)
          updateWaypointsButtons(waypointButtonPanel)
  
  hideAllCEWindows()
  modForm.show()
  modForm.centerScreen()
  print("Initilized. Have fun!")
end

init()
