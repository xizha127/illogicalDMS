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

    readonly property bool scrollEnabled: pluginData.barScrollEnabled ?? true
    readonly property bool showUi: pluginData.showZoneUi ?? true
    readonly property int sensitivity: pluginData.scrollSensitivity ?? 5
    readonly property int zoneWidth: pluginData.leftZoneWidth ?? 200
    readonly property int safeSensitivity: Math.max(1, Math.min(50, sensitivity))
    readonly property color brightColor: Theme.tertiary
    readonly property color volumeColor: Theme.primary

    // ── Device detection ─────────────────────────────────────────────
    property var screenDevices: ({})
    property bool devicesReady: false

    function detectDevices(): void {
        if (devicesReady) return
        detectProc.command = ["sh", "-c",
            "dms ipc brightness list 2>/dev/null | grep -E '^(backlight|ddc):' | head -20"]
        detectProc.running = true
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
                const bl = devices.filter(d => d.startsWith("backlight:"))
                const ddc = devices.filter(d => d.startsWith("ddc:"))
                for (let i = 0; i < screens.length; i++) {
                    const name = screens[i].name || ""
                    if (bl.length > 0 && i === 0) map[name] = bl[0]
                    else if (ddc.length > 0) {
                        const idx = Math.min(Math.max(0, i - (bl.length > 0 ? 1 : 0)), ddc.length - 1)
                        map[name] = ddc[idx]
                    }
                }
                screenDevices = map
                devicesReady = true
            }
        }
    }

    function getFocusedDevice(): string {
        if (!devicesReady) detectDevices()
        try {
            const name = Hyprland.focusedMonitor?.name || ""
            if (name && screenDevices[name]) return screenDevices[name]
        } catch (e) {}
        const vals = Object.values(screenDevices)
        return vals.length > 0 ? vals[0] : ""
    }

    function runIpc(target: string, fn: string, args: var): void {
        const cmd = ["dms", "ipc", target, fn]
        for (let i = 0; i < args.length; i++) cmd.push(String(args[i]))
        Quickshell.execDetached(cmd)
    }

    // ── Scroll zone overlays on the bar window ───────────────────────
    property var leftZone: null
    property var rightZone: null
    property var zoneUiLeft: null
    property var zoneUiRight: null

    function ensureZones(): void {
        if (leftZone !== null) return
        if (!blurBarWindow || !blurBarWindow.contentItem) return
        const parent = blurBarWindow.contentItem

        // Left zone — brightness
        const lz = zoneComp.createObject(parent, {
            "anchors.left": parent.left,
            "anchors.top": parent.top,
            "anchors.bottom": parent.bottom,
            "z": 999,
            "zoneColor": showUi ? Qt.rgba(1, 0.84, 0, 0.06) : "transparent"
        })
        leftZone = lz

        // Right zone — volume
        const rz = zoneComp.createObject(parent, {
            "anchors.right": parent.right,
            "anchors.top": parent.top,
            "anchors.bottom": parent.bottom,
            "z": 999,
            "zoneColor": showUi ? Qt.rgba(0.31, 0.76, 0.97, 0.06) : "transparent"
        })
        rightZone = rz

        updateZoneWidths()
    }

    function updateZoneWidths(): void {
        if (leftZone) leftZone.width = Qt.binding(() => zoneWidth)
        if (rightZone) rightZone.width = Qt.binding(() => zoneWidth)
    }

    function destroyZones(): void {
        if (leftZone) { leftZone.destroy(); leftZone = null }
        if (rightZone) { rightZone.destroy(); rightZone = null }
    }

    Component.onCompleted: {
        detectDevices()
        Qt.callLater(ensureZones)
    }

    Component.onDestruction: destroyZones()

    onZoneWidthChanged: updateZoneWidths()
    onShowUiChanged: {
        if (leftZone) leftZone.zoneColor = showUi ? Qt.rgba(1, 0.84, 0, 0.06) : "transparent"
        if (rightZone) rightZone.zoneColor = showUi ? Qt.rgba(0.31, 0.76, 0.97, 0.06) : "transparent"
    }

    Component {
        id: zoneComp
        Rectangle {
            id: zoneRect
            color: "transparent"

            property alias zoneColor: bg.color
            property alias bg: bg

            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Theme.cornerRadius

                StyledText {
                    anchors.centerIn: parent
                    text: zoneRect === leftZone ? "☀" : "🔊"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.withAlpha(zoneRect === leftZone ? "#FFD700" : "#4FC3F7", 0.6)
                    visible: showUi && zoneMouse.containsMouse
                }

                MouseArea {
                    id: zoneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        if (!scrollEnabled || event.angleDelta.y === 0) return
                        const delta = event.angleDelta.y
                        if (zoneRect === leftZone) {
                            const device = getFocusedDevice()
                            if (!device) return
                            runIpc("brightness", delta > 0 ? "increment" : "decrement", [safeSensitivity, device])
                        } else {
                            runIpc("audio", delta > 0 ? "increment" : "decrement", [safeSensitivity])
                        }
                        event.accepted = true
                    }
                }
            }
        }
    }

    // ── Bar pill — minimal, just an indicator that the plugin is active ──
    horizontalBarPill: Component {
        StyledText {
            height: parent.widgetThickness
            width: 0  // invisible pill — scroll zones are on the bar window
            visible: false
            text: ""
        }
    }

    verticalBarPill: Component {
        StyledText {
            width: parent.widgetThickness
            height: 0
            visible: false
            text: ""
        }
    }
}
