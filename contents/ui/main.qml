import QtQuick 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.plasmoid 2.0
import QtQuick.Controls 2.5
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    PlasmaComponents3.ToolButton {
        onClicked: plasmoid.expanded = !plasmoid.expanded
        ToolTip.text: i18n("Open TDP Control")
        ToolTip.visible: hovered
    }

    fullRepresentation: ColumnLayout {
        spacing: 10
        anchors.margins: 10

        Plasma5Support.DataSource {
            id: execute
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName) {
                handleOutput(sourceName)
            }
        }


        // TDP Control
        RowLayout {
            PlasmaComponents3.Label { text: i18n("Set Max TDP:") }
            PlasmaComponents3.Slider {
                id: tdpSlider
                from: 3; to: 15; value: 10; stepSize: 1
                Layout.fillWidth: true
            }
            PlasmaComponents3.Label { text: i18n("%1W", tdpSlider.value) }
            PlasmaComponents3.Button {
                text: i18n("Apply")
                onClicked: runCommand1()
            }
        }

        // Temp Control
        RowLayout {
            visible: plasmoid.configuration.tempCheckbox
            PlasmaComponents3.Label { text: i18n("Set Max Temp:") }
            PlasmaComponents3.Slider {
                id: tempSlider
                from: 45; to: 90; value: 80; stepSize: 5
                Layout.fillWidth: true
            }
            PlasmaComponents3.Label { text: i18n("%1°C", tempSlider.value) }
            PlasmaComponents3.Button {
                text: i18n("Apply")
                onClicked: runCommand2()
            }
        }

        // Presets
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            PlasmaComponents3.Button {
                visible: plasmoid.configuration.preset1Checkbox
                text: i18n(plasmoid.configuration.preset1Name)
                onClicked: runCommand3()
            }
            PlasmaComponents3.Button {
                visible: plasmoid.configuration.preset1Checkbox && plasmoid.configuration.preset2Checkbox
                text: i18n(plasmoid.configuration.preset2Name)
                onClicked: runCommand4()
            }
        }

        // Output Text Area
        PlasmaComponents3.TextArea {
            id: outputArea
            Layout.fillWidth: true
            Layout.preferredHeight: 33
            readOnly: true
            placeholderText: i18n("Output will be displayed here...")
        }
        Item { Layout.fillWidth: true }

        function handleOutput(sourceName) {
            var output = execute.data[sourceName].stdout;
            if (output !== undefined && output.length > 0) {
                outputArea.text = output + "\n" + outputArea.text;
            }
            execute.disconnectSource(sourceName);
        }

        function runRyzenAdjCommand(args) {
            let path = "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.desktoptdpcontrol/contents/libs/ryzenadj";
            let safeArgs = args.replace(/(["`\\$])/g, '\\$1');  // basic escaping
            let command = `bash -c "sudo ${path} ${safeArgs}"`;
            execute.connectSource(command);
        }

        // Command runners
        function runCommand1() {
            let value = tdpSlider.value;
            runRyzenAdjCommand(`--stapm-limit=${value}000 --fast-limit=${value}000 --slow-limit=${value}000`);
            updateOutput(`Set Max TDP to ${value}W`);

        }
        function runCommand2() {
            let value = tempSlider.value;
            runRyzenAdjCommand(`--tctl-temp=${value}`);
            updateOutput(`Set Max Temp to ${value}°C`);
        }
        function runCommand3() {
            let value = plasmoid.configuration.preset1String;
            runRyzenAdjCommand(value)
            updateOutput(`Applied Presett 1: ${value}`);
        }
        function runCommand4() {
            let value = plasmoid.configuration.preset2String;
            runRyzenAdjCommand(value)
            updateOutput(`Applied Preset 2: ${value}`);
        }
        function updateOutput(message) {
            outputArea.text = message + "\n" + outputArea.text;
        }
    }
}
import QtQuick 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.plasmoid 2.0
import QtQuick.Controls 2.5
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    PlasmaComponents3.ToolButton {
        onClicked: plasmoid.expanded = !plasmoid.expanded
        ToolTip.text: i18n("Open TDP Control")
        ToolTip.visible: hovered
    }

    fullRepresentation: ColumnLayout {
        spacing: 10
        anchors.margins: 10

        Plasma5Support.DataSource {
            id: execute
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName) {
                handleOutput(sourceName)
            }
        }


        // TDP Control
        RowLayout {
            PlasmaComponents3.Label { text: i18n("Set Max TDP:") }
            PlasmaComponents3.Slider {
                id: tdpSlider
                from: 3; to: 15; value: 10; stepSize: 1
                Layout.fillWidth: true
            }
            PlasmaComponents3.Label { text: i18n("%1W", tdpSlider.value) }
            PlasmaComponents3.Button {
                text: i18n("Apply")
                onClicked: runCommand1()
            }
        }

        // Temp Control
        RowLayout {
            visible: plasmoid.configuration.tempCheckbox
            PlasmaComponents3.Label { text: i18n("Set Max Temp:") }
            PlasmaComponents3.Slider {
                id: tempSlider
                from: 45; to: 90; value: 80; stepSize: 5
                Layout.fillWidth: true
            }
            PlasmaComponents3.Label { text: i18n("%1°C", tempSlider.value) }
            PlasmaComponents3.Button {
                text: i18n("Apply")
                onClicked: runCommand2()
            }
        }

        // Presets
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            PlasmaComponents3.Button {
                visible: plasmoid.configuration.preset1Checkbox
                text: i18n(plasmoid.configuration.preset1Name)
                onClicked: runCommand3()
            }
            PlasmaComponents3.Button {
                visible: plasmoid.configuration.preset1Checkbox && plasmoid.configuration.preset2Checkbox
                text: i18n(plasmoid.configuration.preset2Name)
                onClicked: runCommand4()
            }
        }

        // Output Text Area
        PlasmaComponents3.TextArea {
            id: outputArea
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            readOnly: true
            placeholderText: i18n("Output will be displayed here...")
        }
        Item { Layout.fillWidth: true }

        function handleOutput(sourceName) {
            var output = execute.data[sourceName].stdout;
            if (output !== undefined && output.length > 0) {
                outputArea.text = output + "\n" + outputArea.text;
            }
            execute.disconnectSource(sourceName);
        }

        function runRyzenAdjCommand(args) {
            let path = "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.desktoptdpcontrol/contents/libs/ryzenadj";
            let safeArgs = args.replace(/(["`\\$])/g, '\\$1');  // basic escaping
            let command = `bash -c "sudo ${path} ${safeArgs}"`;
            execute.connectSource(command);
        }

        // Command runners
        function runCommand1() {
            let value = tdpSlider.value;
            runRyzenAdjCommand(`--stapm-limit=${value}000 --fast-limit=${value}000 --slow-limit=${value}000`);


        }
        function runCommand2() {
            let value = tempSlider.value;
            runRyzenAdjCommand(`--tctl-temp=${value}`);

        }
        function runCommand3() {
            let value = plasmoid.configuration.preset1String;
            runRyzenAdjCommand(value)

        }
        function runCommand4() {
            let value = plasmoid.configuration.preset2String;
            runRyzenAdjCommand(value)

        }

    }
}
