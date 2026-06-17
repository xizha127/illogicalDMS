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

    // ── Visibility ──
    StyledText {
        width: parent.width
        text: "Visibility"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "alwaysOnTop"
        label: "Always on Top"
        description: "Must be ON. Also enable 'Show on Overlay' in the Desktop Widgets instance settings."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showZoneUi"
        label: "Show Zone UI"
        description: "Colored borders and labels on the bar edges. Scroll works regardless of this setting."
        defaultValue: false
    }

    StyledRect { width: parent.width; height: 1; color: Theme.outlineVariant }

    // ── Behavior ──
    StyledText {
        width: parent.width
        text: "Behavior"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "barScrollEnabled"
        label: "Bar Scroll Control"
        description: "Scroll left edge for brightness, right edge for volume."
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

    // ── Zone Size ──
    StyledText {
        width: parent.width
        text: "Zone Size"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "leftZoneWidth"
        label: "Left Zone Width"
        description: "Width of the brightness zone on the left bar edge."
        defaultValue: 200
        minimum: 40
        maximum: 600
        unit: "px"
    }

    SliderSetting {
        settingKey: "rightZoneWidth"
        label: "Right Zone Width"
        description: "Width of the volume zone on the right bar edge."
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
        text: "Add widget in Desktop Widgets. Set Show on Overlay: ON, Click Through: OFF. Position at screen edges covering the bar."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "deviceMap"
        label: "Device Map"
        description: "Screen→device pairs. Format: eDP-1=backlight:nvidia_0;DP-2=ddc:i2c-2"
        defaultValue: "eDP-1=backlight:nvidia_0"
    }
}
