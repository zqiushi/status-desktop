import ../shared_models/[currency_amount, wallet_account_item]

import app_service/service/currency/dto as currency_dto

import ../main/wallet_section/accounts/item as wallet_accounts_item

proc currencyAmountToItem*(amount: float64, format: CurrencyFormatDto) : CurrencyAmount =
  return newCurrencyAmount(
    amount,
    format.symbol,
    int(format.displayDecimals),
    format.stripTrailingZeroes
  )

proc walletAccountToWalletAccountItem*(w: WalletAccountDto, keycardAccount: bool, areTestNetworksEnabled: bool): WalletAccountItem =
  if w.isNil:
    return newWalletAccountItem()

  return newWalletAccountItem(
    w.name,
    w.address,
    w.colorId,
    w.emoji,
    w.walletType,
    w.path,
    w.keyUid,
    keycardAccount,
    w.position,
    w.operable,
    areTestNetworksEnabled,
    w.prodPreferredChainIds,
    w.testPreferredChainIds,
    w.hideFromTotalBalance
  )

proc walletAccountToWalletAccountsItem*(w: WalletAccountDto, keycardAccount: bool,
  chainIds: seq[int], enabledChainIds: seq[int], 
  currencyBalance: float64, currencyFormat: CurrencyFormatDto, areTestNetworksEnabled: bool,
  marketValuesLoading: bool): wallet_accounts_item.Item =
  return wallet_accounts_item.newItem(
    w.name,
    w.address,
    w.path,
    w.colorId,
    w.walletType,
    currencyAmountToItem(currencyBalance, currencyFormat),
    w.emoji,
    w.keyUid,
    w.createdAt,
    w.position,
    keycardAccount,
    w.assetsLoading or marketValuesLoading,
    w.isWallet,
    areTestNetworksEnabled,
    w.prodPreferredChainIds,
    w.testPreferredChainIds,
    w.hideFromTotalBalance,
    canSend=w.walletType != "watch" and (w.operable==AccountFullyOperable or w.operable==AccountPartiallyOperable)
  )
  