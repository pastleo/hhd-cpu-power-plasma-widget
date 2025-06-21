

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami


Item {
    id: page

    property alias cfg_outputCheckbox: outputCheckbox.checked
    property alias cfg_preset1Checkbox: preset1Checkbox.checked
    property alias cfg_preset2Checkbox: preset2Checkbox.checked
    property alias cfg_preset1String: preset1String.text
    property alias cfg_preset2String: preset2String.text
    property alias cfg_preset1Name: preset1Name.text
    property alias cfg_preset2Name: preset2Name.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        CheckBox {
            id: outputCheckbox
            Kirigami.FormData.label: i18n("Output TextArea:")
        }


        CheckBox {
            id: preset1Checkbox
            Kirigami.FormData.label: i18n("Preset shortcut:")
        }
        ColumnLayout {
            visible: preset1Checkbox.checked

            TextField {
            id: preset1Name
            placeholderText: i18n("Your preset name...")
            }
            RowLayout {
            TextField {
            id: preset1String
            placeholderText: i18n("Example: 15 (for 15W TDP)")
            }
            Button {
            text: i18n("List")
            onClicked: usageDialog.open()
            }
            }
        }


        CheckBox {
            visible: preset1Checkbox.checked
            id: preset2Checkbox
            Kirigami.FormData.label: i18n("Preset shortcut:")
        }
        ColumnLayout {
            visible: preset1Checkbox.checked && preset2Checkbox.checked
            TextField {
            id: preset2Name
            placeholderText: i18n("Your preset name...")
            }
            TextField {
            id: preset2String
            placeholderText: i18n("Example: 10 (for 10W TDP)")
            }
        }



    }

    Dialog {
        id: usageDialog
        title: i18n("Settings")
        modal: true
        width: 700
        height: 400

        ScrollView {
            anchors.fill: parent
            // horizontalScrollBarPolicy: ScrollBar.AlwaysOn
            TextArea {
                id: settingsTextArea
                readOnly: true
                wrapMode: TextEdit.Wrap
                text: "HHD TDP Control\n\n" +
                      "Enter TDP values in watts (W) for your presets.\n\n" +
                      "Example: 15 (sets TDP to 15W)\n\n" +
                      "The widget will communicate with HHD daemon to set TDP limits.\n" +
                      "Make sure HHD is running and accessible at localhost:5335."
            }
        }
    }

}
