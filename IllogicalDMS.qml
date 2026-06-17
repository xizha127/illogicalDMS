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
    readonly property bool showUi: pluginData.showZoneUi ?? true
    readonly property bool autoAlign: pluginData.autoAlign ?? true
    readonly property int sensitivity: pluginData.scrollSensitivity ?? 5
    readonly property int zoneWidthPercent: Math.min(50, pluginData.zoneWidthPercent ?? 20)
    readonly property int zoneHeight: pluginData.zoneHeight || 0
    readonly property int safeSensitivity: Math.max(1, Math.min(50, sensitivity))
    readonly property int barH: barThickness || 48
    readonly property int effectiveZoneHeight: autoAlign ? barH : (zoneHeight > 0 ? zoneHeight : barH)

    // Dynamic zone width: percentage of bar window width, capped at 50%
    readonly property int effectiveZoneWidth: {
        if (!blurBarWindow || blurBarWindow.width <= 0) return 200
        return Math.floor(blurBarWindow.width * zoneWidthPercent / 100)
    }

    // ── Device detection ─────────────────────────────────────────────
    property var screenDevices: ({})
    property bool devicesReady: false
    property int deviceRetries: 0

    function detectDevices(): void {
        if (devicesReady) return
        if (deviceRetries >= 15) {
            // Give up — use direct brightnessctl as fallback
            devicesReady = true
            return
        }
        deviceRetries++
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
                if (lines.length === 0) {
                    // DMS IPC not ready — retry
                    deviceRetryTimer.start()
                    return
                }
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
        onExited: (exitCode) => {
            if (exitCode !== 0 && !devicesReady) deviceRetryTimer.start()
        }
    }

    Timer {
        id: deviceRetryTimer
        interval: 2000
        repeat: false
        onTriggered: detectDevices()
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

    // ── Gamma control (below 0% brightness) ──────────────────────────
    property int currentGamma: 100

    function doGamma(delta: int): void {
        currentGamma = Math.max(0, Math.min(100, currentGamma + delta))
        Quickshell.execDetached(["hyprsunset", "-g", String(currentGamma)])
    }

    function doBrightness(delta: int): void {
        if (delta > 0 && currentGamma < 100) {
            // Gamma is below 100 — increase gamma toward 100 first
            const gStep = Math.min(safeSensitivity, 100 - currentGamma)
            doGamma(gStep)
            return
        }
        if (delta < 0 && currentGamma < 100) {
            // Already in gamma range — decrease gamma further
            doGamma(-safeSensitivity)
            return
        }
        // Normal brightness control (gamma at 100)
        const device = getFocusedDevice()
        if (device) {
            runIpc("brightness", delta > 0 ? "increment" : "decrement", [safeSensitivity, device])
        } else {
            const op = delta > 0 ? "+" : "-"
            Quickshell.execDetached(["brightnessctl", "set", op + safeSensitivity + "%", "--quiet"])
        }
    }

    // ── Scroll zone overlays on the bar window ───────────────────────
    property var leftZone: null
    property var rightZone: null
    property int zoneRetries: 0

    function tryCreateZones(): void {
        if (leftZone !== null) return
        if (!blurBarWindow || !blurBarWindow.contentItem) {
            if (zoneRetries < 20) {
                zoneRetries++
                zoneRetryTimer.start()
            }
            return
        }
        zoneRetries = 0
        const parent = blurBarWindow.contentItem

        const lz = zoneComp.createObject(parent, {
            "anchors.left": parent.left,
            "anchors.top": parent.top,
            "z": 999,
            "zoneColor": showUi ? Qt.rgba(1, 0.84, 0, 0.06) : "transparent"
        })
        leftZone = lz

        const rz = zoneComp.createObject(parent, {
            "anchors.right": parent.right,
            "anchors.top": parent.top,
            "z": 999,
            "zoneColor": showUi ? Qt.rgba(0.31, 0.76, 0.97, 0.06) : "transparent"
        })
        rightZone = rz

        applyZoneDimensions()
    }

    Timer {
        id: zoneRetryTimer
        interval: 500
        repeat: false
        onTriggered: tryCreateZones()
    }

    function applyZoneDimensions(): void {
        if (leftZone) {
            leftZone.width = Qt.binding(() => effectiveZoneWidth)
            leftZone.height = Qt.binding(() => effectiveZoneHeight)
        }
        if (rightZone) {
            rightZone.width = Qt.binding(() => effectiveZoneWidth)
            rightZone.height = Qt.binding(() => effectiveZoneHeight)
        }
    }

    function destroyZones(): void {
        if (leftZone) { leftZone.destroy(); leftZone = null }
        if (rightZone) { rightZone.destroy(); rightZone = null }
    }

    Component.onCompleted: {
        detectDevices()
        Qt.callLater(tryCreateZones)
    }

    Component.onDestruction: destroyZones()

    // React to settings changes
    onZoneWidthPercentChanged: applyZoneDimensions()
    onZoneHeightChanged: applyZoneDimensions()
    onAutoAlignChanged: applyZoneDimensions()
    onBarHChanged: { if (autoAlign) applyZoneDimensions() }

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
                            doBrightness(delta)
                        } else {
                            runIpc("audio", delta > 0 ? "increment" : "decrement", [safeSensitivity])
                        }
                        event.accepted = true
                    }
                }
            }
        }
    }

    // ── Bar pill — invisible, just a hook for the plugin lifecycle ──
    horizontalBarPill: Component {
        Rectangle {
            height: parent.widgetThickness
            width: 1
            color: "transparent"
            visible: false
        }
    }

    verticalBarPill: Component {
        Rectangle {
            width: parent.widgetThickness
            height: 1
            color: "transparent"
            visible: false
        }
    }
}
