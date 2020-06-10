import QtQuick 2.12
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.12
import "../imports"

Item {
    property alias textField: inputValue
    property string placeholderText: "My placeholder"
    property alias text: inputValue.text
    property string label: ""
    //    property string label: "My Label"
    readonly property bool hasLabel: label !== ""
    property color bgColor: Theme.grey
    //    property url icon: "../app/img/hash.svg"
    property url icon: ""
    readonly property bool hasIcon: icon.toString() !== ""
    readonly property var forceActiveFocus: function () {
        inputValue.forceActiveFocus(Qt.MouseFocusReason)
    }
    readonly property int labelMargin: 7
    property int customHeight: 44

    id: inputBox
    height: inputRectangle.height + (hasLabel ? inputLabel.height + labelMargin : 0)
    anchors.right: parent.right
    anchors.left: parent.left

    Text {
        id: inputLabel
        text: inputBox.label
        font.weight: Font.Medium
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        font.pixelSize: 13
        color: Theme.black
    }

    Rectangle {
        id: inputRectangle
        height: customHeight
        color: bgColor
        radius: 8
        anchors.top: inputBox.hasLabel ? inputLabel.bottom : parent.top
        anchors.topMargin: inputBox.hasLabel ? inputBox.labelMargin : 0
        anchors.right: parent.right
        anchors.left: parent.left

        TextField {
            id: inputValue
            visible: !inputBox.isTextArea && !inputBox.isSelect
            placeholderText: inputBox.placeholderText
            text: inputBox.text
            anchors.left: parent.left
            anchors.leftMargin: inputBox.hasIcon ? 36 : Theme.padding
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 15
            background: Rectangle {
                color: "#00000000"
            }
        }

        Image {
            id: iconImg
            sourceSize.height: 24
            sourceSize.width: 24
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectFit
            source: inputBox.icon
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            inputValue.forceActiveFocus(Qt.MouseFocusReason)
        }
    }
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#ffffff";formeditorZoom:1.25}
}
##^##*/

