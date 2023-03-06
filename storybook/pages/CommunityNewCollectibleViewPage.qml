import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import StatusQ.Core.Theme 0.1
import StatusQ.Components 0.1

import AppLayouts.Chat.views.communities 1.0

import Storybook 1.0
import Models 1.0

import utils 1.0

SplitView {

    Logs { id: logs }

    SplitView {
        orientation: Qt.Vertical
        SplitView.fillWidth: true

        Item {
            SplitView.fillWidth: true
            SplitView.fillHeight: true

            CommunityNewCollectibleView {
                anchors.fill: parent
                anchors.margins: 50
                store: QtObject {
                    property var layer1Networks: NetworksModel.layer1Networks
                    property var layer2Networks: NetworksModel.layer2Networks
                    property var testNetworks: NetworksModel.testNetworks
                    property var enabledNetworks: NetworksModel.enabledNetworks
                    property var allNetworks: enabledNetworks
                }

                onPreviewClicked: logs.logEvent("CommunityNewCollectibleView::previewClicked")
            }
        }


        LogsAndControlsPanel {
            id: logsAndControlsPanel

            SplitView.minimumHeight: 100
            SplitView.preferredHeight: 150

            logsView.logText: logs.logText
        }
    }
}
