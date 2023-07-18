import strutils, stint
import ../../../../global/global_singleton

import ../../../../../app_service/service/transaction/dto
import ../../../../../app_service/service/currency/dto as currency_dto
import ../../../shared/wallet_utils
import ../../../shared_models/currency_amount

import ./item
import ./multi_transaction_item

import ./backend/transactions

proc hex2GweiCurrencyAmount(hexValueStr: string, gweiFormat: CurrencyFormatDto): CurrencyAmount =
  let value = parseFloat(singletonInstance.utils.hex2Gwei(hexValueStr))
  return currencyAmountToItem(value, gweiFormat)

proc hex2EthCurrencyAmount(hexValueStr: string, ethFormat: CurrencyFormatDto): CurrencyAmount  =
  let value = parseFloat(singletonInstance.utils.hex2Eth(hexValueStr))
  return currencyAmountToItem(value, ethFormat)

proc hex2TokenCurrencyAmount(hexValueStr: string, tokenFormat: CurrencyFormatDto): CurrencyAmount  =
  let value = parseFloat(singletonInstance.utils.hex2Eth(hexValueStr))
  return currencyAmountToItem(value, tokenFormat)

proc transactionToItem*(t: TransactionDto, resolvedSymbol: string, tokenFormat: CurrencyFormatDto, ethFormat: CurrencyFormatDto, gweiFormat: CurrencyFormatDto): Item =
  return initItem(
        t.id,
        t.typeValue,
        t.address,
        t.blockNumber,
        t.blockHash,
        toInt(t.timestamp),
        hex2EthCurrencyAmount(t.gasPrice, ethFormat),
        parseInt(singletonInstance.utils.hex2Dec(t.gasLimit)),
        parseInt(singletonInstance.utils.hex2Dec(t.gasUsed)),
        t.nonce,
        t.txStatus,
        hex2TokenCurrencyAmount(t.value, tokenFormat),
        t.fromAddress,
        t.to,
        t.contract,
        t.chainId,
        hex2GweiCurrencyAmount(t.maxFeePerGas, gweiFormat),
        hex2GweiCurrencyAmount(t.maxPriorityFeePerGas, gweiFormat),
        t.input,
        t.txHash,
        t.multiTransactionID,
        false,
        hex2GweiCurrencyAmount(t.baseGasFees, gweiFormat),
        hex2GweiCurrencyAmount(t.totalFees, gweiFormat),
        hex2GweiCurrencyAmount(t.maxTotalFees, gweiFormat),
        resolvedSymbol
      )

proc multiTransactionToItem*(t: MultiTransactionDto): MultiTransactionItem =
  return initMultiTransactionItem(
        t.id,
        t.timestamp,
        t.fromAddress,
        t.toAddress,
        t.fromAsset,
        t.toAsset,
        t.fromAmount,
        t.multiTxType
      )