
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        
        Label {
            text: i18n("No configuration options available")
        }
    }
}
