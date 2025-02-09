import QtQuick 2.15
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtMultimedia 5.13
import Qt.labs.platform 1.1
import Qt.labs.settings 1.1
import QtQml.Models 2.14
import QtQml 2.15

import AppLayouts.Wallet 1.0
import AppLayouts.Node 1.0
import AppLayouts.Browser 1.0
import AppLayouts.Chat 1.0
import AppLayouts.Chat.views 1.0
import AppLayouts.Profile 1.0
import AppLayouts.Communities 1.0
import AppLayouts.Wallet.services.dapps 1.0

import utils 1.0
import shared 1.0
import shared.controls 1.0
import shared.controls.chat.menuItems 1.0
import shared.panels 1.0
import shared.popups 1.0
import shared.popups.keycard 1.0
import shared.status 1.0
import shared.stores 1.0
import shared.popups.send 1.0 as SendPopups
import shared.popups.send.views 1.0
import shared.stores.send 1.0

import StatusQ 0.1
import StatusQ.Core 0.1
import StatusQ.Core.Theme 0.1
import StatusQ.Core.Utils 0.1 as SQUtils
import StatusQ.Components 0.1
import StatusQ.Controls 0.1
import StatusQ.Layout 0.1
import StatusQ.Popups 0.1
import StatusQ.Popups.Dialog 0.1

import AppLayouts.Browser.stores 1.0 as BrowserStores
import AppLayouts.stores 1.0
import AppLayouts.Chat.stores 1.0 as ChatStores
import AppLayouts.Communities.stores 1.0
import AppLayouts.Wallet.stores 1.0 as WalletStore
import AppLayouts.Wallet.popups 1.0 as WalletPopups

import mainui.activitycenter.stores 1.0
import mainui.activitycenter.popups 1.0

import SortFilterProxyModel 0.2

import "panels"

