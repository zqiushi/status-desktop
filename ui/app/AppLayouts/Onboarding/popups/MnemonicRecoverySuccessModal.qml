import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Dialogs 1.3

import utils 1.0

import StatusQ.Controls 0.1 as StatusQControls

import shared.panels 1.0
import shared.popups 1.0
import shared.status 1.0
import "../stores"

import StatusQ.Components 0.1

// TODO: replace with StatusModal
ModalPopup {
    id: popup
    //% "Your keys have been successfully recovered"
    title: qsTrId("your-keys-have-been-successfully-recovered")
    height: 400

    signal buttonClicked()

    StyledText {
        id: info
        anchors.top: parent.top
        anchors.topMargin: Style.current.bigPadding
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.current.bigPadding
        anchors.rightMargin: Style.current.bigPadding
        //% "You will have to create a new code or password to re-encrypt your keys"
        text: qsTrId("recovery-success-text")
        font.pixelSize: 15
        color: Style.current.secondaryText
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    StatusSmartIdenticon {
        id: identicon
        anchors.top: info.bottom
        anchors.topMargin: Style.current.bigPadding
        anchors.horizontalCenter: parent.horizontalCenter
        image.source: OnboardingStore.onboardingModuleInst.importedAccountIdenticon
        image.width: 60
        image.height: 60
    }

    StyledText {
        id: username
        anchors.top: identicon.bottom
        anchors.topMargin: Style.current.padding
        anchors.horizontalCenter: identicon.horizontalCenter
        text: OnboardingStore.onboardingModuleInst.importedAccountAlias
        font.weight: Font.Bold
        font.pixelSize: 15
    }

    Address {
        anchors.top: username.bottom
        anchors.topMargin: Style.current.halfPadding
        anchors.horizontalCenter: username.horizontalCenter
        text: OnboardingStore.onboardingModuleInst.importedAccountAddress
        width: 120
    }

    footer: Item {
        width: parent.width
        height: reencryptBtn.height

        StatusQControls.StatusButton {
            id: reencryptBtn
            anchors.bottom: parent.bottom
            anchors.topMargin: Style.current.padding
            anchors.right: parent.right
            //% "Re-encrypt your keys"
            text: qsTrId("re-encrypt-key")

            onClicked: {
                OnboardingStore.accountImported = true
                popup.buttonClicked()
            }
        }
    }
}
