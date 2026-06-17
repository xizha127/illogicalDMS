import QtQuick
import Quickshell
import Quickshell.Hyprland
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

    // ── Screen → brightness device mapping ─────────────────────────
    // Built from user settings. Format: "eDP-1=backlight:nvidia_0;DP-2=ddc:i2c-2"
    readonly property string deviceMapRaw: pluginData.deviceMap || "eDP-1=backlight:nvidia_0"

    function getDeviceForScreen(screenName: string): string {
        const pairs = deviceMapRaw.split(";")
        for (let i = 0; i < pairs.length; i++) {
            const eq = pairs[i].indexOf("=")
            if (eq > 0 && pairs[i].substring(0, eq).trim() === screenName)
                return pairs[i].substring(eq + 1).trim()
        }
        return "backlight:nvidia_0"  // fallback
    }

    function getFocusedDevice(): string {
        try {
            const name = Hyprland.focusedMonitor?.name || ""
            if (name) return getDeviceForScreen(name)
        } catch (e) {}
        return "backlight:nvidia_0"
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
