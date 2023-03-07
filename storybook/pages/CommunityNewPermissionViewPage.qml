import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import AppLayouts.Chat.views.communities 1.0

import Storybook 1.0
import Models 1.0

SplitView {
    orientation: Qt.Vertical
    SplitView.fillWidth: true

    Logs { id: logs }

    Pane {
        SplitView.fillWidth: true
        SplitView.fillHeight: true

        CommunityNewPermissionView {
            id: communityNewPermissionView

            anchors.fill: parent

            isEditState: isEditStateCheckBox.checked
            isPrivate: isPrivateCheckBox.checked
            isOwner: isOwnerCheckBox.checked
            duplicationWarningVisible: isDuplicationWarningVisibleCheckBox.checked

            assetsModel: AssetsModel {}
            collectiblesModel: CollectiblesModel {}
            channelsModel: ChannelsModel {}

            communityDetails: QtObject {
                readonly property string name: "Socks"
                readonly property string image: ModelsData.icons.socks
                readonly property string color: "red"
            }

            onCreatePermissionClicked: {
                logs.logEvent("CommunityNewPermissionView::onCreatePermissionClicked")
            }
        }
    }

    LogsAndControlsPanel {
        id: logsAndControlsPanel

        SplitView.minimumHeight: 100
        SplitView.preferredHeight: 160

        logsView.logText: logs.logText

        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            RowLayout {
                Layout.fillWidth: true

                CheckBox {
                    id: isOwnerCheckBox

                    text: "Is owner"
                }

                CheckBox {
                    id: isEditStateCheckBox

                    text: "Is edit state"
                }

                CheckBox {
                    id: isPrivateCheckBox

                    text: "Is private"
                }

                CheckBox {
                    id: isDuplicationWarningVisibleCheckBox

                    text: "Is duplication warning visible"
                }
            }

            Button {
                text: "Reset changes"

                onClicked: communityNewPermissionView.resetChanges()
            }

            Label {
                text: "Is dirty: " + communityNewPermissionView.dirty
            }
        }
    }
}
