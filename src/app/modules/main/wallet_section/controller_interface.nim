type
  AccessInterface* {.pure inheritable.} = ref object of RootObj
  ## Abstract class for any input/interaction with this module.

method delete*(self: AccessInterface) {.base.} =
  raise newException(ValueError, "No implementation available")

method init*(self: AccessInterface) {.base.} =
  raise newException(ValueError, "No implementation available")

method getCurrency*(self: AccessInterface): string {.base.} =
  raise newException(ValueError, "No implementation available")

method getSigningPhrase*(self: AccessInterface): string {.base.} =
  raise newException(ValueError, "No implementation available")

method isMnemonicBackedUp*(self: AccessInterface): bool {.base.} =
  raise newException(ValueError, "No implementation available")

method getCurrencyBalance*(self: AccessInterface): float64 {.base.} =
  raise newException(ValueError, "No implementation available")

method updateCurrency*(self: AccessInterface, currency: string) {.base.} =
  raise newException(ValueError, "No implementation available")

method isEIP1559Enabled*(self: AccessInterface): bool {.base.} =
  raise newException(ValueError, "No implementation available")

method getIndex*(self: AccessInterface, address: string): int {.base.} =
  raise newException(ValueError, "No implementation available")

type
  ## Abstract class (concept) which must be implemented by object/s used in this
  ## module.
  DelegateInterface* = concept c
