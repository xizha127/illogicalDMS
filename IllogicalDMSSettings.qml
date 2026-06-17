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
        text: "Brings illogical-impulse features to DankMaterialShell."
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

    SelectionSetting {
        settingKey: "zoneSide"
        label: "Zone Side"
        description: "Left = brightness, Right = volume. Add two widgets: one in left section, one in right."
        options: [
            { label: "Brightness (Left)", value: "left" },
            { label: "Volume (Right)", value: "right" }
        ]
        defaultValue: "left"
    }

    SliderSetting {
        settingKey: "leftZoneWidth"
        label: "Zone Width"
        description: "Width of the scroll zone on the bar edge."
        defaultValue: 200
        minimum: 40
        maximum: 600
        unit: "px"
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
        text: "Add two widgets in Bar Settings. Set one to Brightness in the left section, one to Volume in the right section. Place them as the first widget in their section so the scroll zone sits at the bar edge."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
