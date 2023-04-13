import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

import StatusQ.Core 0.1
import StatusQ.Core.Theme 0.1
import StatusQ.Controls 0.1
import StatusQ.Components 0.1

import SortFilterProxyModel 0.2

import utils 1.0
import shared.controls 1.0

Control {
    id: root

    // Expected roles: name, walletAddress, imageSource, amount, selfDestructAmount and selfDestruct
    property var model

    property string tokenName
    property bool isSelectorMode: false

    signal selfDestructChanged()


    QtObject {
        id: d

        readonly property int red2Color: 4
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        spacing: Style.current.padding

        SortFilterProxyModel {
            id: filteredModel

            sourceModel: root.model
            filters: ExpressionFilter {
                enabled: searcher.enabled
                expression: {
                    searcher.text
                    return model.name.toLowerCase().includes(searcher.text.toLowerCase()) ||
                            model.walletAddress.toLowerCase().includes(searcher.text.toLowerCase())
                }
            }
        }

        SearchBox {
            id: searcher

            Layout.fillWidth: true

            topPadding: 0
            bottomPadding: 0
            minimumHeight: 36 // by design
            maximumHeight: minimumHeight
            enabled: root.model && root.model.count > 0
            placeholderText: enabled ? qsTr("Search") : qsTr("No placeholders to search")
        }

        StatusBaseText {
            Layout.fillWidth: true

            visible: !root.preview
            wrapMode: Text.Wrap
            font.pixelSize: Style.current.primaryTextFontSize
            color: Theme.palette.baseColor1
            text: searcher.text.length > 0 ? qsTr("Search results") : qsTr("All %1 token holders").arg(root.tokenName)
        }

        StatusListView {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            model: filteredModel
            delegate: RowLayout {
                width: ListView.view.width
                spacing: Style.current.padding

                StatusListItem {
                    readonly property bool unknownHolder: model.name === ""
                    readonly property string formattedTitle: unknownHolder ? "?" : model.name

                    Layout.fillWidth: true

                    leftPadding: 0
                    rightPadding: 0
                    sensor.enabled: false
                    title: formattedTitle
                    statusListItemTitle.visible: !unknownHolder
                    subTitle: model.walletAddress
                    asset.name: model.imageSource
                    asset.isImage: true
                    asset.isLetterIdenticon: unknownHolder
                    asset.color: Theme.palette.userCustomizationColors[d.red2Color]
                }

                StatusComboBox {
                    id: combo

                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 44

                    visible: root.isSelectorMode && amount > 1
                    control.spacing: Style.current.halfPadding / 2
                    model: amount
                    size: StatusComboBox.Size.Small
                    type: StatusComboBox.Type.Secondary
                    delegate: StatusItemDelegate {
                        width: combo.control.width
                        centerTextHorizontally: true
                        highlighted: combo.control.highlightedIndex === index
                        font: combo.control.font
                        text: Number(modelData) + 1
                    }
                    contentItem: StatusBaseText {
                        font: combo.control.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: Number(combo.control.displayText) + 1
                        color: Theme.palette.baseColor1
                    }

                    control.onDisplayTextChanged: {
                        selfDestructAmount = combo.currentIndex + 1
                        root.selfDestructChanged()
                    }
                }

                StatusCheckBox {
                    id: checkBox

                    Layout.leftMargin: Style.current.padding
                    visible: root.isSelectorMode
                    checked: root.isSelectorMode ? selfDestruct : false
                    padding: 0
                    onCheckStateChanged: {
                        selfDestruct = checked
                        root.selfDestructChanged()
                    }
                }
            }
        }
    }
}
