import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    property var popoutService: null

    popoutWidth: 420
    popoutHeight: 360

    // ── Bar pill ──────────────────────────────────────────
    horizontalBarPill: Component {
        StyledRect {
            width: pillLabel.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                id: pillLabel
                anchors.centerIn: parent
                text: "ii"
                color: Theme.primary
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            height: pillLabelV.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                id: pillLabelV
                anchors.centerIn: parent
                text: "ii"
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                rotation: 90
            }
        }
    }

    // ── Popout ────────────────────────────────────────────
    popoutContent: Component {
        PopoutComponent {
            headerText: "Illogical DMS"
            detailsText: "v0.1.0"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM
                topPadding: Theme.spacingM
                leftPadding: Theme.spacingM
                rightPadding: Theme.spacingM

                StyledText {
                    text: "Illogical-impulse features coming to DMS."
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.WordWrap
                    width: parent.width - Theme.spacingM * 2
                }

                StyledText {
                    text: "Modules planned: system info, resource monitor, weather, quick actions."
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                    width: parent.width - Theme.spacingM * 2
                }
            }
        }
    }
}
