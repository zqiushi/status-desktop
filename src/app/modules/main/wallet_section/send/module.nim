import tables, NimQml, sequtils, sugar, stint, strutils, chronicles, options

import ./io_interface, ./view, ./controller, ./network_route_item, ./transaction_routes, ./suggested_route_item, ./suggested_route_model, ./gas_estimate_item, ./gas_fees_item, ./network_route_model
import ../io_interface as delegate_interface
import app/global/global_singleton
import app/core/eventemitter
import app_service/service/wallet_account/service as wallet_account_service
import app_service/service/network/service as network_service
import app_service/service/currency/service as currency_service
import app_service/service/transaction/service as transaction_service
import app_service/service/keycard/service as keycard_service
import app_service/service/keycard/constants as keycard_constants
import app_service/service/transaction/dto
import app_service/service/transaction/dtoV2
import app_service/service/transaction/dto_conversion
import app/modules/shared_models/currency_amount
import app_service/service/network/network_item as network_service_item

import app/modules/shared_modules/collectibles/controller as collectiblesc
import app/modules/shared_models/collectibles_model as collectibles
import app/modules/shared_models/collectibles_nested_model as nested_collectibles
import backend/collectibles as backend_collectibles

export io_interface

logScope:
  topics = "wallet-send-module"

const authenticationCanceled* = "authenticationCanceled"

# Shouldn't be public ever, use only within this module.
type TmpSendTransactionDetails = object
  fromAddr: string
  fromAddrPath: string
  toAddr: string
  assetKey: string
  toAssetKey: string
  paths: seq[TransactionPathDto]
  uuid: string
  sendType: SendType
  resolvedSignatures: TransactionsSignatures
  tokenName: string
  isOwnerToken: bool
  slippagePercentage: Option[float]

type
  Module* = ref object of io_interface.AccessInterface
    delegate: delegate_interface.AccessInterface
    events: EventEmitter
    view: View
    viewVariant: QVariant
    controller: controller.Controller
    # Get the list of owned collectibles by the currently selected account
    collectiblesController: collectiblesc.Controller
    nestedCollectiblesModel: nested_collectibles.Model
    moduleLoaded: bool
    tmpSendTransactionDetails: TmpSendTransactionDetails
    tmpPin: string
    tmpTxHashBeingProcessed: string

# Forward declaration
method getTokenBalance*(self: Module, address: string, chainId: int, tokensKey: string): CurrencyAmount

proc newModule*(
  delegate: delegate_interface.AccessInterface,
  events: EventEmitter,
  walletAccountService: wallet_account_service.Service,
  networkService: network_service.Service,
  currencyService: currency_service.Service,
  transactionService: transaction_service.Service,
  keycardService: keycard_service.Service
): Module =
  result = Module()
  result.delegate = delegate
  result.events = events
  result.controller = controller.newController(result, events, walletAccountService, networkService, currencyService,
    transactionService, keycardService)
  result.collectiblesController = collectiblesc.newController(
    requestId = int32(backend_collectibles.CollectiblesRequestID.WalletSend),
    loadType = collectiblesc.LoadType.AutoLoadSingleUpdate,
    networkService = networkService,
    events = events
  )
  result.nestedCollectiblesModel = nested_collectibles.newModel(result.collectiblesController.getModel())
  result.view = newView(result)
  result.viewVariant = newQVariant(result.view)

  result.moduleLoaded = false

method delete*(self: Module) =
  self.viewVariant.delete
  self.view.delete
  self.controller.delete
  self.nestedCollectiblesModel.delete
  self.collectiblesController.delete

proc convertSendToNetworkToNetworkItem(self: Module, network: SendToNetwork): NetworkRouteItem =
  result = initNetworkRouteItem(
      network.chainId,
      layer = 0,
      true,
      true,
      true,
      newCurrencyAmount(),
      false,
      lockedAmount = "",
      amountIn = "",
      $network.amountOut)

proc convertNetworkDtoToNetworkRouteItem(self: Module, network: network_service_item.NetworkItem): NetworkRouteItem =
  result = initNetworkRouteItem(
      network.chainId, 
      network.layer,
      true,
      false,
      true,
      self.getTokenBalance(self.view.getSelectedSenderAccountAddress(), network.chainId, self.view.getSelectedAssetKey())
      )

