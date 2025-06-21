import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    property string displayText: "CPU"
    property bool wattDataAvailable: false
    
    preferredRepresentation: compactRepresentation
    
    compactRepresentation: Item {
        PlasmaComponents3.Label {
            id: powerLabel
            text: displayText
            font.pixelSize: 1024
            minimumPixelSize: theme.smallestFont.pixelSize
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
        }
        
        property bool wasExpanded: false
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPressed: parent.wasExpanded = expanded
            onClicked: expanded = !parent.wasExpanded
            PlasmaComponents3.ToolTip {
                text: i18n("Open HHD Control")
            }
        }
    }
    
    Timer {
        id: wattTimer
        interval: 4000
        running: true
        repeat: true
        onTriggered: getWattData()
    }
    
    Plasma5Support.DataSource {
        id: wattDataSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName) {
            var output = wattDataSource.data[sourceName].stdout.trim()
            if (output) {
                try {
                    var json = JSON.parse(output)
                    if (json.power_watts !== undefined) {
                        displayText = Math.round(json.power_watts) + " W"
                        wattDataAvailable = true
                    }
                } catch (e) {
                    if (!wattDataAvailable) {
                        displayText = "HHD TDP"
                    }
                }
            } else {
                if (!wattDataAvailable) {
                    displayText = "HHD TDP"
                }
            }
            wattDataSource.disconnectSource(sourceName)
        }
    }
    
    function getWattData() {
        var pythonScript = `
import socket
import json
import sys

try:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.settimeout(2)
    client.connect('/tmp/pkg-watt-stat.sock')
    data = client.recv(1024).decode().strip()
    client.close()
    if data:
        print(data)
    else:
        sys.exit(1)
except:
    sys.exit(1)
`
        var command = `python3 -c "${pythonScript}"`
        wattDataSource.connectSource(command)
    }
    
    Component.onCompleted: {
        getWattData()
    }

    fullRepresentation: ColumnLayout {
        spacing: 10
        anchors.margins: 10

        property string hhdToken: ""
        property string hhdApiUrl: "http://localhost:5335/api/v1/state"
        property string hhdSettingsUrl: "http://localhost:5335/api/v1/settings"
        property string debugStatus: "Initializing..."
        
        Component.onCompleted: {
            loadHhdToken()
        }
        
        function loadHhdToken() {
            var tokenCommand = "cat ~/.config/hhd/token"
            debugStatus = "Loading HHD token..."
            tokenLoader.connectSource(tokenCommand)
        }
        
        function loadTdpLimits() {
            if (!hhdToken) {
                debugStatus = "No token available for TDP limits"
                return;
            }
            
            let curlCommand = `curl -s "${hhdSettingsUrl}" -H "Authorization: Bearer ${hhdToken}"`;
            
            debugStatus = "Loading TDP limits..."
            limitsLoader.connectSource(curlCommand);
        }
        
        function loadCurrentTdp() {
            if (!hhdToken) {
                debugStatus = "No token available for current TDP"
                return;
            }
            
            let curlCommand = `curl -s "${hhdApiUrl}" -H "Authorization: Bearer ${hhdToken}"`;
            
            debugStatus = "Loading current TDP..."
            currentTdpLoader.connectSource(curlCommand);
        }
        
        // DataSource for loading HHD token
        Plasma5Support.DataSource {
            id: tokenLoader
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName) {
                hhdToken = tokenLoader.data[sourceName].stdout.trim()
                debugStatus = hhdToken ? "Token loaded ✓" : "Token failed ✗"
                tokenLoader.disconnectSource(sourceName)
                if (hhdToken) {
                    loadTdpLimits()
                    loadCurrentTdp()
                }
            }
        }
        
        // DataSource for loading TDP limits
        Plasma5Support.DataSource {
            id: limitsLoader
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName) {
                var output = limitsLoader.data[sourceName].stdout.trim()
                if (output) {
                    try {
                        var json = JSON.parse(output)
                        if (json.tdp && json.tdp.qam && json.tdp.qam.children && json.tdp.qam.children.tdp) {
                            var tdpConfig = json.tdp.qam.children.tdp
                            if (tdpConfig.min !== undefined && tdpConfig.max !== undefined) {
                                tdpSlider.from = tdpConfig.min
                                tdpSlider.to = tdpConfig.max
                                debugStatus = `TDP limits: ${tdpSlider.from}-${tdpSlider.to}W`
                            }
                        }
                    } catch (e) {
                        debugStatus = "Failed to parse TDP limits"
                    }
                } else {
                    debugStatus = "No TDP limits data received"
                }
                limitsLoader.disconnectSource(sourceName)
            }
        }
        
        // DataSource for loading current TDP
        Plasma5Support.DataSource {
            id: currentTdpLoader
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName) {
                var output = currentTdpLoader.data[sourceName].stdout.trim()
                if (output) {
                    try {
                        var json = JSON.parse(output)
                        if (json.tdp && json.tdp.qam && json.tdp.qam.tdp !== undefined) {
                            var currentTdp = json.tdp.qam.tdp
                            tdpSlider.value = Math.min(Math.max(currentTdp, tdpSlider.from), tdpSlider.to)
                            debugStatus = `Ready - Current TDP: ${currentTdp}W`
                        }
                    } catch (e) {
                        debugStatus = "Failed to parse current TDP"
                    }
                } else {
                    debugStatus = "No current TDP data received"  
                }
                currentTdpLoader.disconnectSource(sourceName)
            }
        }
        
        // DataSource for general command execution
        Plasma5Support.DataSource {
            id: execute
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName) {
                handleOutput(sourceName)
            }
        }


        // Debug Status
        PlasmaComponents3.Label {
            text: debugStatus
            Layout.fillWidth: true
            font.pointSize: 8
            color: PlasmaCore.Theme.disabledTextColor
        }

        // TDP Control
        RowLayout {
            PlasmaComponents3.Label { text: i18n("TDP:") }
            PlasmaComponents3.Slider {
                id: tdpSlider
                from: 3; to: 15; value: 10; stepSize: 1
                Layout.fillWidth: true
                onValueChanged: runCommand1()
            }
            PlasmaComponents3.Label { text: i18n("%1W", tdpSlider.value) }
        }

        Item { Layout.fillWidth: true }

        function handleOutput(sourceName) {
            execute.disconnectSource(sourceName);
        }

        function runHhdCommand(settings) {
            if (!hhdToken) {
                debugStatus = "Error: HHD token not loaded";
                return;
            }
            
            let settingsJson = JSON.stringify(settings);
            let curlCommand = `curl -s -X POST "${hhdApiUrl}" ` +
                           `-H "Authorization: Bearer ${hhdToken}" ` +
                           `-H "Content-Type: application/json" ` +
                           `-d '${settingsJson}'`;
            
            if (settings["tdp.qam.tdp"]) {
                debugStatus = `TDP set to ${settings["tdp.qam.tdp"]}W`;
            }
            execute.connectSource(curlCommand);
        }

        // Command runners
        function runCommand1() {
            let value = tdpSlider.value;
            runHhdCommand({
                "tdp.qam.tdp": value
            });
        }

    }
}
