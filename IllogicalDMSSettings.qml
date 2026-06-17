import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "illogicalDMS"

    StyledText {
        width: parent.width
        text: "Illogical DMS"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Scroll bar edges for brightness (left) and volume (right). One widget creates both zones on the bar."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect { width: parent.width; height: 1; color: Theme.outlineVariant }

    // ── Controls ──
    StyledText {
        width: parent.width
        text: "Controls"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "barScrollEnabled"
        label: "Bar Scroll Control"
        description: "Enable scroll-on-bar-edge for brightness (left) and volume (right)."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showZoneUi"
        label: "Show Zone UI"
        description: "Show colored indicator on the bar edge. Scroll works regardless."
        defaultValue: true
    }

    SliderSetting {
        settingKey: "scrollSensitivity"
        label: "Scroll Sensitivity"
        description: "How much each scroll tick changes brightness or volume."
        defaultValue: 5
        minimum: 1
        maximum: 20
        unit: "%"
    }

    StyledRect { width: parent.width; height: 1; color: Theme.outlineVariant }

    // ── Zone ──
    StyledText {
        width: parent.width
        text: "Zone"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "autoAlign"
        label: "Auto-align with Bar"
        description: "Zones automatically match bar height. When off, use the height slider below."
        defaultValue: true
    }

    SliderSetting {
        settingKey: "zoneHeight"
        label: "Zone Height"
        description: "Height of the scroll zones. 0 = auto-detect from bar. Only used when auto-align is off."
        defaultValue: 0
        minimum: 0
        maximum: 800
        unit: "px"
    }

    SliderSetting {
        settingKey: "zoneWidthPercent"
        label: "Zone Width"
        description: "Width of each scroll zone as percentage of bar width. Capped at 50% per side."
        defaultValue: 20
        minimum: 5
        maximum: 50
        unit: "%"
    }

    StyledRect { width: parent.width; height: 1; color: Theme.outlineVariant }

    StyledText {
        width: parent.width
        text: "Setup"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Add one Illogical DMS widget to your bar. Both left (brightness) and right (volume) zones are created automatically on the bar window edges. No Desktop Widgets setup needed."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect { width: parent.width; height: 1; color: Theme.outlineVariant }

    StyledText {
        width: parent.width
        text: "TODO: Multi-bar support — currently targets the bar the widget is placed on. Multiple bars with separate scroll zones not yet supported."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        opacity: 0.6
    }
}