proc convertSuggestedFeesDtoToGasFeesItem(self: Module, gasFees: SuggestedFeesDto): GasFeesItem =
  result = newGasFeesItem(
    gasPrice = gasFees.gasPrice,
    baseFee = gasFees.baseFee,
    maxPriorityFeePerGas = gasFees.maxPriorityFeePerGas,
    maxFeePerGasL = gasFees.maxFeePerGasL,
    maxFeePerGasM = gasFees.maxFeePerGasM,
    maxFeePerGasH = gasFees.maxFeePerGasH,
    l1GasFee = gasFees.l1GasFee,
    eip1559Enabled = gasFees.eip1559Enabled
    )

proc convertFeesDtoToGasEstimateItem(self: Module, fees: FeesDto): GasEstimateItem =
  result = newGasEstimateItem(
    totalFeesInEth = fees.totalFeesInEth,
    totalTokenFees = fees.totalTokenFees,
    totalTime = fees.totalTime
    )

proc convertTransactionPathDtoToSuggestedRouteItem(self: Module, path: TransactionPathDto): SuggestedRouteItem =
  result = newSuggestedRouteItem(
    bridgeName = path.bridgeName,
    fromNetwork = path.fromNetwork.chainId,
    toNetwork = path.toNetwork.chainId,
    maxAmountIn = $path.maxAmountIn,
    amountIn = $path.amountIn,
    amountOut = $path.amountOut,
    gasAmount = $path.gasAmount,
    gasFees = self.convertSuggestedFeesDtoToGasFeesItem(path.gasFees),
    tokenFees = path.tokenFees,
    cost = path.cost,
    estimatedTime = path.estimatedTime,
    amountInLocked = path.amountInLocked,
    isFirstSimpleTx = path.isFirstSimpleTx,
    isFirstBridgeTx = path.isFirstBridgeTx,
    approvalRequired = path.approvalRequired,
    approvalGasFees = path.approvalGasFees,
    approvalAmountRequired = $path.approvalAmountRequired,
    approvalContractAddress = path.approvalContractAddress
    )

proc refreshNetworks*(self: Module) =
  let networks = self.controller.getCurrentNetworks()
  let fromNetworks = networks.map(x => self.convertNetworkDtoToNetworkRouteItem(x))
  let toNetworks = networks.map(x => self.convertNetworkDtoToNetworkRouteItem(x))
  self.view.setNetworkItems(fromNetworks, toNetworks)

method load*(self: Module) =
  singletonInstance.engine.setRootContextProperty("walletSectionSend", self.viewVariant)

  # these connections should be part of the controller's init method
  self.events.on(SIGNAL_WALLET_ACCOUNT_NETWORK_ENABLED_UPDATED) do(e:Args):
    self.refreshNetworks()

  self.controller.init()
  self.view.load()

method isLoaded*(self: Module): bool =
  return self.moduleLoaded

method viewDidLoad*(self: Module) =
  self.refreshNetworks()
  self.moduleLoaded = true
  self.delegate.sendModuleDidLoad()

method getTokenBalance*(self: Module, address: string, chainId: int, tokensKey: string): CurrencyAmount =
  return self.controller.getTokenBalance(address, chainId, tokensKey)

method getNetworkItem*(self: Module, chainId: int): network_service_item.NetworkItem =
  let networks = self.controller.getCurrentNetworks().filter(x => x.chainId == chainId)
  if networks.len == 0:
    return nil
  return networks[0]

method authenticateAndTransfer*(self: Module, fromAddr: string, toAddr: string, assetKey: string, toAssetKey: string, uuid: string,
  sendType: SendType, selectedTokenName: string, selectedTokenIsOwnerToken: bool) =
  self.tmpSendTransactionDetails.fromAddr = fromAddr
  self.tmpSendTransactionDetails.toAddr = toAddr
  self.tmpSendTransactionDetails.assetKey = assetKey
  self.tmpSendTransactionDetails.toAssetKey = toAssetKey
  self.tmpSendTransactionDetails.uuid = uuid
  self.tmpSendTransactionDetails.sendType = sendType
  self.tmpSendTransactionDetails.fromAddrPath = ""
  self.tmpSendTransactionDetails.resolvedSignatures.clear()
  self.tmpSendTransactionDetails.tokenName = selectedTokenName
  self.tmpSendTransactionDetails.isOwnerToken = selectedTokenIsOwnerToken

  let kp = self.controller.getKeypairByAccountAddress(fromAddr)
  if kp.migratedToKeycard():
    let accounts = kp.accounts.filter(acc => cmpIgnoreCase(acc.address, fromAddr) == 0)
    if accounts.len != 1:
      error "cannot resolve selected account to send from among known keypair accounts"
      return
    self.tmpSendTransactionDetails.fromAddrPath = accounts[0].path
    self.controller.authenticate(kp.keyUid)
  else:
    self.controller.authenticate()

