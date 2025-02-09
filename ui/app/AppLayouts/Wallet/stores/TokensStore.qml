import QtQuick 2.15

import SortFilterProxyModel 0.2
import StatusQ 0.1

import utils 1.0

QtObject {
    id: root

    /* PRIVATE: Modules used to get data from backend */
    readonly property var _allTokensModule: !!walletSectionAllTokens ? walletSectionAllTokens : null
    readonly property var _networksModule: !!networksModule ? networksModule : null

    readonly property double tokenListUpdatedAt: root._allTokensModule.tokenListUpdatedAt

    /* This contains the different sources for the tokens list
       ex. uniswap list, status tokens list */
    readonly property var sourcesOfTokensModel: SortFilterProxyModel {
        sourceModel: !!root._allTokensModule ? root._allTokensModule.sourcesOfTokensModel : null
        proxyRoles: FastExpressionRole {
            function sourceImage(name) {
                return Constants.getSupportedTokenSourceImage(name)
            }
            name: "image"
            expression: sourceImage(model.name)
            expectedRoles: ["name"]
        }
        filters: AnyOf {
            ValueFilter {
                roleName: "name"
                value: Constants.supportedTokenSources.uniswap
            }
            ValueFilter {
                roleName: "name"
                value: Constants.supportedTokenSources.status
            }
        }
    }

    /* This list contains the complete list of tokens with separate
       entry per token which has a unique [address + network] pair */
    readonly property var flatTokensModel: !!root._allTokensModule ? root._allTokensModule.flatTokensModel : null

    /* PRIVATE: This model just combines tokens and network information in one */
    readonly property LeftJoinModel _joinFlatTokensModel : LeftJoinModel {
        leftModel: root.flatTokensModel
        rightModel: root._networksModule.flatNetworks

        joinRole: "chainId"
    }

    /* This list contains the complete list of tokens with separate
       entry per token which has a unique [address + network] pair including extended information
       about the specific network per entry */
    readonly property var extendedFlatTokensModel: SortFilterProxyModel {
        sourceModel: root._joinFlatTokensModel

        proxyRoles:  [
            JoinRole {
                name: "explorerUrl"
                roleNames: ["blockExplorerURL", "address"]
                separator: "/token/"
            },
            FastExpressionRole {
                function tokenIcon(symbol) {
                    return Constants.tokenIcon(symbol)
                }
                name: "image"
                expression: tokenIcon(model.symbol)
                expectedRoles: ["symbol"]
            }
        ]
    }

    /* This list contains list of tokens grouped by symbol
       EXCEPTION: We may have different entries for the same symbol in case
       of symbol clash when minting community tokens, so in case of community tokens
       there will be one entry per address + network pair */
    // TODO in #12513
    readonly property var plainTokensBySymbolModel: !!root._allTokensModule ? root._allTokensModule.tokensBySymbolModel : null
    readonly property var assetsBySymbolModel: SortFilterProxyModel {
        sourceModel: plainTokensBySymbolModel
        proxyRoles: [
            FastExpressionRole {
                function tokenIcon(symbol) {
                    return Constants.tokenIcon(symbol)
                }
                name: "iconSource"
                expression: tokenIcon(model.symbol)
                expectedRoles: ["symbol"]
            },
            // TODO: Review if it can be removed
            FastExpressionRole {
                name: "shortName"
                expression: model.symbol
                expectedRoles: ["symbol"]
            },
            FastExpressionRole {
                function getCategory(index) {
                    return 0
                }
                name: "category"
                expression: getCategory(model.communityId)
                expectedRoles: ["communityId"]
            }
        ]
    }

    // Property and methods below are used to apply advanced token management settings to the SendModal
    readonly property bool showCommunityAssetsInSend: root._allTokensModule.showCommunityAssetWhenSendingTokens
    readonly property bool displayAssetsBelowBalance: root._allTokensModule.displayAssetsBelowBalance

    signal displayAssetsBelowBalanceThresholdChanged()

    function getDisplayAssetsBelowBalanceThresholdCurrency() {
        return root._allTokensModule.displayAssetsBelowBalanceThreshold
    }

    function getDisplayAssetsBelowBalanceThresholdDisplayAmount() {
        const thresholdCurrency = getDisplayAssetsBelowBalanceThresholdCurrency()
        return thresholdCurrency.amount / Math.pow(10, thresholdCurrency.displayDecimals)
    }

    function setDisplayAssetsBelowBalanceThreshold(rawValue) {
        // rawValue - raw amount (multiplied by displayDecimals)`
        root._allTokensModule.setDisplayAssetsBelowBalanceThreshold(rawValue)
    }

    function toggleShowCommunityAssetsInSend() {
        root._allTokensModule.toggleShowCommunityAssetWhenSendingTokens()
    }

    function toggleDisplayAssetsBelowBalance() {
        root._allTokensModule.toggleDisplayAssetsBelowBalance()
    }

    readonly property Connections allTokensConnections: Connections {
        target: root._allTokensModule

        function onDisplayAssetsBelowBalanceThresholdChanged() {
            root.displayAssetsBelowBalanceThresholdChanged()
        }
    }

    function updateTokenPreferences(jsonData) {
        root._allTokensModule.updateTokenPreferences(jsonData)
    }

    function getTokenPreferencesJson(jsonData) {
        return root._allTokensModule.getTokenPreferencesJson(jsonData)
    }
}
