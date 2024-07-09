import NimQml
import chronicles

import app_service/service/wallet_connect/service as wallet_connect_service
import app_service/service/wallet_account/service as wallet_account_service

logScope:
  topics = "wallet-connect-controller"

QtObject:
  type
    Controller* = ref object of QObject
      service: wallet_connect_service.Service
      walletAccountService: wallet_account_service.Service

  proc delete*(self: Controller) =
    self.QObject.delete

  proc newController*(service: wallet_connect_service.Service, walletAccountService: wallet_account_service.Service): Controller =
    new(result, delete)

    result.service = service
    result.walletAccountService = walletAccountService

    result.QObject.setup

  proc addWalletConnectSession*(self: Controller, session_json: string): bool {.slot.} =
    return self.service.addSession(session_json)

  proc deactivateWalletConnectSession*(self: Controller, topic: string): bool {.slot.} =
    return self.service.deactivateSession(topic)

  proc updateSessionsMarkedAsActive*(self: Controller, activeTopicsJson: string) {.slot.} =
    self.service.updateSessionsMarkedAsActive(activeTopicsJson)

  proc dappsListReceived*(self: Controller, dappsJson: string) {.signal.}

  # Emits signal dappsListReceived with the list of dApps
  proc getDapps*(self: Controller): bool {.slot.} =
    let res = self.service.getDapps()
    if res == "":
      return false
    else:
      self.dappsListReceived(res)
      return true

  proc userAuthenticationResult*(self: Controller, topic: string, id: string, error: bool, password: string, pin: string) {.signal.}

  # Beware, it will fail if an authentication is already in progress
  proc authenticateUser*(self: Controller, topic: string, id: string, address: string): bool {.slot.} =
    let acc = self.walletAccountService.getAccountByAddress(address)
    if acc.keyUid == "":
      return false

    return self.service.authenticateUser(acc.keyUid, proc(password: string, pin: string, success: bool) =
      self.userAuthenticationResult(topic, id, success, password, pin)
    )

  proc signMessageUnsafe*(self: Controller, address: string, password: string, message: string): string {.slot.} =
    return self.service.signMessageUnsafe(address, password, message)

  proc signMessage*(self: Controller, address: string, password: string, message: string): string {.slot.} =
    return self.service.signMessage(address, password, message)

  proc safeSignTypedData*(self: Controller, address: string, password: string, typedDataJson: string, chainId: int, legacy: bool): string {.slot.} =
    return self.service.safeSignTypedData(address, password, typedDataJson, chainId, legacy)

  proc signTransaction*(self: Controller, address: string, chainId: int, password: string, txJson: string): string {.slot.} =
    return self.service.signTransaction(address, chainId, password, txJson)

  proc sendTransaction*(self: Controller, address: string, chainId: int, password: string, txJson: string): string {.slot.} =
    return self.service.sendTransaction(address, chainId, password, txJson)

  proc getEstimatedTimeMinutesInterval(self: Controller, chainId: int, maxFeePerGas: string): int {.slot.} =
    return self.service.getEstimatedTimeMinutesInterval(chainId, maxFeePerGas).int