method authenticateAndTransferWithPaths*(self: Module, fromAddr: string, toAddr: string, assetKey: string, toAssetKey: string, uuid: string,
  sendType: SendType, selectedTokenName: string, selectedTokenIsOwnerToken: bool, rawPaths: string, slippagePercentage: Option[float]) =
  # Temporary until transaction service rework is completed
  let pathsV2 = rawPaths.toTransactionPathsDtoV2()
  let pathsV1 = pathsV2.convertToOldRoute().addFirstSimpleBridgeTxFlag()
  
  self.tmpSendTransactionDetails.paths = pathsV1
  self.tmpSendTransactionDetails.slippagePercentage = slippagePercentage
  self.authenticateAndTransfer(fromAddr, toAddr, assetKey, toAssetKey, uuid, sendType, selectedTokenName, selectedTokenIsOwnerToken)

method onUserAuthenticated*(self: Module, password: string, pin: string) =
  if password.len == 0:
    self.transactionWasSent(chainId = 0, txHash = "", uuid = self.tmpSendTransactionDetails.uuid, error = authenticationCanceled)
  else:
    self.tmpPin = pin
    let doHashing = self.tmpPin.len == 0
    let usePassword = self.tmpSendTransactionDetails.fromAddrPath.len == 0
    self.controller.transfer(
      self.tmpSendTransactionDetails.fromAddr, self.tmpSendTransactionDetails.toAddr,
      self.tmpSendTransactionDetails.assetKey, self.tmpSendTransactionDetails.toAssetKey, self.tmpSendTransactionDetails.uuid,
      self.tmpSendTransactionDetails.paths, password, self.tmpSendTransactionDetails.sendType, usePassword, doHashing,
      self.tmpSendTransactionDetails.tokenName, self.tmpSendTransactionDetails.isOwnerToken, self.tmpSendTransactionDetails.slippagePercentage
    )

proc signOnKeycard(self: Module) =
  self.tmpTxHashBeingProcessed = ""
  for h, (r, s, v) in self.tmpSendTransactionDetails.resolvedSignatures.pairs:
    if r.len != 0 and s.len != 0 and v.len != 0:
      continue
    self.tmpTxHashBeingProcessed = h
    var txForKcFlow = self.tmpTxHashBeingProcessed
    if txForKcFlow.startsWith("0x"):
      txForKcFlow = txForKcFlow[2..^1]
    self.controller.runSignFlow(self.tmpPin, self.tmpSendTransactionDetails.fromAddrPath, txForKcFlow)
    break
  if self.tmpTxHashBeingProcessed.len == 0:
    self.controller.proceedWithTransactionsSignatures(self.tmpSendTransactionDetails.fromAddr, self.tmpSendTransactionDetails.toAddr,
      self.tmpSendTransactionDetails.assetKey, self.tmpSendTransactionDetails.toAssetKey, self.tmpSendTransactionDetails.uuid,
      self.tmpSendTransactionDetails.resolvedSignatures, self.tmpSendTransactionDetails.paths, self.tmpSendTransactionDetails.sendType)

method prepareSignaturesForTransactions*(self: Module, txHashes: seq[string]) =
  if txHashes.len == 0:
    error "no transaction hashes to be signed"
    return
  for h in txHashes:
    self.tmpSendTransactionDetails.resolvedSignatures[h] = ("", "", "")
  self.signOnKeycard()

method onTransactionSigned*(self: Module, keycardFlowType: string, keycardEvent: KeycardEvent) =
  if keycardFlowType != keycard_constants.ResponseTypeValueKeycardFlowResult:
    error "unexpected error while keycard signing transaction"
    return
  self.tmpSendTransactionDetails.resolvedSignatures[self.tmpTxHashBeingProcessed] = (keycardEvent.txSignature.r,
    keycardEvent.txSignature.s, keycardEvent.txSignature.v)
  self.signOnKeycard()

method transactionWasSent*(self: Module, chainId: int, txHash, uuid, error: string) =
  if txHash.len == 0:
    self.view.sendTransactionSentSignal(chainId = 0, txHash = "", uuid = self.tmpSendTransactionDetails.uuid, error)
    return
  self.view.sendTransactionSentSignal(chainId, txHash, uuid, error)

