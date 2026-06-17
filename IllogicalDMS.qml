import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    readonly property bool scrollEnabled: pluginData.barScrollEnabled ?? true
    readonly property bool alwaysOnTop: pluginData.alwaysOnTop ?? true
    readonly property bool showUi: pluginData.showZoneUi ?? false
    readonly property int sensitivity: pluginData.scrollSensitivity ?? 5
    readonly property int brightnessZoneSize: pluginData.leftZoneWidth ?? 200
    readonly property int volumeZoneSize: pluginData.rightZoneWidth ?? 200

    readonly property bool horizontalMode: width >= height
    readonly property int safeSensitivity: Math.max(1, Math.min(50, sensitivity))
    readonly property color brightnessColor: Theme.tertiary
    readonly property color volumeColor: Theme.primary

    minWidth: 40
    minHeight: 32
    widgetWidth: 800
    widgetHeight: 48

    // ── Auto-detect screen → brightness device mapping ───────────────
    property var screenDevices: ({})
    property bool devicesReady: false

    function detectDevices(): void {
        if (devicesReady) return
        const screens = Quickshell.screens || []
        if (screens.length === 0) return

        // Run "dms ipc brightness list" to get available devices
        const proc = detectProc
        proc.command = ["sh", "-c",
            "dms ipc brightness list 2>/dev/null | grep -E '^(backlight|ddc):' | head -20"]
        proc.running = true
    }

    Process {
        id: detectProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const devices = []
                for (let i = 0; i < lines.length; i++) {
                    const m = lines[i].match(/^(\S+)/)
                    if (m) devices.push(m[1])
                }

                const screens = Quickshell.screens || []
                const map = {}

                // Built-in display (usually first screen) → first backlight device
                const backlights = devices.filter(d => d.startsWith("backlight:"))
                const ddcs = devices.filter(d => d.startsWith("ddc:"))

                // Laptop: built-in screen gets backlight, externals get DDC
                // Desktop: all screens get DDC
                for (let i = 0; i < screens.length; i++) {
                    const name = screens[i].name || ""
                    if (backlights.length > 0 && i === 0) {
                        map[name] = backlights[0]
                    } else if (ddcs.length > 0) {
                        const ddcIdx = Math.min(i - (backlights.length > 0 ? 1 : 0), ddcs.length - 1)
                        map[name] = ddcs[Math.max(0, ddcIdx)]
                    }
                }

                screenDevices = map
                devicesReady = true
            }
        }
    }

    Component.onCompleted: detectDevices()

    function getFocusedDevice(): string {
        if (!devicesReady) detectDevices()
        try {
            const name = Hyprland.focusedMonitor?.name || ""
            if (name && screenDevices[name]) return screenDevices[name]
        } catch (e) {}
        // Fallback: use first known device
        const vals = Object.values(screenDevices)
        return vals.length > 0 ? vals[0] : ""
    }

    // ── IPC helper ─────────────────────────────────────────────────
    function runIpc(target: string, fn: string, args: var): void {
        const cmd = ["dms", "ipc", target, fn]
        for (let i = 0; i < args.length; i++)
            cmd.push(String(args[i]))
        Quickshell.execDetached(cmd)
    }

    function handleBrightnessWheel(event: var): void {
        if (!scrollEnabled || event.angleDelta.y === 0)
            return
        const device = getFocusedDevice()
        if (!device) return
        const action = event.angleDelta.y > 0 ? "increment" : "decrement"
        runIpc("brightness", action, [safeSensitivity, device])
        event.accepted = true
    }

    function handleVolumeWheel(event: var): void {
        if (!scrollEnabled || event.angleDelta.y === 0)
            return
        runIpc("audio", event.angleDelta.y > 0 ? "increment" : "decrement", [safeSensitivity])
        event.accepted = true
    }

    // ── Visual ─────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: "transparent"
        border.width: showUi ? 1 : 0
        border.color: showUi ? Theme.withAlpha(Theme.primary, 0.12) : "transparent"
    }

    MouseArea {
        id: brightnessZone
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        anchors.left: parent.left
        anchors.top: parent.top
        width: root.horizontalMode ? Math.min(root.brightnessZoneSize, parent.width) : parent.width
        height: root.horizontalMode ? parent.height : Math.min(root.brightnessZoneSize, parent.height)
        onWheel: event => root.handleBrightnessWheel(event)

        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: root.showUi ? Theme.withAlpha(root.brightnessColor, brightnessZone.containsMouse ? 0.14 : 0.06) : "transparent"
            border.width: root.showUi ? 1 : 0
            border.color: root.showUi ? Theme.withAlpha(root.brightnessColor, brightnessZone.containsMouse ? 0.45 : 0.18) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        StyledText {
            visible: root.showUi && brightnessZone.containsMouse
            anchors.centerIn: parent
            text: "brightness"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: root.brightnessColor
        }
    }

    MouseArea {
        id: volumeZone
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.horizontalMode ? Math.min(root.volumeZoneSize, parent.width) : parent.width
        height: root.horizontalMode ? parent.height : Math.min(root.volumeZoneSize, parent.height)
        onWheel: event => root.handleVolumeWheel(event)

        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: root.showUi ? Theme.withAlpha(root.volumeColor, volumeZone.containsMouse ? 0.14 : 0.06) : "transparent"
            border.width: root.showUi ? 1 : 0
            border.color: root.showUi ? Theme.withAlpha(root.volumeColor, volumeZone.containsMouse ? 0.45 : 0.18) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        StyledText {
            visible: root.showUi && volumeZone.containsMouse
            anchors.centerIn: parent
            text: "volume"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: root.volumeColor
        }
    }

    StyledText {
        visible: root.showUi && !brightnessZone.containsMouse && !volumeZone.containsMouse
        anchors.centerIn: parent
        text: root.horizontalMode ? "bar scroll zones" : "bar\nscroll\nzones"
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.withAlpha(Theme.surfaceText, 0.5)
    }
}
