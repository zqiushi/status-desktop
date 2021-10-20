import QtQuick 2.13
import QtQuick.Controls 2.13

import utils 1.0

import shared.popups 1.0
import shared.controls 1.0

// TODO: replace with StatusModal
ModalPopup {
    id: popup

    //% "Open links with..."
    title: qsTrId("open-links-with---")

    onClosed: {
        destroy()
    }

    Column {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: Style.current.padding
        anchors.leftMargin: Style.current.padding

        spacing: 0

        ButtonGroup {
            id: openLinksWithGroup
        }

        RadioButtonSelector {
            title: "Status"
            buttonGroup: openLinksWithGroup
            checked: localAccountSensitiveSettings.openLinksInStatus
            onCheckedChanged: {
                if (checked) {
                    localAccountSensitiveSettings.openLinksInStatus = true
                }
            }
        }
        RadioButtonSelector {
            //% "My default browser"
            title: qsTrId("my-default-browser")
            buttonGroup: openLinksWithGroup
            checked: !localAccountSensitiveSettings.openLinksInStatus
            onCheckedChanged: {
                if (checked) {
                    localAccountSensitiveSettings.openLinksInStatus = false
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