method suggestedRoutesReady*(self: Module, uuid: string, suggestedRoutes: SuggestedRoutesDto, errCode: string, errDescription: string) =
  self.tmpSendTransactionDetails.paths = suggestedRoutes.best
  self.tmpSendTransactionDetails.slippagePercentage = none(float)
  let paths = suggestedRoutes.best.map(x => self.convertTransactionPathDtoToSuggestedRouteItem(x))
  let suggestedRouteModel = newSuggestedRouteModel()
  suggestedRouteModel.setItems(paths)
  let gasTimeEstimate = self.convertFeesDtoToGasEstimateItem(suggestedRoutes.gasTimeEstimate)
  let networks = suggestedRoutes.toNetworks.map(x => self.convertSendToNetworkToNetworkItem(x))
  let toNetworksRouteModel = newNetworkRouteModel()
  toNetworksRouteModel.setItems(networks)
  self.view.updatedNetworksWithRoutes(paths, self.controller.getChainsWithNoGasFromError(errCode, errDescription))
  let transactionRoutes = newTransactionRoutes(
    uuid = uuid,
    suggestedRoutes = suggestedRouteModel,
    gasTimeEstimate = gasTimeEstimate,
    amountToReceive = suggestedRoutes.amountToReceive,
    toNetworksRouteModel = toNetworksRouteModel,
    rawPaths = suggestedRoutes.rawBest)
  self.view.setTransactionRoute(transactionRoutes, errCode, errDescription)

method suggestedRoutes*(self: Module,
  uuid: string,
  sendType: SendType,
  accountFrom: string,
  accountTo: string,
  token: string,
  amountIn: string,
  toToken: string = "",
  amountOut: string = "",
  disabledFromChainIDs: seq[int] = @[],
  disabledToChainIDs: seq[int] = @[],
  lockedInAmounts: Table[string, string] = initTable[string, string](),
  extraParamsTable: Table[string, string] = initTable[string, string]()) =
  self.controller.suggestedRoutes(
    uuid,
    sendType,
    accountFrom,
    accountTo,
    token,
    amountIn,
    toToken,
    amountOut,
    disabledFromChainIDs,
    disabledToChainIDs,
    lockedInAmounts,
    extraParamsTable
  )

method filterChanged*(self: Module, addresses: seq[string], chainIds: seq[int]) =
  if addresses.len == 0:
    return
  self.view.setSenderAccount(addresses[0])
  self.view.setReceiverAccount(addresses[0])

proc updateCollectiblesFilter*(self: Module) =
  let senderAddress = self.view.getSelectedSenderAccountAddress()
  let addresses = @[senderAddress]
  let chainIds = self.controller.getChainIds()
  self.collectiblesController.setFilterAddressesAndChains(addresses, chainIds)
  self.nestedCollectiblesModel.setAddress(senderAddress)

method notifySelectedSenderAccountChanged*(self: Module) =
  self.updateCollectiblesFilter()

method getCollectiblesModel*(self: Module): collectibles.Model =
  return self.collectiblesController.getModel()

method getNestedCollectiblesModel*(self: Module): nested_collectibles.Model =
  return self.nestedCollectiblesModel

proc getNetworkColor(self: Module, shortName: string): string =
  let networks = self.controller.getCurrentNetworks()
  for network in networks:
    if cmpIgnoreCase(network.shortName, shortName) == 0:
      return network.chainColor
  return ""

proc getLayer1NetworkChainId*(self: Module): int =
  let networks = self.controller.getCurrentNetworks()
  for network in networks:
    if network.layer == NETWORK_LAYER_1:
      return network.chainId
  return 0

method getNetworkChainId*(self: Module, shortName: string): int =
  let networks = self.controller.getCurrentNetworks()
  for network in networks:
    if cmpIgnoreCase(network.shortName, shortName) == 0:
      return network.chainId
  return 0

method splitAndFormatAddressPrefix*(self: Module, text : string, updateInStore: bool): string {.slot.} =
  var tempPreferredChains: seq[int]
  var chainFound = false
  var editedText = ""

  for word in plainText(text).split(':'):
    if word.startsWith("0x"):
      editedText = editedText & word
    else:
      let chainColor = self.getNetworkColor(word)
      if not chainColor.isEmptyOrWhitespace():
        chainFound = true
        tempPreferredChains.add(self.getNetworkChainId(word))
        editedText = editedText & "<span style='color: " & chainColor & "'>" & word & "</span>" & ":"

  if updateInStore:
    if not chainFound:
      self.view.updateRoutePreferredChains($self.getLayer1NetworkChainId())
    else:
      self.view.updateRoutePreferredChains(tempPreferredChains.join(":"))

  editedText = "<a><p>" & editedText & "</a></p>"
  return editedText

method transactionSendingComplete*(self: Module, txHash: string, success: bool) =
  self.view.sendtransactionSendingCompleteSignal(txHash, success)