Item {
    id: appMain

    property alias appLayout: appLayout
    property RootStore rootStore: RootStore {
        profileSectionStore.sendModalPopup: sendModal
    }
    property var rootChatStore: ChatStores.RootStore {
        contactsStore: appMain.rootStore.contactStore
        communityTokensStore: appMain.communityTokensStore
        emojiReactionsModel: appMain.rootStore.emojiReactionsModel
        openCreateChat: createChatView.opened
        networkConnectionStore: appMain.networkConnectionStore
    }
    property var createChatPropertiesStore: ChatStores.CreateChatPropertiesStore {}
    property ActivityCenterStore activityCenterStore: ActivityCenterStore {}
    property NetworkConnectionStore networkConnectionStore: NetworkConnectionStore {}
    property CommunityTokensStore communityTokensStore: CommunityTokensStore {}
    property CommunitiesStore communitiesStore: CommunitiesStore {}
    readonly property WalletStore.TokensStore tokensStore: WalletStore.RootStore.tokensStore
    readonly property WalletStore.WalletAssetsStore walletAssetsStore: WalletStore.RootStore.walletAssetsStore
    readonly property WalletStore.CollectiblesStore walletCollectiblesStore: WalletStore.RootStore.collectiblesStore
    readonly property CurrenciesStore currencyStore: CurrenciesStore {}
    readonly property TransactionStore transactionStore: TransactionStore {
        walletAssetStore: appMain.walletAssetsStore
        tokensStore: appMain.tokensStore
        currencyStore: appMain.currencyStore
    }
    required property bool isCentralizedMetricsEnabled

    // set from main.qml
    property var sysPalette

    // Central UI point for managing app toasts:
    ToastsManager {
        id: toastsManager

        rootStore: appMain.rootStore
        rootChatStore: appMain.rootChatStore
        communityTokensStore: appMain.communityTokensStore
        profileStore: appMain.rootStore.profileSectionStore.profileStore

        sendModalPopup: sendModal
    }

    Connections {
        target: rootStore.mainModuleInst

        function onDisplayUserProfile(publicKey: string) {
            popups.openProfilePopup(publicKey)
        }

        function onDisplayKeycardSharedModuleForAuthenticationOrSigning() {
            keycardPopupForAuthenticationOrSigning.active = true
        }

        function onDestroyKeycardSharedModuleForAuthenticationOrSigning() {
            keycardPopupForAuthenticationOrSigning.active = false
        }

        function onDisplayKeycardSharedModuleFlow() {
            keycardPopup.active = true
        }

        function onDestroyKeycardSharedModuleFlow() {
            keycardPopup.active = false
        }

        function onMailserverWorking() {
            mailserverConnectionBanner.hide()
        }

        function onMailserverNotWorking() {
            mailserverConnectionBanner.show()
        }

        function onActiveSectionChanged() {
            createChatView.opened = false
            Global.settingsSubSubsection = -1
        }

        function onOpenActivityCenter() {
            d.openActivityCenterPopup()
        }

        function onShowToastAccountAdded(name: string) {
            Global.displayToastMessage(
                qsTr("\"%1\" successfully added").arg(name),
                "",
                "checkmark-circle",
                false,
                Constants.ephemeralNotificationType.success,
                ""
            )
        }

        function onShowToastAccountRemoved(name: string) {
            Global.displayToastMessage(
                        qsTr("\"%1\" successfully removed").arg(name),
                        "",
                        "checkmark-circle",
                        false,
                        Constants.ephemeralNotificationType.success,
                        ""
                        )
        }

        function onShowToastKeypairRenamed(oldName: string, newName: string) {
            Global.displayToastMessage(
                qsTr("You successfully renamed your key pair\nfrom \"%1\" to \"%2\"").arg(oldName).arg(newName),
                "",
                "checkmark-circle",
                false,
                Constants.ephemeralNotificationType.success,
                ""
            )
        }

        function onShowNetworkEndpointUpdated(name: string, isTest: bool, revertToDefault: bool) {
            let mainText = revertToDefault ?
                    (isTest ? qsTr("Test network settings for %1 reverted to default").arg(name): qsTr("Live network settings for %1 reverted to default").arg(name)):
                    (isTest ? qsTr("Test network settings for %1 updated").arg(name): qsTr("Live network settings for %1 updated").arg(name))
            Global.displayToastMessage(
                mainText,
                "",
                "checkmark-circle",
                false,
                Constants.ephemeralNotificationType.success,
                ""
            )
        }

        function onShowToastKeypairRemoved(keypairName: string) {
            Global.displayToastMessage(
                qsTr("“%1” key pair and its derived accounts were successfully removed from all devices").arg(keypairName),
                "",
                "checkmark-circle",
                false,
                Constants.ephemeralNotificationType.success,
                ""
            )
        }

        function onShowToastKeypairsImported(keypairName: string, keypairsCount: int, error: string) {
            let notification = qsTr("Please re-generate QR code and try importing again")
            if (error !== "") {
                if (error.startsWith("one or more expected keystore files are not found among the sent files")) {
                    notification = qsTr("Make sure you're importing the exported key pair on paired device")
                }
            }
            else {
                notification = qsTr("%1 key pair successfully imported").arg(keypairName)
                if (keypairsCount > 1) {
                    notification = qsTr("%n key pair(s) successfully imported", "", keypairsCount)
                }
            }
            Global.displayToastMessage(
                notification,
                "",
                error!==""? "info" : "checkmark-circle",
                false,
                error!==""? Constants.ephemeralNotificationType.normal : Constants.ephemeralNotificationType.success,
                ""
            )
        }

        function onShowToastTransactionSent(chainId: int, txHash: string, uuid: string, error: string, txType: int,
                                            fromAddr: string, toAddr: string, fromTokenKey: string, fromAmount: string,
                                            toTokenKey: string, toAmount: string) {
            switch(txType) {
            case Constants.SendType.Approve: {
                const fromToken = SQUtils.ModelUtils.getByKey(appMain.tokensStore.plainTokensBySymbolModel, "key", fromTokenKey)
                const fromAccountName = SQUtils.ModelUtils.getByKey(appMain.transactionStore.accounts, "address", fromAddr, "name")
                const networkName = SQUtils.ModelUtils.getByKey(WalletStore.RootStore.filteredFlatModel, "chainId", chainId, "chainName")
                if(!!fromToken && !!fromAccountName && !!networkName) {
                    const approvalAmount = currencyStore.formatCurrencyAmountFromBigInt(fromAmount, fromToken.symbol, fromToken.decimals)
                    let toastTitle = qsTr("Setting spending cap: %1 in %2 for %3 on %4").arg(approvalAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                    let toastSubtitle = qsTr("View on %1").arg(networkName)
                    let urlLink = "%1/%2".arg(appMain.rootStore.getEtherscanLink(chainId)).arg(txHash)
                    let toastType = Constants.ephemeralNotificationType.normal
                    let icon = ""
                    if(error) {
                        toastTitle = qsTr("Failed to set spending cap: %1 in %2 for %3 on %4").arg(approvalAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                        toastSubtitle = ""
                        urlLink = ""
                        toastType = Constants.ephemeralNotificationType.danger
                        icon = "warning"
                    }
                    Global.displayToastMessage(toastTitle, toastSubtitle, icon, !error, toastType, urlLink)
                }
                break
            }
            case Constants.SendType.Swap: {
                const fromToken = SQUtils.ModelUtils.getByKey(appMain.tokensStore.plainTokensBySymbolModel, "key", fromTokenKey)
                const toToken = SQUtils.ModelUtils.getByKey(appMain.tokensStore.plainTokensBySymbolModel, "key", toTokenKey)
                const fromAccountName = SQUtils.ModelUtils.getByKey(appMain.transactionStore.accounts, "address", fromAddr, "name")
                const networkName = SQUtils.ModelUtils.getByKey(WalletStore.RootStore.filteredFlatModel, "chainId", chainId, "chainName")
                if(!!fromToken && !!toToken && !!fromAccountName && !!networkName) {
                    const fromSwapAmount = currencyStore.formatCurrencyAmountFromBigInt(fromAmount, fromToken.symbol, fromToken.decimals)
                    const toSwapAmount = currencyStore.formatCurrencyAmountFromBigInt(toAmount, toToken.symbol, toToken.decimals)
                    let toastTitle = qsTr("Swapping %1 to %2 in %3 using %4 on %5").arg(fromSwapAmount).arg(toSwapAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                    let toastSubtitle = qsTr("View on %1").arg(networkName)
                    let urlLink = "%1/%2".arg(appMain.rootStore.getEtherscanLink(chainId)).arg(txHash)
                    let toastType = Constants.ephemeralNotificationType.normal
                    let icon = ""
                    if(error) {
                        toastTitle = qsTr("Failed to swap %1 to %2 in %3 using %4 on %5").arg(fromSwapAmount).arg(toSwapAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                        toastSubtitle = ""
                        urlLink = ""
                        toastType = Constants.ephemeralNotificationType.danger
                        icon = "warning"
                    }
                    Global.displayToastMessage(toastTitle, toastSubtitle, icon, !error, toastType, urlLink)
                }
                break
            }
            default: {
                if (!error) {
                    let networkName = SQUtils.ModelUtils.getByKey(WalletStore.RootStore.filteredFlatModel, "chainId", chainId, "chainName")
                    if(!!networkName) {
                        Global.displayToastMessage(qsTr("Transaction pending..."),
                                                   qsTr("View on %1").arg(networkName),
                                                   "",
                                                   true,
                                                   Constants.ephemeralNotificationType.normal,
                                                   "%1/%2".arg(appMain.rootStore.getEtherscanLink(chainId)).arg(txHash))
                    }
                }
                break
            }
            }
        }

        function onShowToastTransactionSendingComplete(chainId: int, txHash: string, data: string, success: bool,
                                                       txType: int, fromAddr: string, toAddr: string, fromTokenKey: string,
                                                       fromAmount: string, toTokenKey: string, toAmount: string) {
            switch(txType) {
            case Constants.SendType.Approve: {
                const fromToken = SQUtils.ModelUtils.getByKey(appMain.tokensStore.plainTokensBySymbolModel, "key", fromTokenKey)
                const fromAccountName = SQUtils.ModelUtils.getByKey(appMain.transactionStore.accounts, "address", fromAddr, "name")
                const networkName = SQUtils.ModelUtils.getByKey(WalletStore.RootStore.filteredFlatModel, "chainId", chainId, "chainName")
                if(!!fromToken && !!fromAccountName && !!networkName) {
                    const approvalAmount = currencyStore.formatCurrencyAmountFromBigInt(fromAmount, fromToken.symbol, fromToken.decimals)
                    let toastTitle = qsTr("Spending cap set: %1 in %2 for %3 on %4").arg(approvalAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                    const toastSubtitle =  qsTr("View on %1").arg(networkName)
                    const urlLink = "%1/%2".arg(appMain.rootStore.getEtherscanLink(chainId)).arg(txHash)
                    let toastType = Constants.ephemeralNotificationType.success
                    let icon = "checkmark-circle"
                    if(!success) {
                        toastTitle = qsTr("Failed to set spending cap: %1 in %2 for %3 on %4").arg(approvalAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                        toastType = Constants.ephemeralNotificationType.danger
                        icon = "warning"
                    }
                    Global.displayToastMessage(toastTitle, toastSubtitle, icon, false, toastType, urlLink)
                }
                break
            }
            case Constants.SendType.Swap: {
                const fromToken = SQUtils.ModelUtils.getByKey(appMain.tokensStore.plainTokensBySymbolModel, "key", fromTokenKey)
                const toToken = SQUtils.ModelUtils.getByKey(appMain.tokensStore.plainTokensBySymbolModel, "key", toTokenKey)
                const fromAccountName = SQUtils.ModelUtils.getByKey(appMain.transactionStore.accounts, "address", fromAddr, "name")
                const networkName = SQUtils.ModelUtils.getByKey(WalletStore.RootStore.filteredFlatModel, "chainId", chainId, "chainName")
                if(!!fromToken && !!toToken && !!fromAccountName && !!networkName) {
                    const fromSwapAmount = currencyStore.formatCurrencyAmountFromBigInt(fromAmount, fromToken.symbol, fromToken.decimals)
                    const toSwapAmount = currencyStore.formatCurrencyAmountFromBigInt(toAmount, toToken.symbol, toToken.decimals)
                    let toastTitle = qsTr("Swapped %1 to %2 in %3 using %4 on %5").arg(fromSwapAmount).arg(toSwapAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                    const toastSubtitle = qsTr("View on %1").arg(networkName)
                    const urlLink = "%1/%2".arg(appMain.rootStore.getEtherscanLink(chainId)).arg(txHash)
                    let toastType = Constants.ephemeralNotificationType.success
                    let icon = "checkmark-circle"
                    if(!success) {
                        toastTitle = qsTr("Failed to swap %1 to %2 in %3 using %4 on %5").arg(fromSwapAmount).arg(toSwapAmount).arg(fromAccountName).arg(Constants.swap.paraswapUrl).arg(networkName)
                        toastType = Constants.ephemeralNotificationType.danger
                        icon = "warning"
                    }
                    Global.displayToastMessage(toastTitle, toastSubtitle, icon, false, toastType, urlLink)
                }
                break
            }
            default: break
            }
        }

        function onCommunityMemberStatusEphemeralNotification(communityName: string, memberName: string, state: CommunityMembershipRequestState) {
            var text = ""
            switch (state) {
                case Constants.CommunityMembershipRequestState.Banned:
                case Constants.CommunityMembershipRequestState.BannedWithAllMessagesDelete:
                    text = qsTr("%1 was banned from %2").arg(memberName).arg(communityName)
                    break
                case Constants.CommunityMembershipRequestState.Unbanned:
                    text = qsTr("%1 unbanned from %2").arg(memberName).arg(communityName)
                    break
                case Constants.CommunityMembershipRequestState.Kicked:
                    text = qsTr("%1 was kicked from %2").arg(memberName).arg(communityName)
                    break
                default: return
            }

            Global.displayToastMessage(
                text,
                "",
                "checkmark-circle",
                false,
                Constants.ephemeralNotificationType.success,
                ""
            )
        }
    }

    QtObject {
        id: d

        property var activityCenterPopupObj: null

        function openActivityCenterPopup() {
            if (!activityCenterPopupObj) {
                activityCenterPopupObj = activityCenterPopupComponent.createObject(appMain)
            }

            if (activityCenterPopupObj.opened) {
                activityCenterPopupObj.close()
            } else {
                activityCenterPopupObj.open()
            }
        }
    }

    Settings {
        id: appMainLocalSettings
        property var whitelistedUnfurledDomains: []
    }

    Popups {
        id: popups
        popupParent: appMain
        rootStore: appMain.rootStore
        communityTokensStore: appMain.communityTokensStore
        communitiesStore: appMain.communitiesStore
        devicesStore: appMain.rootStore.profileSectionStore.devicesStore
        currencyStore: appMain.currencyStore
        walletAssetsStore: appMain.walletAssetsStore
        walletCollectiblesStore: appMain.walletCollectiblesStore
        networkConnectionStore: appMain.networkConnectionStore
        isDevBuild: !production

        onOpenExternalLink: globalConns.onOpenLink(link)
        onSaveDomainToUnfurledWhitelist: {
            const whitelistedHostnames = appMainLocalSettings.whitelistedUnfurledDomains || []
            if (!whitelistedHostnames.includes(domain)) {
                whitelistedHostnames.push(domain)
                appMainLocalSettings.whitelistedUnfurledDomains = whitelistedHostnames
            }
        }
    }

    Connections {
        id: globalConns
        target: Global

        function onOpenLinkInBrowser(link: string) {
            changeAppSectionBySectionId(Constants.appSection.browser)
            Qt.callLater(() => browserLayoutContainer.item.openUrlInNewTab(link));
        }

        function onOpenCreateChatView() {
            createChatView.opened = true
        }

        function onCloseCreateChatView() {
            createChatView.opened = false
        }

        function onOpenActivityCenterPopupRequested() {
            d.openActivityCenterPopup()
        }

        function onOpenLink(link: string) {
            // Qt sometimes inserts random HTML tags; and this will break on invalid URL inside QDesktopServices::openUrl(link)
            link = appMain.rootStore.plainText(link)

            if (appMain.rootStore.showBrowserSelector) {
                popups.openChooseBrowserPopup(link)
            } else {
                if (appMain.rootStore.openLinksInStatus) {
                    globalConns.onAppSectionBySectionTypeChanged(Constants.appSection.browser)
                    globalConns.onOpenLinkInBrowser(link)
                } else {
                    Qt.openUrlExternally(link)
                }
            }
        }

        function onOpenLinkWithConfirmation(link: string, domain: string) {
            if (appMainLocalSettings.whitelistedUnfurledDomains.includes(domain))
                globalConns.onOpenLink(link)
            else
                popups.openConfirmExternalLinkPopup(link, domain)
        }

        function onActivateDeepLink(link: string) {
            appMain.rootStore.mainModuleInst.activateStatusDeepLink(link)
        }

        function onPlaySendMessageSound() {
            sendMessageSound.stop()
            sendMessageSound.play()
        }

        function onPlayNotificationSound() {
            notificationSound.stop()
            notificationSound.play()
        }

        function onPlayErrorSound() {
            errorSound.stop()
            errorSound.play()
        }

        function onSetNthEnabledSectionActive(nthSection: int) {
            if(!appMain.rootStore.mainModuleInst)
                return
            appMain.rootStore.mainModuleInst.setNthEnabledSectionActive(nthSection)
        }

        function onAppSectionBySectionTypeChanged(sectionType, subsection, subSubsection = -1, data = {}) {
            if(!appMain.rootStore.mainModuleInst)
                return

            appMain.rootStore.mainModuleInst.setActiveSectionBySectionType(sectionType)

            if (sectionType === Constants.appSection.profile) {
                Global.settingsSubsection = subsection;
                Global.settingsSubSubsection = subSubsection;
            } else if (sectionType === Constants.appSection.wallet) {
                appView.children[Constants.appViewStackIndex.wallet].item.openDesiredView(subsection, subSubsection, data)
            }
        }

        function onOpenSendModal(address: string) {
            sendModal.open(address)
        }

        function onSwitchToCommunity(communityId: string) {
            appMain.communitiesStore.setActiveCommunity(communityId)
        }

        function onOpenAddEditSavedAddressesPopup(params) {
            addEditSavedAddress.open(params)
        }

        function onOpenDeleteSavedAddressesPopup(params) {
            deleteSavedAddress.open(params)
        }

        function onOpenShowQRPopup(params) {
            showQR.open(params)
        }

        function onOpenSavedAddressActivityPopup(params) {
            savedAddressActivity.open(params)
        }
    }

    Connections {
        target: appMain.communitiesStore

        function onImportingCommunityStateChanged(communityId, state, errorMsg) {
            let title = ""
            let subTitle = ""
            let loading = false
            let notificationType = Constants.ephemeralNotificationType.normal
            let icon = ""

            switch (state)
            {
            case Constants.communityImported:
                const community = appMain.communitiesStore.getCommunityDetailsAsJson(communityId)
                if(community.isControlNode) {
                    title = qsTr("This device is now the control node for the %1 Community").arg(community.name)
                    notificationType = Constants.ephemeralNotificationType.success
                    icon = "checkmark-circle"
                } else {
                    title = qsTr("'%1' community imported").arg(community.name)
                }
                break
            case Constants.communityImportingInProgress:
                title = qsTr("Importing community is in progress")
                loading = true
                break
            case Constants.communityImportingError:
                title = qsTr("Failed to import community '%1'").arg(communityId)
                subTitle = errorMsg
                break
            case Constants.communityImportingCanceled:
                title = qsTr("Import community '%1' was canceled").arg(community.name)
                break;
            default:
                console.error("unknown state while importing community: %1").arg(state)
                return
            }

            Global.displayToastMessage(title,
                                       subTitle,
                                       icon,
                                       loading,
                                       notificationType,
                                       "")
        }
    }

    Connections {
        target: Global.applicationWindow

        function onActiveChanged() {
            if (Global.applicationWindow.active) appMain.rootStore.windowActivated()
            else appMain.rootStore.windowDeactivated()
        }
    }

    function changeAppSectionBySectionId(sectionId) {
        appMain.rootStore.mainModuleInst.setActiveSectionById(sectionId)
    }

    Audio {
        id: sendMessageSound
        store: rootStore
        source: "qrc:/imports/assets/audio/send_message.wav"
    }

    Audio {
        id: notificationSound
        store: rootStore
        source: "qrc:/imports/assets/audio/notification.wav"
    }

    Audio {
        id: errorSound
        source: "qrc:/imports/assets/audio/error.mp3"
        store: rootStore
    }

    Loader {
        id: appSearch
        active: false
        asynchronous: true

        function openSearchPopup() {
            if (!active)
                active = true
            item.openSearchPopup()
        }

        function closeSearchPopup() {
            if (item)
                item.closeSearchPopup()

            active = false
        }

        sourceComponent: AppSearch {
            store: appMain.rootStore.appSearchStore
            onClosed: appSearch.active = false
        }
    }

    Loader {
        id: statusEmojiPopup
        active: appMain.rootStore.mainModuleInst.sectionsLoaded
        sourceComponent: StatusEmojiPopup {
            width: 360
            height: 440
        }
    }

    Loader {
        id: statusStickersPopupLoader
        active: appMain.rootStore.mainModuleInst.sectionsLoaded
        sourceComponent: StatusStickersPopup {
            id: statusStickersPopup
            store: appMain.rootChatStore
            transactionStore: appMain.transactionStore
            walletAssetsStore: appMain.walletAssetsStore
        }
    }

    StatusMainLayout {
        id: appLayout

        anchors.fill: parent

        leftPanel: StatusAppNavBar {
            chatItemsModel: SortFilterProxyModel {
                sourceModel: appMain.rootStore.mainModuleInst.sectionsModel
                filters: [
                    ValueFilter {
                        roleName: "sectionType"
                        value: Constants.appSection.chat
                    },
                    ValueFilter {
                        roleName: "enabled"
                        value: true
                    }
                ]
            }
            chatItemDelegate: navbarButton

            communityItemsModel: SortFilterProxyModel {
                sourceModel: appMain.rootStore.mainModuleInst.sectionsModel
                filters: [
                    ValueFilter {
                        roleName: "sectionType"
                        value: Constants.appSection.community
                    },
                    ValueFilter {
                        roleName: "enabled"
                        value: true
                    }
                ]
            }
            communityItemDelegate: StatusNavBarTabButton {
                objectName: "CommunityNavBarButton"
                anchors.horizontalCenter: parent.horizontalCenter
                name: model.icon.length > 0? "" : model.name
                icon.name: model.icon
                icon.source: model.image
                identicon.asset.color: (hovered || identicon.highlighted || checked) ? model.color : icon.color
                tooltip.text: model.name
                checked: model.active
                badge.value: model.notificationsCount
                badge.visible: model.hasNotification
                badge.border.color: hovered ? Theme.palette.statusBadge.hoverBorderColor : Theme.palette.statusBadge.borderColor
                badge.border.width: 2

                stateIcon.color: Theme.palette.dangerColor1
                stateIcon.border.color: Theme.palette.baseColor2
                stateIcon.border.width: 2
                stateIcon.visible: model.amIBanned
                stateIcon.asset.name: "cancel"
                stateIcon.asset.color: Theme.palette.baseColor2
                stateIcon.asset.width: 14

                onClicked: {
                    changeAppSectionBySectionId(model.id)
                }

                popupMenu: Component {
                    StatusMenu {
                        id: communityContextMenu
                        property var chatCommunitySectionModule

                        readonly property bool isSpectator: model.spectated && !model.joined

                        openHandler: function () {
                            // we cannot return QVariant if we pass another parameter in a function call
                            // that's why we're using it this way
                            appMain.rootStore.mainModuleInst.prepareCommunitySectionModuleForCommunityId(model.id)
                            communityContextMenu.chatCommunitySectionModule = appMain.rootStore.mainModuleInst.getCommunitySectionModule()
                        }

                        StatusAction {
                            text: qsTr("Invite People")
                            icon.name: "share-ios"
                            objectName: "invitePeople"
                            onTriggered: {
                                popups.openInviteFriendsToCommunityPopup(model,
                                                                         communityContextMenu.chatCommunitySectionModule,
                                                                         null)
                            }
                        }

                        StatusAction {
                            text: qsTr("View Community")
                            icon.name: "group-chat"
                            onTriggered: popups.openCommunityProfilePopup(appMain.rootStore, model, communityContextMenu.chatCommunitySectionModule)
                        }

                        StatusMenuSeparator {}

                        MuteChatMenuItem {
                            enabled: !model.muted
                            title: qsTr("Mute Community")
                            onMuteTriggered: {
                                communityContextMenu.chatCommunitySectionModule.setCommunityMuted(interval)
                                communityContextMenu.close()
                            }
                        }

                        StatusAction {
                            enabled: model.muted
                            text: qsTr("Unmute Community")
                            icon.name: "notification"
                            onTriggered: {
                                communityContextMenu.chatCommunitySectionModule.setCommunityMuted(Constants.MutingVariations.Unmuted)
                            }
                        }

                        StatusAction {
                            text: qsTr("Edit Shared Addresses")
                            icon.name: "wallet"
                            enabled: {
                                if (model.memberRole === Constants.memberRole.owner || communityContextMenu.isSpectator)
                                    return false
                                return true
                            }
                            onTriggered: {
                                communityContextMenu.close()
                                Global.openEditSharedAddressesFlow(model.id)
                            }
                        }

                        StatusMenuSeparator { visible: leaveCommunityMenuItem.enabled }

                        StatusAction {
                            id: leaveCommunityMenuItem
                            // allow to leave community for the owner in non-production builds
                            enabled: model.memberRole !== Constants.memberRole.owner || !production
                            text: {
                                if (communityContextMenu.isSpectator)
                                    return qsTr("Close Community")
                                return qsTr("Leave Community")
                            }
                            icon.name: communityContextMenu.isSpectator ? "close-circle" : "arrow-left"
                            type: StatusAction.Type.Danger
                            onTriggered: communityContextMenu.isSpectator ? communityContextMenu.chatCommunitySectionModule.leaveCommunity()
                                                                          : popups.openLeaveCommunityPopup(model.name, model.id, model.outroMessage)
                        }
                    }
                }
            }

            regularItemsModel: SortFilterProxyModel {
                sourceModel: appMain.rootStore.mainModuleInst.sectionsModel
                filters: [
                    RangeFilter {
                        roleName: "sectionType"
                        minimumValue: Constants.appSection.wallet
                        maximumValue: Constants.appSection.communitiesPortal
                    },
                    ValueFilter {
                        roleName: "enabled"
                        value: true
                    }
                ]
            }
            regularItemDelegate: navbarButton

            delegateHeight: 40

            profileComponent: StatusNavBarTabButton {
                id: profileButton
                objectName: "statusProfileNavBarTabButton"
                property bool opened: false

                name: appMain.rootStore.userProfileInst.name
                icon.source: appMain.rootStore.userProfileInst.icon
                implicitWidth: 32
                implicitHeight: 32
                identicon.asset.width: width
                identicon.asset.height: height
                identicon.asset.useAcronymForLetterIdenticon: true
                identicon.asset.color: Utils.colorForPubkey(appMain.rootStore.userProfileInst.pubKey)
                identicon.ringSettings.ringSpecModel: Utils.getColorHashAsJson(appMain.rootStore.userProfileInst.pubKey,
                                                                               appMain.rootStore.userProfileInst.preferredName)

                badge.visible: true
                badge.anchors {
                    left: undefined
                    top: undefined
                    right: profileButton.right
                    bottom: profileButton.bottom
                    margins: 0
                    rightMargin: -badge.border.width
                    bottomMargin: -badge.border.width
                }
                badge.implicitHeight: 12
                badge.implicitWidth: 12
                badge.border.width: 2
                badge.border.color: hovered ? Theme.palette.statusBadge.hoverBorderColor : Theme.palette.statusAppNavBar.backgroundColor
                badge.color: {
                    switch(appMain.rootStore.userProfileInst.currentUserStatus){
                        case Constants.currentUserStatus.automatic:
                        case Constants.currentUserStatus.alwaysOnline:
                            return Style.current.green;
                        default:
                            return Style.current.midGrey;
                    }
                }

                onClicked: userStatusContextMenu.opened ? userStatusContextMenu.close() : userStatusContextMenu.open()

                UserStatusContextMenu {
                    id: userStatusContextMenu
                    y: profileButton.y - userStatusContextMenu.height + profileButton.height
                    x: profileButton.x + profileButton.width + 5
                    store: appMain.rootStore
                }
            }

            Component {
                id: navbarButton
                StatusNavBarTabButton {
                    id: navbar
                    objectName: model.name + "-navbar"
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: model.icon.length > 0? "" : model.name
                    icon.name: model.icon
                    icon.source: model.image
                    tooltip.text: Utils.translatedSectionName(model.sectionType, model.name)
                    checked: model.active
                    badge.value: model.notificationsCount
                    badge.visible: model.sectionType === Constants.appSection.profile &&
                                   appMain.rootStore.contactStore.receivedContactRequestsModel.count ? true // pending CR request
                                                                                                     : model.hasNotification
                    badge.border.color: hovered ? Theme.palette.statusBadge.hoverBorderColor : Theme.palette.statusBadge.borderColor
                    badge.border.width: 2
                    onClicked: {
                        changeAppSectionBySectionId(model.id)
                    }
                }
            }
        }

        rightPanel: ColumnLayout {
            spacing: 0
            objectName: "mainRightView"

            ColumnLayout {
                id: bannersLayout

                enabled: !localAppSettings.testEnvironment
                visible: enabled

                property var updateBanner: null
                property var connectedBanner: null
                readonly property bool isConnected: appMain.rootStore.mainModuleInst.isOnline

                function processUpdateAvailable() {
                    if (!updateBanner)
                        updateBanner = updateBannerComponent.createObject(this)
                }

                function processConnected() {
                    if (!connectedBanner)
                        connectedBanner = connectedBannerComponent.createObject(this)
                }

                Layout.fillWidth: true
                Layout.maximumHeight: implicitHeight
                spacing: 1

                onIsConnectedChanged: {
                    processConnected()
                }

                Component.onCompleted: {
                    if (!isConnected)
                        processConnected()
                }

                Connections {
                    target: rootStore.aboutModuleInst
                    function onAppVersionFetched(available: bool, version: string, url: string) {
                        rootStore.setLatestVersionInfo(available, version, url);
                        // TODO when we re-implement check for updates, uncomment this
                        // bannersLayout.processUpdateAvailable()
                    }
                }

                ModuleWarning {
                    id: testnetBanner
                    objectName: "testnetBanner"
                    Layout.fillWidth: true
                    text: qsTr("Testnet mode enabled. All balances, transactions and dApp interactions will be on testnets.")
                    buttonText: qsTr("Turn off")
                    type: ModuleWarning.Warning
                    iconName: "warning"
                    active: appMain.rootStore.profileSectionStore.walletStore.areTestNetworksEnabled
                    delay: false
                    onClicked: Global.openTestnetPopup()
                    closeBtnVisible: false
                }

                ModuleWarning {
                    id: secureYourSeedPhrase
                    objectName: "secureYourSeedPhraseBanner"
                    Layout.fillWidth: true
                    active: !appMain.rootStore.profileSectionStore.profileStore.userDeclinedBackupBanner
                              && !appMain.rootStore.profileSectionStore.profileStore.privacyStore.mnemonicBackedUp
                    type: ModuleWarning.Danger
                    text: qsTr("Secure your seed phrase")
                    buttonText: qsTr("Back up now")
                    delay: false
                    onClicked: popups.openBackUpSeedPopup()

                    onCloseClicked: {
                        appMain.rootStore.profileSectionStore.profileStore.userDeclinedBackupBanner = true
                    }
                }


                ModuleWarning {
                    Layout.fillWidth: true
                    readonly property int progress: appMain.communitiesStore.discordImportProgress
                    readonly property bool inProgress: (progress > 0 && progress < 100) || appMain.communitiesStore.discordImportInProgress
                    readonly property bool finished: progress >= 100
                    readonly property bool cancelled: appMain.communitiesStore.discordImportCancelled
                    readonly property bool stopped: appMain.communitiesStore.discordImportProgressStopped
                    readonly property int errors: appMain.communitiesStore.discordImportErrorsCount
                    readonly property int warnings: appMain.communitiesStore.discordImportWarningsCount
                    readonly property string communityId: appMain.communitiesStore.discordImportCommunityId
                    readonly property string communityName: appMain.communitiesStore.discordImportCommunityName
                    readonly property string channelId: appMain.communitiesStore.discordImportChannelId
                    readonly property string channelName: appMain.communitiesStore.discordImportChannelName
                    readonly property string channelOrCommunityName: channelName || communityName
                    delay: false
                    active: !cancelled && (inProgress || finished || stopped)
                    type: errors ? ModuleWarning.Type.Danger : ModuleWarning.Type.Success
                    text: {
                        if (finished || stopped) {
                            if (errors)
                                return qsTr("The import of ‘%1’ from Discord to Status was stopped: <a href='#'>Critical issues found</a>").arg(channelOrCommunityName)

                            let result = qsTr("‘%1’ was successfully imported from Discord to Status").arg(channelOrCommunityName) + "  <a href='#'>"
                            if (warnings)
                                result += qsTr("Details (%1)").arg(qsTr("%n issue(s)", "", warnings))
                            else
                                result += qsTr("Details")
                            result += "</a>"
                            return result
                        }
                        if (inProgress) {
                            let result = qsTr("Importing ‘%1’ from Discord to Status").arg(channelOrCommunityName) + "  <a href='#'>"
                            if (warnings)
                                result += qsTr("Check progress (%1)").arg(qsTr("%n issue(s)", "", warnings))
                            else
                                result += qsTr("Check progress")
                            result += "</a>"
                            return result
                        }

                        return ""
                    }
                    onLinkActivated: popups.openDiscordImportProgressPopup(!!channelId)
                    progressValue: progress
                    closeBtnVisible: finished || stopped
                    buttonText: finished && !errors ? !!channelId ? qsTr("Visit your new channel") : qsTr("Visit your Community") : ""
                    onClicked: function() {
                        if (!!channelId)
                            rootStore.setActiveSectionChat(communityId, channelId)
                        else
                            appMain.communitiesStore.setActiveCommunity(communityId)
                    }
                    onCloseClicked: hide()
                }

                ModuleWarning {
                    id: downloadingArchivesBanner
                    Layout.fillWidth: true
                    active: appMain.communitiesStore.downloadingCommunityHistoryArchives
                    type: ModuleWarning.Danger
                    text: qsTr("Downloading message history archives, DO NOT CLOSE THE APP until this banner disappears.")
                    closeBtnVisible: false
                    delay: false
                }

                ModuleWarning {
                    id: mailserverConnectionBanner
                    type: ModuleWarning.Warning
                    text: qsTr("Can not connect to store node. Retrying automatically")
                    onCloseClicked: hide()
                    Layout.fillWidth: true
                }

                Component {
                    id: connectedBannerComponent

                    ModuleWarning {
                        id: connectedBanner
                        property bool isConnected: true

                        objectName: "connectionInfoBanner"
                        Layout.fillWidth: true
                        text: isConnected ? qsTr("You are back online") : qsTr("Internet connection lost. Reconnect to ensure everything is up to date.")
                        type: isConnected ? ModuleWarning.Success : ModuleWarning.Danger

                        function updateState() {
                            if (isConnected)
                                showFor()
                            else
                                show();
                        }

                        Component.onCompleted: {
                            connectedBanner.isConnected = Qt.binding(() => bannersLayout.isConnected);
                        }
                        onIsConnectedChanged: {
                            updateState();
                        }
                        onCloseClicked: {
                            hide();
                        }
                        onHideFinished: {
                            destroy()
                            bannersLayout.connectedBanner = null
                        }
                    }
                }

                Component {
                    id: updateBannerComponent

                    ModuleWarning {
                        readonly property string version: appMain.rootStore.latestVersion
                        readonly property bool updateAvailable: appMain.rootStore.newVersionAvailable

                        objectName: "appVersionUpdateBanner"
                        Layout.fillWidth: true
                        type: ModuleWarning.Success
                        delay: false
                        text: updateAvailable ? qsTr("A new version of Status (%1) is available").arg(version)
                                              : qsTr("Your version is up to date")

                        buttonText: updateAvailable ? qsTr("Update")
                                                    : qsTr("Close")

                        function updateState() {
                            if (updateAvailable)
                                show()
                            else
                                showFor(5000)
                        }

                        Component.onCompleted: {
                            updateState()
                        }
                        onUpdateAvailableChanged: {
                            updateState();
                        }
                        onClicked: {
                            if (updateAvailable)
                                Global.openDownloadModal(appMain.rootStore.newVersionAvailable,
                                                         appMain.rootStore.latestVersion,
                                                         appMain.rootStore.downloadURL)
                            else
                                close()
                        }
                        onCloseClicked: {
                            if (updateAvailable)
                                appMain.rootStore.resetLastVersion();
                            hide()
                        }
                        onHideFinished: {
                            destroy()
                            bannersLayout.updateBanner = null
                        }
                    }
                }

                ConnectionWarnings {
                    id: walletBlockchainConnectionBanner
                    objectName: "walletBlockchainConnectionBanner"
                    Layout.fillWidth: true
                    websiteDown: Constants.walletConnections.blockchains
                    withCache: networkConnectionStore.balanceCache
                    networkConnectionStore: appMain.networkConnectionStore
                    tooltipMessage: qsTr("Pocket Network (POKT) & Infura are currently both unavailable for %1. Balances for those chains are as of %2.").arg(jointChainIdString).arg(lastCheckedAt)
                    toastText: {
                        switch(connectionState) {
                        case Constants.ConnectionStatus.Success:
                            return qsTr("Pocket Network (POKT) connection successful")
                        case Constants.ConnectionStatus.Failure:
                            if(completelyDown) {
                                if(withCache)
                                    return qsTr("POKT & Infura down. Token balances are as of %1.").arg(lastCheckedAt)
                                else
                                    return qsTr("POKT & Infura down. Token balances cannot be retrieved.")
                            }
                            else if(chainIdsDown.length > 0) {
                                if(chainIdsDown.length > 2) {
                                    return qsTr("POKT & Infura down for <a href='#'>multiple chains </a>. Token balances for those chains cannot be retrieved.")
                                }
                                else if(chainIdsDown.length === 1) {
                                    return qsTr("POKT & Infura down for %1. %1 token balances are as of %2.").arg(jointChainIdString).arg(lastCheckedAt)
                                }
                                else {
                                    return qsTr("POKT & Infura down for %1. %1 token balances cannot be retrieved.").arg(jointChainIdString)
                                }
                            }
                            else
                                return ""
                        case Constants.ConnectionStatus.Retrying:
                            return qsTr("Retrying connection to POKT Network (grove.city).")
                        default:
                            return ""
                        }
                    }
                }

                ConnectionWarnings {
                    id: walletCollectiblesConnectionBanner
                    objectName: "walletCollectiblesConnectionBanner"
                    Layout.fillWidth: true
                    websiteDown: Constants.walletConnections.collectibles
                    withCache: lastCheckedAtUnix > 0
                    networkConnectionStore: appMain.networkConnectionStore
                    tooltipMessage: {
                        if(withCache)
                            return qsTr("Collectibles providers are currently unavailable for %1. Collectibles for those chains are as of %2.").arg(jointChainIdString).arg(lastCheckedAt)
                        else
                            return qsTr("Collectibles providers are currently unavailable for %1.").arg(jointChainIdString)
                    }
                    toastText: {
                        switch(connectionState) {
                        case Constants.ConnectionStatus.Success:
                            return qsTr("Collectibles providers connection successful")
                        case Constants.ConnectionStatus.Failure:
                            if(completelyDown) {
                                if(withCache)
                                    return qsTr("Collectibles providers down. Collectibles are as of %1.").arg(lastCheckedAt)
                                else
                                    return qsTr("Collectibles providers down. Collectibles cannot be retrieved.")
                            }
                            else if(chainIdsDown.length > 0) {
                                if(chainIdsDown.length > 2) {
                                    if(withCache)
                                        return qsTr("Collectibles providers down for <a href='#'>multiple chains</a>. Collectibles for these chains are as of %1.".arg(lastCheckedAt))
                                    else
                                        return qsTr("Collectibles providers down for <a href='#'>multiple chains</a>. Collectibles for these chains cannot be retrieved.")
                                }
                                else if(chainIdsDown.length === 1) {
                                    if(withCache)
                                        return qsTr("Collectibles providers down for %1. Collectibles for this chain are as of %2.").arg(jointChainIdString).arg(lastCheckedAt)
                                    else
                                        return qsTr("Collectibles providers down for %1. Collectibles for this chain cannot be retrieved.").arg(jointChainIdString)
                                }
                                else {
                                    if(withCache)
                                        return qsTr("Collectibles providers down for %1. Collectibles for these chains are as of %2.").arg(jointChainIdString).arg(lastCheckedAt)
                                    else
                                        return qsTr("Collectibles providers down for %1. Collectibles for these chains cannot be retrieved.").arg(jointChainIdString)
                                }
                            }
                            else
                                return ""
                        case Constants.ConnectionStatus.Retrying:
                            return qsTr("Retrying connection to collectibles providers...")
                        default:
                            return ""
                        }
                    }
                }

                ConnectionWarnings {
                    id: walletMarketConnectionBanner
                    objectName: "walletMarketConnectionBanner"
                    Layout.fillWidth: true
                    websiteDown: Constants.walletConnections.market
                    withCache: networkConnectionStore.marketValuesCache
                    networkConnectionStore: appMain.networkConnectionStore
                    toastText: {
                        switch(connectionState) {
                        case Constants.ConnectionStatus.Success:
                            return qsTr("CryptoCompare and CoinGecko connection successful")
                        case Constants.ConnectionStatus.Failure: {
                            if(withCache) {
                                return qsTr("CryptoCompare and CoinGecko down. Market values are as of %1.").arg(lastCheckedAt)
                            }
                            else {
                                return qsTr("CryptoCompare and CoinGecko down. Market values cannot be retrieved.")
                            }
                        }
                        case Constants.ConnectionStatus.Retrying:
                            return qsTr("Retrying connection to CryptoCompare and CoinGecko...")
                        default:
                            return ""
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    id: appView
                    anchors.fill: parent

                    currentIndex: {
                        const activeSectionType = appMain.rootStore.mainModuleInst.activeSection.sectionType

                        if (activeSectionType === Constants.appSection.chat)
                            return Constants.appViewStackIndex.chat
                        if (activeSectionType === Constants.appSection.community) {
                            for (let i = this.children.length - 1; i >=0; i--) {
                                var obj = this.children[i]
                                if (obj && obj.sectionId && obj.sectionId === appMain.rootStore.mainModuleInst.activeSection.id) {
                                    return i
                                }
                            }

                            // Should never be here, correct index must be returned from the for loop above
                            console.error("Wrong section type:", appMain.rootStore.mainModuleInst.activeSection.sectionType,
                                          "or section id: ", appMain.rootStore.mainModuleInst.activeSection.id)
                            return Constants.appViewStackIndex.community
                        }
                        if (activeSectionType === Constants.appSection.communitiesPortal)
                            return Constants.appViewStackIndex.communitiesPortal
                        if (activeSectionType === Constants.appSection.wallet)
                            return Constants.appViewStackIndex.wallet
                        if (activeSectionType === Constants.appSection.browser)
                            return Constants.appViewStackIndex.browser
                        if (activeSectionType === Constants.appSection.profile)
                            return Constants.appViewStackIndex.profile
                        if (activeSectionType === Constants.appSection.node)
                            return Constants.appViewStackIndex.node

                        // We should never end up here
                        console.error("AppMain: Unknown section type")
                    }

                    // NOTE:
                    // If we ever change stack layout component order we need to updade
                    // Constants.appViewStackIndex accordingly

                    Loader {
                        id: personalChatLayoutLoader
                        asynchronous: true
                        active: false
                        sourceComponent: {
                            if (appMain.rootStore.mainModuleInst.chatsLoadingFailed) {
                                return errorStateComponent
                            }
                            if (appMain.rootStore.mainModuleInst.sectionsLoaded) {
                                return personalChatLayoutComponent
                            }
                            return loadingStateComponent
                        }

                        // Do not unload section data from the memory in order not
                        // to reset scroll, not send text input and etc during the
                        // sections switching
                        Binding on active {
                            when: appView.currentIndex === Constants.appViewStackIndex.chat
                            value: true
                            restoreMode: Binding.RestoreNone
                        }

                        Component {
                            id: loadingStateComponent
                            Item {
                                anchors.fill: parent

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    StatusBaseText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Loading sections...")
                                    }
                                    LoadingAnimation { anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }

                        Component {
                            id: errorStateComponent
                            Item {
                                anchors.fill: parent
                                StatusBaseText {
                                    text: qsTr("Error loading chats, try closing the app and restarting")
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        Component {
                            id: personalChatLayoutComponent

                            ChatLayout {
                                id: chatLayoutContainer

                                Binding {
                                    target: rootDropAreaPanel
                                    property: "enabled"
                                    value: chatLayoutContainer.currentIndex === 0 // Meaning: Chats / channels view
                                    when: visible
                                    restoreMode: Binding.RestoreBindingOrValue
                                }

                                rootStore: ChatStores.RootStore {
                                    contactsStore: appMain.rootStore.contactStore
                                    communityTokensStore: appMain.communityTokensStore
                                    emojiReactionsModel: appMain.rootStore.emojiReactionsModel
                                    openCreateChat: createChatView.opened
                                    chatCommunitySectionModule: appMain.rootStore.mainModuleInst.getChatSectionModule()
                                    networkConnectionStore: appMain.networkConnectionStore
                                }
                                createChatPropertiesStore: appMain.createChatPropertiesStore
                                tokensStore: appMain.tokensStore
                                transactionStore: appMain.transactionStore
                                walletAssetsStore: appMain.walletAssetsStore
                                currencyStore: appMain.currencyStore
                                emojiPopup: statusEmojiPopup.item
                                stickersPopup: statusStickersPopupLoader.item

                                onProfileButtonClicked: {
                                    Global.changeAppSectionBySectionType(Constants.appSection.profile);
                                }

                                onOpenAppSearch: {
                                    appSearch.openSearchPopup()
                                }
                            }
                        }
                    }

                    Loader {
                        active: appView.currentIndex === Constants.appViewStackIndex.communitiesPortal
                        asynchronous: true
                        CommunitiesPortalLayout {
                            anchors.fill: parent
                            communitiesStore: appMain.communitiesStore
                            assetsModel: appMain.rootStore.globalAssetsModel
                            collectiblesModel: appMain.rootStore.globalCollectiblesModel
                            notificationCount: appMain.activityCenterStore.unreadNotificationsCount
                            hasUnseenNotifications: activityCenterStore.hasUnseenNotifications
                        }
                    }

                    Loader {
                        id: walletLoader
                        active: appView.currentIndex === Constants.appViewStackIndex.wallet
                        asynchronous: true
                        sourceComponent: WalletLayout {
                            objectName: "walletLayoutReal"
                            store: appMain.rootStore
                            contactsStore: appMain.rootStore.profileSectionStore.contactsStore
                            communitiesStore: appMain.communitiesStore
                            transactionStore: appMain.transactionStore
                            emojiPopup: statusEmojiPopup.item
                            sendModalPopup: sendModal
                            networkConnectionStore: appMain.networkConnectionStore
                            appMainVisible: appMain.visible
                        }
                        onLoaded: {
                            item.resetView()
                        }
                    }

                    Loader {
                        id: browserLayoutContainer
                        active: appView.currentIndex === Constants.appViewStackIndex.browser
                        asynchronous: true
                        sourceComponent: BrowserLayout {
                            globalStore: appMain.rootStore
                            sendTransactionModal: sendModal
                            transactionStore: appMain.transactionStore
                            assetsStore: appMain.walletAssetsStore
                            currencyStore: appMain.currencyStore
                            tokensStore: appMain.tokensStore
                        }
                        // Loaders do not have access to the context, so props need to be set
                        // Adding a "_" to avoid a binding loop
                        // Not Refactored Yet
                        //                property var _chatsModel: chatsModel.messageView
                        // Not Refactored Yet
                        //                property var _walletModel: walletModel
                        // Not Refactored Yet
                        //                property var _utilsModel: utilsModel
                        //  property var _web3Provider: BrowserStores.Web3ProviderStore.web3ProviderInst
                    }

                    Loader {
                        active: appView.currentIndex === Constants.appViewStackIndex.profile
                        asynchronous: true
                        sourceComponent: ProfileLayout {
                            store: appMain.rootStore.profileSectionStore
                            globalStore: appMain.rootStore
                            systemPalette: appMain.sysPalette
                            emojiPopup: statusEmojiPopup.item
                            networkConnectionStore: appMain.networkConnectionStore
                            tokensStore: appMain.tokensStore
                            transactionStore: appMain.transactionStore
                            walletAssetsStore: appMain.walletAssetsStore
                            collectiblesStore: appMain.walletCollectiblesStore
                            currencyStore: appMain.currencyStore
                            isCentralizedMetricsEnabled: appMain.isCentralizedMetricsEnabled
                        }
                    }

                    Loader {
                        active: appView.currentIndex === Constants.appViewStackIndex.node
                        asynchronous: true
                        sourceComponent: NodeLayout {}
                    }

                    Repeater {
                        model: SortFilterProxyModel {
                            sourceModel: appMain.rootStore.mainModuleInst.sectionsModel
                            filters: ValueFilter {
                                roleName: "sectionType"
                                value: Constants.appSection.community
                            }
                        }

                        delegate: Loader {
                            id: communityLoader

                            readonly property string sectionId: model.id

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            Layout.fillHeight: true

                            asynchronous: true
                            active: false

                            // Do not unload section data from the memory in order not
                            // to reset scroll, not send text input and etc during the
                            // sections switching
                            Binding on active {
                                when: sectionId === appMain.rootStore.mainModuleInst.activeSection.id
                                value: true
                                restoreMode: Binding.RestoreNone
                            }

                            sourceComponent: ChatLayout {
                                id: chatLayoutComponent

                                readonly property bool isManageCommunityEnabledInAdvanced: appMain.rootStore.profileSectionStore.advancedStore.isManageCommunityOnTestModeEnabled

                                Binding {
                                    target: rootDropAreaPanel
                                    property: "enabled"
                                    value: chatLayoutComponent.currentIndex === 0 // Meaning: Chats / channels view
                                    when: visible
                                    restoreMode: Binding.RestoreBindingOrValue
                                }

                                Connections {
                                    target: Global
                                    function onSwitchToCommunitySettings(communityId: string) {
                                        if (communityId !== model.id)
                                            return
                                        chatLayoutComponent.currentIndex = 1 // Settings
                                    }
                                }

                                Connections {
                                    target: Global
                                    function onSwitchToCommunityChannelsView(communityId: string) {
                                        if (communityId !== model.id)
                                            return
                                        chatLayoutComponent.currentIndex = 0
                                    }
                                }

                                sendModalPopup: sendModal
                                emojiPopup: statusEmojiPopup.item
                                stickersPopup: statusStickersPopupLoader.item
                                sectionItemModel: model
                                createChatPropertiesStore: appMain.createChatPropertiesStore
                                communitiesStore: appMain.communitiesStore
                                communitySettingsDisabled: !chatLayoutComponent.isManageCommunityEnabledInAdvanced &&
                                                           (production && appMain.rootStore.profileSectionStore.walletStore.areTestNetworksEnabled)
                                rootStore: ChatStores.RootStore {
                                    contactsStore: appMain.rootStore.contactStore
                                    communityTokensStore: appMain.communityTokensStore
                                    emojiReactionsModel: appMain.rootStore.emojiReactionsModel
                                    openCreateChat: createChatView.opened
                                    chatCommunitySectionModule: {
                                        appMain.rootStore.mainModuleInst.prepareCommunitySectionModuleForCommunityId(model.id)
                                        return appMain.rootStore.mainModuleInst.getCommunitySectionModule()
                                    }
                                }
                                tokensStore: appMain.tokensStore
                                transactionStore: appMain.transactionStore
                                walletAssetsStore: appMain.walletAssetsStore
                                currencyStore: appMain.currencyStore

                                onProfileButtonClicked: {
                                    Global.changeAppSectionBySectionType(Constants.appSection.profile);
                                }

                                onOpenAppSearch: {
                                    appSearch.openSearchPopup()
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: createChatView

                    property bool opened: false
                    active: appMain.rootStore.mainModuleInst.sectionsLoaded && opened

                    asynchronous: true
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: active ?
                            parent.width - Constants.chatSectionLeftColumnWidth -
                            anchors.rightMargin - anchors.leftMargin : 0

                    sourceComponent: CreateChatView {
                        rootStore: ChatStores.RootStore {
                            contactsStore: appMain.rootStore.contactStore
                            communityTokensStore: appMain.communityTokensStore
                            emojiReactionsModel: appMain.rootStore.emojiReactionsModel
                            openCreateChat: createChatView.opened
                            chatCommunitySectionModule: appMain.rootStore.mainModuleInst.getChatSectionModule()
                        }
                        createChatPropertiesStore: appMain.createChatPropertiesStore
                        emojiPopup: statusEmojiPopup.item
                        stickersPopup: statusStickersPopupLoader.item
                    }
                }
            }
        } // ColumnLayout

        Component {
            id: activityCenterPopupComponent
            ActivityCenterPopup {
                // TODO get screen size // Taken from old code top bar height was fixed there to 56
                readonly property int _buttonSize: 56

                x: parent.width - width - Style.current.smallPadding
                y: parent.y + _buttonSize
                height: appView.height - _buttonSize * 2
                store: ChatStores.RootStore {
                    contactsStore: appMain.rootStore.contactStore
                    communityTokensStore: appMain.communityTokensStore
                    emojiReactionsModel: appMain.rootStore.emojiReactionsModel
                    openCreateChat: createChatView.opened
                    walletStore: WalletStore.RootStore
                    chatCommunitySectionModule: appMain.rootStore.mainModuleInst.getChatSectionModule()
                }
                activityCenterStore: appMain.activityCenterStore
            }
        }

        // Add SendModal here as it is used by the Wallet as well as the Browser
        Loader {
            id: sendModal
            active: false

            function open(address = "") {
                if (!!address) {
                    preSelectedRecipient = address
                    preSelectedRecipientType = SendPopups.Helpers.RecipientAddressObjectType.Address
                }
                this.active = true
                this.item.open()
            }

            function closed() {
                // this.sourceComponent = undefined // kill an opened instance
                this.active = false
            }

            property string preSelectedAccountAddress
            property var preSelectedRecipient
            property int preSelectedRecipientType
            property string preSelectedHoldingID
            property int preSelectedHoldingType: Constants.TokenType.Unknown
            property int preSelectedSendType: Constants.SendType.Unknown
            property string preDefinedAmountToSend
            property bool onlyAssets: false

            sourceComponent: SendPopups.SendModal {
                onlyAssets: sendModal.onlyAssets                

                loginType: appMain.rootStore.loginType

                store: appMain.transactionStore
                collectiblesStore: appMain.walletCollectiblesStore

                onClosed: {
                    sendModal.closed()
                    sendModal.preSelectedSendType = Constants.SendType.Unknown
                    sendModal.preSelectedHoldingID = ""
                    sendModal.preSelectedHoldingType = Constants.TokenType.Unknown
                    sendModal.preSelectedAccountAddress = ""
                    sendModal.preSelectedRecipient = undefined
                    sendModal.preDefinedAmountToSend = ""
                }
            }
            onLoaded: {
                if (!!sendModal.preSelectedAccountAddress) {
                    item.preSelectedAccountAddress = sendModal.preSelectedAccountAddress
                }
                if (!!sendModal.preSelectedRecipient) {
                    item.preSelectedRecipient = sendModal.preSelectedRecipient
                    item.preSelectedRecipientType = sendModal.preSelectedRecipientType
                }
                if(sendModal.preSelectedSendType !== Constants.SendType.Unknown) {
                    item.preSelectedSendType = sendModal.preSelectedSendType
                }
                if(preSelectedHoldingType !== Constants.TokenType.Unknown) {
                    item.preSelectedHoldingID = sendModal.preSelectedHoldingID
                    item.preSelectedHoldingType = sendModal.preSelectedHoldingType
                }
                if(preDefinedAmountToSend != "") {
                    item.preDefinedAmountToSend = preDefinedAmountToSend
                }
            }
        }

        Action {
            shortcut: "Ctrl+1"
            onTriggered: {
                Global.setNthEnabledSectionActive(0)
            }
        }
        Action {
            shortcut: "Ctrl+2"
            onTriggered: {
                Global.setNthEnabledSectionActive(1)
            }
        }
        Action {
            shortcut: "Ctrl+3"
            onTriggered: {
                Global.setNthEnabledSectionActive(2)
            }
        }
        Action {
            shortcut: "Ctrl+4"
            onTriggered: {
                Global.setNthEnabledSectionActive(3)
            }
        }
        Action {
            shortcut: "Ctrl+5"
            onTriggered: {
                Global.setNthEnabledSectionActive(4)
            }
        }
        Action {
            shortcut: "Ctrl+6"
            onTriggered: {
                Global.setNthEnabledSectionActive(5)
            }
        }
        Action {
            shortcut: "Ctrl+7"
            onTriggered: {
                Global.setNthEnabledSectionActive(6)
            }
        }
        Action {
            shortcut: "Ctrl+8"
            onTriggered: {
                Global.setNthEnabledSectionActive(7)
            }
        }
        Action {
            shortcut: "Ctrl+9"
            onTriggered: {
                Global.setNthEnabledSectionActive(8)
            }
        }

        Action {
            shortcut: "Ctrl+K"
            onTriggered: {
                // FIXME the focus is no longer on the AppMain when the popup is opened, so this does not work to close
                if (!channelPickerLoader.active)
                    channelPickerLoader.active = true

                if (channelPickerLoader.item.opened) {
                    channelPickerLoader.item.close()
                    channelPickerLoader.active = false
                } else {
                    channelPickerLoader.item.open()
                }
            }
        }
        Action {
            shortcut: "Ctrl+F"
            onTriggered: {
                // FIXME the focus is no longer on the AppMain when the popup is opened, so this does not work to close
                if (appSearch.active) {
                    appSearch.closeSearchPopup()
                } else {
                    appSearch.openSearchPopup()
                }
            }
        }

        Loader {
            id: channelPickerLoader
            active: false
            asynchronous: true
            sourceComponent: StatusSearchListPopup {
                searchBoxPlaceholder: qsTr("Where do you want to go?")
                model: rootStore.chatSearchModel
                delegate: StatusListItem {
                    property var modelData
                    property bool isCurrentItem: true
                    function filterAccepts(searchText) {
                        const lowerCaseSearchText = searchText.toLowerCase()
                        return title.toLowerCase().includes(lowerCaseSearchText) || label.toLowerCase().includes(lowerCaseSearchText)
                    }

                    title: modelData ? modelData.name : ""
                    label: modelData? modelData.sectionName : ""
                    highlighted: isCurrentItem
                    sensor.hoverEnabled: false
                    statusListItemIcon {
                        name: modelData ? modelData.name : ""
                        active: true
                    }
                    asset.width: 30
                    asset.height: 30
                    asset.color: modelData ? modelData.color ? modelData.color : Utils.colorForColorId(modelData.colorId) : ""
                    asset.name: modelData ? modelData.icon : ""
                    asset.charactersLen: 2
                    asset.letterSize: asset._twoLettersSize
                    ringSettings.ringSpecModel: modelData ? modelData.colorHash : undefined
                }

                onAboutToShow: rootStore.rebuildChatSearchModel()
                onSelected: {
                    rootStore.setActiveSectionChat(modelData.sectionId, modelData.chatId)
                    close()
                }
            }
        }
    }

    StatusListView {
        id: toastArea
        objectName: "ephemeralNotificationList"
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        width: 374
        height: Math.min(parent.height - 120, toastArea.contentHeight)
        spacing: 8
        verticalLayoutDirection: ListView.BottomToTop
        model: appMain.rootStore.mainModuleInst.ephemeralNotificationModel
        clip: false

        delegate: StatusToastMessage {
            property bool isSquare : isSquareShape(model.actionData)

            // Specific method to calculate image radius depending on if the toast represents some info about a collectible or an asset
            function isSquareShape(data) {
                // It expects the data is a JSON file containing `tokenType`
                if(data) {
                    var parsedData = JSON.parse(data)
                    var tokenType = parsedData.tokenType
                    return tokenType === Constants.TokenType.ERC721
                }
                return false
            }

            objectName: "statusToastMessage"
            width: ListView.view.width
            primaryText: model.title
            secondaryText: model.subTitle
            image: model.image
            imageRadius: model.image && isSquare ? 8 : imageSize / 2
            icon.name: model.icon
            iconColor: model.iconColor
            loading: model.loading
            type: model.ephNotifType
            linkUrl: model.url
            actionRequired: model.actionType !== ToastsManager.ActionType.None
            duration: model.durationInMs
            onClicked: {
                appMain.rootStore.mainModuleInst.ephemeralNotificationClicked(model.timestamp)
                this.open = false
            }
            onLinkActivated: {
                this.open = false
                if(actionRequired) {
                    toastsManager.doAction(model.actionType, model.actionData)
                    return
                }

                if (link.startsWith("#") && link !== "#") { // internal link to section
                    const sectionArgs = link.substring(1).split("/")
                    const section = sectionArgs[0]
                    let subsection = sectionArgs.length > 1 ? sectionArgs[1] : 0
                    let subsubsection = sectionArgs.length > 2 ? sectionArgs[2] : -1
                    Global.changeAppSectionBySectionType(section, subsection, subsubsection)
                }
                else
                    Global.openLink(link)
            }
            onClose: {
                appMain.rootStore.mainModuleInst.removeEphemeralNotification(model.timestamp)
            }
        }
    }

    Loader {
        id: keycardPopupForAuthenticationOrSigning
        active: false
        sourceComponent: KeycardPopup {
            sharedKeycardModule: appMain.rootStore.mainModuleInst.keycardSharedModuleForAuthenticationOrSigning
        }

        onLoaded: {
            keycardPopupForAuthenticationOrSigning.item.open()
        }
    }

    Loader {
        id: keycardPopup
        active: false
        sourceComponent: KeycardPopup {
            sharedKeycardModule: appMain.rootStore.mainModuleInst.keycardSharedModule
        }

        onLoaded: {
            keycardPopup.item.open()
        }
    }

    Loader {
        id: addEditSavedAddress

        active: false

        property var params

        function open(params = {}) {
            addEditSavedAddress.params = params
            addEditSavedAddress.active = true
        }

        function close() {
            addEditSavedAddress.active = false
        }

        onLoaded: {
            addEditSavedAddress.item.initWithParams(addEditSavedAddress.params)
            addEditSavedAddress.item.open()
        }

        sourceComponent: WalletPopups.AddEditSavedAddressPopup {
            flatNetworks: WalletStore.RootStore.filteredFlatModel

            onClosed: {
                addEditSavedAddress.close()
            }
        }

        Connections {
            target: WalletStore.RootStore

            function onSavedAddressAddedOrUpdated(added: bool, name: string, address: string, errorMsg: string) {
                WalletStore.RootStore.addingSavedAddress = false
                WalletStore.RootStore.lastCreatedSavedAddress = { address: address, error: errorMsg }

                if (!!errorMsg) {
                    let mode = qsTr("adding")
                    if (!added) {
                        mode = qsTr("editing")
                    }

                    Global.displayToastMessage(qsTr("An error occurred while %1 %2 address").arg(mode).arg(name),
                                               "",
                                               "warning",
                                               false,
                                               Constants.ephemeralNotificationType.danger,
                                               ""
                                               )
                    return
                }

                let msg = qsTr("%1 successfully added to your saved addresses")
                if (!added) {
                    msg = qsTr("%1 saved address successfully edited")
                }
                Global.displayToastMessage(msg.arg(name),
                                           "",
                                           "checkmark-circle",
                                           false,
                                           Constants.ephemeralNotificationType.success,
                                           ""
                                           )

            }
        }
    }

    Loader {
        id: deleteSavedAddress

        active: false

        property var params

        function open(params = {}) {
            deleteSavedAddress.params = params
            deleteSavedAddress.active = true
        }

        function close() {
            deleteSavedAddress.active = false
        }

        onLoaded: {
            deleteSavedAddress.item.address = deleteSavedAddress.params.address?? ""
            deleteSavedAddress.item.ens = deleteSavedAddress.params.ens?? ""
            deleteSavedAddress.item.name = deleteSavedAddress.params.name?? ""
            deleteSavedAddress.item.colorId = deleteSavedAddress.params.colorId?? "blue"
            deleteSavedAddress.item.chainShortNames = deleteSavedAddress.params.chainShortNames?? ""

            deleteSavedAddress.item.open()
        }

        sourceComponent: WalletPopups.RemoveSavedAddressPopup {
            onClosed: {
                deleteSavedAddress.close()
            }

            onRemoveSavedAddress: {
                WalletStore.RootStore.deleteSavedAddress(address)
                close()
            }
        }

        Connections {
            target: WalletStore.RootStore

            function onSavedAddressDeleted(name: string, address: string, errorMsg: string) {
                WalletStore.RootStore.deletingSavedAddress = false

                if (!!errorMsg) {

                    Global.displayToastMessage(qsTr("An error occurred while removing %1 address").arg(name),
                                               "",
                                               "warning",
                                               false,
                                               Constants.ephemeralNotificationType.danger,
                                               ""
                                               )
                    return
                }

                Global.displayToastMessage(qsTr("%1 was successfully removed from your saved addresses").arg(name),
                                           "",
                                           "checkmark-circle",
                                           false,
                                           Constants.ephemeralNotificationType.success,
                                           ""
                                           )
            }
        }
    }

    Loader {
        id: showQR

        active: false

        property bool showSingleAccount: false
        property bool showForSavedAddress: false
        property var params
        property var selectedAccount: ({
                                           name: "",
                                           address: "",
                                           preferredSharingChainIds: "",
                                           colorId: "",
                                           emoji: ""
                                       })

        function open(params = {}) {
            showQR.showSingleAccount = params.showSingleAccount?? false
            showQR.showForSavedAddress = params.showForSavedAddress?? false
            showQR.params = params

            if (showQR.showSingleAccount || showQR.showForSavedAddress) {
                showQR.selectedAccount.name = params.name?? ""
                showQR.selectedAccount.address = params.address?? ""
                showQR.selectedAccount.preferredSharingChainIds = params.preferredSharingChainIds?? ""
                showQR.selectedAccount.colorId = params.colorId?? ""
                showQR.selectedAccount.emoji = params.emoji?? ""
            }

            showQR.active = true
        }

        function close() {
            showQR.active = false
        }

        onLoaded: {
            showQR.item.switchingAccounsEnabled = showQR.params.switchingAccounsEnabled?? true
            showQR.item.changingPreferredChainsEnabled = showQR.params.changingPreferredChainsEnabled?? true
            showQR.item.hasFloatingButtons = showQR.params.hasFloatingButtons?? true

            showQR.item.open()
        }

        sourceComponent: WalletPopups.ReceiveModal {

            ModelEntry {
                id: selectedReceiverAccount
                key: "address"
                sourceModel: appMain.transactionStore.accounts
                value: appMain.transactionStore.selectedReceiverAccountAddress
            }

            accounts: {
                if (showQR.showSingleAccount || showQR.showForSavedAddress) {
                    return null
                }
                return WalletStore.RootStore.accounts
            }

            selectedAccount: {
                if (showQR.showSingleAccount || showQR.showForSavedAddress) {
                    return showQR.selectedAccount
                }
                return selectedReceiverAccount.item ?? SQUtils.ModelUtils.get(appMain.transactionStore.accounts, 0)
            }

            onUpdateSelectedAddress: (address) => {
                if (showQR.showSingleAccount || showQR.showForSavedAddress) {
                    return
                }
                appMain.transactionStore.setReceiverAccount(address)
            }

            onUpdatePreferredChains: {
                if (showQR.showForSavedAddress) {
                    let shortNames = WalletStore.RootStore.getNetworkShortNames(preferredChains)
                    WalletStore.RootStore.updatePreferredChains(address, shortNames)
                    return
                }
                WalletStore.RootStore.updateWalletAccountPreferredChains(address, preferredChains)
            }

            onClosed: {
                showQR.close()
            }
        }
    }


    Loader {
        id: savedAddressActivity

        active: false

        property var params

        function open(params = {}) {
            savedAddressActivity.params = params
            savedAddressActivity.active = true
        }

        function close() {
            savedAddressActivity.active = false
        }

        onLoaded: {
            savedAddressActivity.item.initWithParams(savedAddressActivity.params)
            savedAddressActivity.item.open()
        }

        sourceComponent: WalletPopups.SavedAddressActivityPopup {
            networkConnectionStore: appMain.networkConnectionStore
            contactsStore: appMain.rootStore.contactStore
            sendModalPopup: sendModal

            onClosed: {
                savedAddressActivity.close()
            }
        }
    }

    DropAreaPanel {
        id: rootDropAreaPanel

        width: appMain.width
        height: appMain.height
    }

    Loader {
        id: userAgreementLoader
        active: production && !localAppSettings.testEnvironment
        sourceComponent: UserAgreementPopup {
            visible: appMain.visible
            onClosed: userAgreementLoader.active = false
        }
    }

    Component {
        id: dappsConnectorSDK

        DappsConnectorSDK {
            active: WalletStore.RootStore.walletSectionInst.walletReady
            controller: WalletStore.RootStore.dappsConnectorController
            wcService: Global.walletConnectService
            walletStore: WalletStore.RootStore
            store: DAppsStore {
                controller: WalletStore.RootStore.walletConnectController
            }
            loginType: appMain.rootStore.loginType
        }
    }

    Loader {
        id: dappsConnectorSDKLoader
        active: Global.featureFlags.connectorEnabled
        sourceComponent: dappsConnectorSDK
    }

    Loader {
        id: walletConnectServiceLoader

        // It seems some of the functionality of the dapp connector depends on the WalletConnectService
        active: (Global.featureFlags.dappsEnabled || Global.featureFlags.connectorEnabled) && appMain.visible

        sourceComponent: WalletConnectService {
            id: walletConnectService

            wcSDK: WalletConnectSDK {
                active: WalletStore.RootStore.walletSectionInst.walletReady

                projectId: WalletStore.RootStore.appSettings.walletConnectProjectID
            }
            store: DAppsStore {
                controller: WalletStore.RootStore.walletConnectController
            }
            walletRootStore: WalletStore.RootStore

            Component.onCompleted: {
                Global.walletConnectService = walletConnectService
            }

            onDisplayToastMessage: (message, isErr) => {
                Global.displayToastMessage(message, "",
                    isErr ? "warning" : "checkmark-circle", false,
                    isErr ? Constants.ephemeralNotificationType.danger
                          : Constants.ephemeralNotificationType.success,
                    "")
            }
        }
    }
}
