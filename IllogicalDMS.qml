import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var popoutService: null

    // ── Settings ──────────────────────────────────────────────────────
    readonly property bool scrollEnabled: pluginData.barScrollEnabled ?? true
    readonly property bool showUi: pluginData.showZoneUi ?? false
    readonly property int sensitivity: pluginData.scrollSensitivity ?? 5
    readonly property int zoneWidth: pluginData.leftZoneWidth ?? 200
    readonly property string zoneSide: pluginData.zoneSide ?? "left"

    readonly property int safeSensitivity: Math.max(1, Math.min(50, sensitivity))
    readonly property bool isLeft: zoneSide === "left"
    readonly property color zoneColor: isLeft ? Theme.tertiary : Theme.primary
    readonly property string zoneIcon: isLeft ? "brightness" : "volume"

    // ── Screen → brightness device mapping ─────────────────────────
    property var screenDevices: ({})
    property bool devicesReady: false

    function detectDevices(): void {
        if (devicesReady) return
        const screens = Quickshell.screens || []
        if (screens.length === 0) return
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
                const backlights = devices.filter(d => d.startsWith("backlight:"))
                const ddcs = devices.filter(d => d.startsWith("ddc:"))

                for (let i = 0; i < screens.length; i++) {
                    const name = screens[i].name || ""
                    if (backlights.length > 0 && i === 0)
                        map[name] = backlights[0]
                    else if (ddcs.length > 0) {
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
        const vals = Object.values(screenDevices)
        return vals.length > 0 ? vals[0] : ""
    }

    // ── IPC ──────────────────────────────────────────────────────────
    function runIpc(target: string, fn: string, args: var): void {
        const cmd = ["dms", "ipc", target, fn]
        for (let i = 0; i < args.length; i++)
            cmd.push(String(args[i]))
        Quickshell.execDetached(cmd)
    }

    function doBrightness(delta: int): void {
        if (!scrollEnabled || delta === 0) return
        const device = getFocusedDevice()
        if (!device) return
        runIpc("brightness", delta > 0 ? "increment" : "decrement", [safeSensitivity, device])
    }

    function doVolume(delta: int): void {
        if (!scrollEnabled || delta === 0) return
        runIpc("audio", delta > 0 ? "increment" : "decrement", [safeSensitivity])
    }

    // ── Horizontal bar pill ──────────────────────────────────────────
    horizontalBarPill: Component {
        Row {
            height: parent.widgetThickness
            spacing: 0

            // Visual indicator at the bar edge
            StyledRect {
                height: parent.height
                width: 26
                radius: isLeft ? Theme.cornerRadius : 0
                color: showUi ? Theme.withAlpha(zoneColor, 0.15) : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: isLeft ? "☀" : "🔊"
                    font.pixelSize: Theme.fontSizeSmall
                    color: showUi ? zoneColor : "transparent"
                    opacity: showUi ? 0.7 : 0
                }
            }

            // Scroll zone — fills remaining width
            StyledRect {
                height: parent.height
                width: Math.max(0, zoneWidth - 26)
                color: showUi ? (scrollHoverH.containsMouse
                    ? Theme.withAlpha(zoneColor, 0.10)
                    : Theme.withAlpha(zoneColor, 0.03)) : "transparent"
                radius: isLeft ? 0 : Theme.cornerRadius

                Behavior on color { ColorAnimation { duration: 150 } }

                StyledText {
                    visible: showUi && scrollHoverH.containsMouse
                    anchors.centerIn: parent
                    text: zoneIcon
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: zoneColor
                    opacity: 0.8
                }

                MouseArea {
                    id: scrollHoverH
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        if (isLeft) doBrightness(event.angleDelta.y)
                        else doVolume(event.angleDelta.y)
                        event.accepted = true
                    }
                }
            }
        }
    }

    // ── Vertical bar pill ────────────────────────────────────────────
    verticalBarPill: Component {
        Column {
            width: parent.widgetThickness
            spacing: 0

            StyledRect {
                width: parent.width
                height: 26
                radius: isLeft ? Theme.cornerRadius : 0
                color: showUi ? Theme.withAlpha(zoneColor, 0.15) : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: isLeft ? "☀" : "🔊"
                    font.pixelSize: Theme.fontSizeSmall
                    color: showUi ? zoneColor : "transparent"
                    opacity: showUi ? 0.7 : 0
                    rotation: 90
                }
            }

            StyledRect {
                width: parent.width
                height: Math.max(0, zoneWidth - 26)
                color: showUi ? (scrollHoverV.containsMouse
                    ? Theme.withAlpha(zoneColor, 0.10)
                    : Theme.withAlpha(zoneColor, 0.03)) : "transparent"
                radius: isLeft ? 0 : Theme.cornerRadius

                Behavior on color { ColorAnimation { duration: 150 } }

                StyledText {
                    visible: showUi && scrollHoverV.containsMouse
                    anchors.centerIn: parent
                    text: zoneIcon
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: zoneColor
                    opacity: 0.8
                    rotation: 90
                }

                MouseArea {
                    id: scrollHoverV
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        if (isLeft) doBrightness(event.angleDelta.y)
                        else doVolume(event.angleDelta.y)
                        event.accepted = true
                    }
                }
            }
        }
    }
}
