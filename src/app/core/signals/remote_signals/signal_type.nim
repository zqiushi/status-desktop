{.used.}

type SignalType* {.pure.} = enum
  Message = "messages.new"
  MessageDelivered = "message.delivered"
  ## Wallet Signals
  Wallet = "wallet"
  WalletSignTransactions = "wallet.sign.transactions"
  WalletSuggestedRoutes = "wallet.suggested.routes"
  NodeReady = "node.ready"
  NodeCrashed = "node.crashed"
  NodeStarted = "node.started"
  NodeStopped = "node.stopped"
  NodeLogin = "node.login"
  EnvelopeSent = "envelope.sent"
  EnvelopeExpired = "envelope.expired"
  MailserverRequestCompleted = "mailserver.request.completed"
  MailserverRequestExpired = "mailserver.request.expired"
  DiscoveryStarted = "discovery.started"
  DiscoveryStopped = "discovery.stopped"
  DiscoverySummary = "discovery.summary"
  SubscriptionsData = "subscriptions.data"
  SubscriptionsError = "subscriptions.error"
  WhisperFilterAdded = "whisper.filter.added"
  CommunityFound = "community.found"
  CuratedCommunitiesUpdated = "curated.communities.update"
  PeerStats = "wakuv2.peerstats"
  Stats = "stats"
  ChroniclesLogs = "chronicles-log"
  HistoryRequestStarted = "history.request.started"
  HistoryRequestCompleted = "history.request.completed"
  HistoryRequestFailed = "history.request.failed"
  HistoryRequestSuccess = "history.request.success"
  MailserverAvailable = "mailserver.available"
  MailserverChanged = "mailserver.changed"
  MailserverNotWorking = "mailserver.not.working"
  HistoryArchivesProtocolEnabled = "community.historyArchivesProtocolEnabled"
  HistoryArchivesProtocolDisabled = "community.historyArchivesProtocolDisabled"
  CreatingHistoryArchives = "community.creatingHistoryArchives"
  HistoryArchivesCreated = "community.historyArchivesCreated"
  NoHistoryArchivesCreated = "community.noHistoryArchivesCreated"
  HistoryArchivesSeeding = "community.historyArchivesSeeding"
  HistoryArchivesUnseeded = "community.historyArchivesUnseeded"
  HistoryArchiveDownloaded = "community.historyArchiveDownloaded"
  DownloadingHistoryArchivesStarted = "community.downloadingHistoryArchivesStarted"
  DownloadingHistoryArchivesFinished = "community.downloadingHistoryArchivesFinished"
  ImportingHistoryArchiveMessages = "community.importingHistoryArchiveMessages"
  UpdateAvailable = "update.available"
  DiscordCategoriesAndChannelsExtracted = "community.discordCategoriesAndChannelsExtracted"
  StatusUpdatesTimedout = "status.updates.timedout"
  DiscordCommunityImportFinished = "community.discordCommunityImportFinished"
  DiscordCommunityImportProgress = "community.discordCommunityImportProgress"
  DiscordCommunityImportCancelled = "community.discordCommunityImportCancelled"
  DiscordCommunityImportCleanedUp = "community.discordCommunityImportCleanedUp"
  DiscordChannelImportFinished = "community.discordChannelImportFinished"
  DiscordChannelImportProgress = "community.discordChannelImportProgress"
  DiscordChannelImportCancelled = "community.discordChannelImportCancelled"
  MemberReevaluationStatus = "community.memberReevaluationStatus"
  WakuFetchingBackupProgress = "waku.fetching.backup.progress"
  WakuBackedUpProfile = "waku.backedup.profile"
  WakuBackedUpSettings = "waku.backedup.settings"
  WakuBackedUpKeypair = "waku.backedup.keypair"
  WakuBackedUpWatchOnlyAccount = "waku.backedup.watch-only-account"
  LocalPairing = "localPairing"
  DBReEncryptionStarted = "db.reEncryption.started"
  DBReEncryptionFinished = "db.reEncryption.finished"
  CommunityTokenTransactionStatusChanged = "communityToken.communityTokenTransactionStatusChanged"
  CommunityTokenAction = "communityToken.communityTokenAction"
  Unknown

proc event*(self:SignalType):string =
  result = "signal:" & $self
