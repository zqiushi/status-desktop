import StatusQ.Components 0.1
import StatusQ.Core.Theme 0.1
import StatusQ.Core 0.1


StatusListItem {
    signal goToAccountView()

    property var account
    
    title: account.name
    subTitle: account.address
    icon.isLetterIdenticon: true
    icon.color: account.color
    width: parent.width
    leftPadding: 0
    rightPadding: 0
    components: [
        StatusIcon {
            icon: "chevron-down"
            rotation: 270
            color: Theme.palette.baseColor1
        }
    ]

    onClicked: {
        goToAccountView()
    }
}