import NimQml, Tables, json, strutils, strformat

import message_item, message_reaction_item, message_transaction_parameters_item

import ../../../app_service/service/message/dto/message# as message_dto

type
  ModelRole {.pure.} = enum
    Id = UserRole + 1
    PrevMsgTimestamp
    PrevMsgIndex
    NextMsgIndex
    CommunityId
    ResponseToMessageWithId
    SenderId
    SenderDisplayName
    SenderOptionalName
    SenderIcon
    AmISender
    SenderIsAdded
    Seen
    OutgoingStatus
    MessageText
    UnparsedText
    MessageImage
    MessageContainsMentions # Actually we don't need to exposed this to qml since we only used it as an improved way to
                            # check whether we need to update mentioned contact name or not.
    Timestamp
    ContentType
    MessageType
    Sticker
    StickerPack
    GapFrom
    GapTo
    Pinned
    PinnedBy
    Reactions
    EditMode
    IsEdited
    Links
    TransactionParameters
    MentionedUsersPks
    SenderTrustStatus
    SenderEnsVerified
    MessageAttachments
    ResendError
    Mentioned
    QuotedMessageFrom
    QuotedMessageText
    QuotedMessageParsedText
    QuotedMessageContentType
    QuotedMessageDeleted
    QuotedMessageFromIterator

QtObject:
  type
    Model* = ref object of QAbstractListModel
      items*: seq[Item]
      allKeys: seq[int]
      firstUnseenMessageId: string

  proc delete(self: Model) =
    self.items = @[]
    self.QAbstractListModel.delete

  proc setup(self: Model) =
    self.QAbstractListModel.setup

  proc newModel*(): Model =
    new(result, delete)
    result.setup

    # This is just a clean way to have all roles in a seq, without typing long seq manualy, and this way we're sure that
    # all new added roles will be included here as well.
    for i in result.roleNames().keys:
      result.allKeys.add(i)

    result.firstUnseenMessageId = ""

  proc `$`*(self: Model): string =
    result = "MessageModel:\n"
    for i in 0 ..< self.items.len:
      result &= fmt"""
      [{i}]:({$self.items[i]})
      """

  proc resetNewMessagesMarker*(self: Model)
  
  proc countChanged(self: Model) {.signal.}
  proc getCount(self: Model): int {.slot.} =
    self.items.len
  QtProperty[int]count:
    read = getCount
    notify = countChanged

  method rowCount*(self: Model, index: QModelIndex = nil): int =
    return self.items.len

  method roleNames(self: Model): Table[int, string] =
    {
      ModelRole.Id.int:"id",
      ModelRole.PrevMsgTimestamp.int: "prevMsgTimestamp",
      ModelRole.PrevMsgIndex.int:"prevMsgIndex",
      ModelRole.NextMsgIndex.int:"nextMsgIndex",
      ModelRole.CommunityId.int:"communityId",
      ModelRole.ResponseToMessageWithId.int:"responseToMessageWithId",
      ModelRole.SenderId.int:"senderId",
      ModelRole.SenderDisplayName.int:"senderDisplayName",
      ModelRole.SenderOptionalName.int:"senderOptionalName",
      ModelRole.SenderIcon.int:"senderIcon",
      ModelRole.AmISender.int:"amISender",
      ModelRole.SenderIsAdded.int:"senderIsAdded",
      ModelRole.Seen.int:"seen",
      ModelRole.OutgoingStatus.int:"outgoingStatus",
      ModelRole.ResendError.int:"resendError",
      ModelRole.Mentioned.int:"mentioned",
      ModelRole.MessageText.int:"messageText",
      ModelRole.UnparsedText.int:"unparsedText",
      ModelRole.MessageImage.int:"messageImage",
      ModelRole.MessageContainsMentions.int:"messageContainsMentions",
      ModelRole.Timestamp.int:"timestamp",
      ModelRole.ContentType.int:"contentType",
      ModelRole.MessageType.int:"messageType",
      ModelRole.Sticker.int:"sticker",
      ModelRole.StickerPack.int:"stickerPack",
      ModelRole.GapFrom.int:"gapFrom",
      ModelRole.GapTo.int:"gapTo",
      ModelRole.Pinned.int:"pinned",
      ModelRole.PinnedBy.int:"pinnedBy",
      ModelRole.Reactions.int:"reactions",
      ModelRole.EditMode.int: "editMode",
      ModelRole.IsEdited.int: "isEdited",
      ModelRole.Links.int: "links",
      ModelRole.TransactionParameters.int: "transactionParameters",
      ModelRole.MentionedUsersPks.int: "mentionedUsersPks",
      ModelRole.SenderTrustStatus.int: "senderTrustStatus",
      ModelRole.SenderEnsVerified.int: "senderEnsVerified",
      ModelRole.MessageAttachments.int: "messageAttachments",
      ModelRole.QuotedMessageFrom.int: "quotedMessageFrom",
      ModelRole.QuotedMessageFromIterator.int: "quotedMessageFromIterator",
      ModelRole.QuotedMessageText.int: "quotedMessageText",
      ModelRole.QuotedMessageParsedText.int: "quotedMessageParsedText",
      ModelRole.QuotedMessageContentType.int: "quotedMessageContentType",
      ModelRole.QuotedMessageDeleted.int: "quotedMessageDeleted",
    }.toTable

  method data(self: Model, index: QModelIndex, role: int): QVariant =
    if (not index.isValid):
      return

    if (index.row < 0 or index.row >= self.items.len):
      return

    let item = self.items[index.row]
    let enumRole = role.ModelRole

    case enumRole:
    of ModelRole.Id:
      result = newQVariant(item.id)
    of PrevMsgTimestamp:
      if (index.row + 1 < self.items.len):
        let prevItem = self.items[index.row + 1]
        result = newQVariant(prevItem.timestamp)
      else:
        result = newQVariant(0)
    of ModelRole.PrevMsgIndex:
      result = newQVariant(index.row + 1)
    of ModelRole.NextMsgIndex:
      result = newQVariant(index.row - 1)
    of ModelRole.CommunityId:
      result = newQVariant(item.communityId)
    of ModelRole.ResponseToMessageWithId:
      result = newQVariant(item.responseToMessageWithId)
    of ModelRole.SenderId:
      result = newQVariant(item.senderId)
    of ModelRole.SenderDisplayName:
      result = newQVariant(item.senderDisplayName)
    of ModelRole.SenderTrustStatus:
      result = newQVariant(item.senderTrustStatus.int)
    of ModelRole.SenderOptionalName:
      result = newQVariant(item.senderOptionalName)
    of ModelRole.SenderIcon:
      result = newQVariant(item.senderIcon)
    of ModelRole.AmISender:
      result = newQVariant(item.amISender)
    of ModelRole.SenderIsAdded:
      result = newQVariant(item.senderIsAdded)
    of ModelRole.Seen:
      result = newQVariant(item.seen)
    of ModelRole.OutgoingStatus:
      result = newQVariant(item.outgoingStatus)
    of ModelRole.ResendError:
      result = newQVariant(item.resendError)
    of ModelRole.Mentioned:
      result = newQVariant(item.mentioned)
    of ModelRole.QuotedMessageFrom:
      result = newQVariant(item.quotedMessageFrom)
    of ModelRole.QuotedMessageFromIterator:
      result = newQVariant(item.quotedMessageFromIterator)
    of ModelRole.QuotedMessageText:
      result = newQVariant(item.quotedMessageText)
    of ModelRole.QuotedMessageParsedText:
      result = newQVariant(item.quotedMessageParsedText)
    of ModelRole.QuotedMessageContentType:
      result = newQVariant(item.quotedMessageContentType)
    of ModelRole.QuotedMessageDeleted:
      result = newQVariant(item.quotedMessageDeleted)
    of ModelRole.MessageText:
      result = newQVariant(item.messageText)
    of ModelRole.UnparsedText:
      result = newQVariant(item.unparsedText)
    of ModelRole.MessageImage:
      result = newQVariant(item.messageImage)
    of ModelRole.MessageContainsMentions:
      result = newQVariant(item.messageContainsMentions)
    of ModelRole.Timestamp:
      result = newQVariant(item.timestamp)
    of ModelRole.ContentType:
      result = newQVariant(item.contentType.int)
    of ModelRole.MessageType:
      result = newQVariant(item.messageType)
    of ModelRole.Sticker:
      result = newQVariant(item.sticker)
    of ModelRole.StickerPack:
      result = newQVariant(item.stickerPack)
    of ModelRole.GapFrom:
      result = newQVariant(item.gapFrom)
    of ModelRole.GapTo:
      result = newQVariant(item.gapTo)
    of ModelRole.Pinned:
      result = newQVariant(item.pinned)
    of ModelRole.PinnedBy:
      result = newQVariant(item.pinnedBy)
    of ModelRole.Reactions:
      result = newQVariant(item.reactionsModel)
    of ModelRole.EditMode:
      result = newQVariant(item.editMode)
    of ModelRole.IsEdited:
      result = newQVariant(item.isEdited)
    of ModelRole.Links:
      result = newQVariant(item.links.join(" "))
    of ModelRole.TransactionParameters:
      result = newQVariant($(%*{
        "id": item.transactionParameters.id,
        "fromAddress": item.transactionParameters.fromAddress,
        "address": item.transactionParameters.address,
        "contract": item.transactionParameters.contract,
        "value": item.transactionParameters.value,
        "transactionHash": item.transactionParameters.transactionHash,
        "commandState": item.transactionParameters.commandState,
        "signature": item.transactionParameters.signature
      }))
    of ModelRole.MentionedUsersPks:
      result = newQVariant(item.mentionedUsersPks.join(" "))
    of ModelRole.SenderEnsVerified:
      result = newQVariant(item.senderEnsVerified)
    of ModelRole.MessageAttachments:
      result = newQVariant(item.messageAttachments.join(" "))

  proc updateItemAtIndex(self: Model, index: int) =
    let ind = self.createIndex(index, 0, nil)
    self.dataChanged(ind, ind, self.allKeys)

  proc findIndexForMessageId*(self: Model, messageId: string): int =
    result = -1
    if messageId.len == 0:
      return
    for i in 0 ..< self.items.len:
      if(self.items[i].id == messageId):
        result = i
        return

  proc findIdsOfTheMessagesWhichRespondedToMessageWithId*(self: Model, messageId: string): seq[string] =
    for i in 0 ..< self.items.len:
      if(self.items[i].responseToMessageWithId == messageId):
        result.add(self.items[i].id)

  proc findIndexBasedOnClockToInsertTo(self: Model, clock: int64, id: string): int =
    for i in 0 ..< self.items.len:
      if clock > self.items[i].clock:
        return i
      elif clock == self.items[i].clock: # break ties by message id
        if id > self.items[i].id:
          return i
    return self.items.len

  proc insertItemBasedOnClock*(self: Model, item: Item) =
    if(self.findIndexForMessageId(item.id) != -1):
      return

    let parentModelIndex = newQModelIndex()
    defer: parentModelIndex.delete

    let position = self.findIndexBasedOnClockToInsertTo(item.clock, item.id)

    self.beginInsertRows(parentModelIndex, position, position)
    self.items.insert(item, position)
    self.endInsertRows()

    if position > 0:
      self.updateItemAtIndex(position - 1)
    if position + 1 < self.items.len:
      self.updateItemAtIndex(position + 1)
    self.countChanged()

  proc insertItemsBasedOnClock*(self: Model, items: seq[Item]) =
    for item in items:
      self.insertItemBasedOnClock(item)

  # Replied message was deleted
  proc updateMessagesWithResponseTo(self: Model, messageId: string) =
    for i in 0 ..< self.items.len:
      if(self.items[i].responseToMessageWithId == messageId):
        let ind = self.createIndex(i, 0, nil)
        var item = self.items[i]
        item.quotedMessageText = ""
        item.quotedMessageParsedText = ""
        item.quotedMessageFrom = ""
        item.quotedMessageDeleted = true
        self.dataChanged(ind, ind, @[
          ModelRole.QuotedMessageFrom.int,
          ModelRole.QuotedMessageParsedText.int,
          ModelRole.QuotedMessageContentType.int,
          ModelRole.QuotedMessageDeleted.int,
        ])

  proc removeItem*(self: Model, messageId: string) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    let parentModelIndex = newQModelIndex()
    defer: parentModelIndex.delete

    self.beginRemoveRows(parentModelIndex, ind, ind)
    self.items.delete(ind)
    self.endRemoveRows()

    self.resetNewMessagesMarker()

    if ind > 0 and ind < self.items.len:
      self.updateItemAtIndex(ind - 1)
    if ind + 1 < self.items.len:
      self.updateItemAtIndex(ind + 1)

    self.countChanged()
    self.updateMessagesWithResponseTo(messageId)

  proc getLastItemFrom*(self: Model, pubkey: string): Item =
    # last item == first time since we process messages in reverse order
    for i in 0 ..< self.items.len:
      if self.items[i].senderId == pubkey:
        return self.items[i]


  proc getItemWithMessageId*(self: Model, messageId: string): Item =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    return self.items[ind]

  proc setOutgoingStatus(self: Model, messageId: string, status: string) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return
    self.items[ind].outgoingStatus = status
    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.OutgoingStatus.int])

  proc itemSending*(self: Model, messageId: string) =
    self.setOutgoingStatus(messageId, PARSED_TEXT_OUTGOING_STATUS_SENDING)

  proc itemSent*(self: Model, messageId: string) =
    self.setOutgoingStatus(messageId, PARSED_TEXT_OUTGOING_STATUS_SENT)

  proc itemDelivered*(self: Model, messageId: string) =
    self.setOutgoingStatus(messageId, PARSED_TEXT_OUTGOING_STATUS_DELIVERED)

  proc itemExpired*(self: Model, messageId: string) =
    self.setOutgoingStatus(messageId, PARSED_TEXT_OUTGOING_STATUS_EXPIRED)

  proc itemFailedResending*(self: Model, messageId: string, error: string) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return
    self.items[ind].resendError = error
    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.ResendError.int])

  proc addReaction*(self: Model, messageId: string, emojiId: EmojiId, didIReactWithThisEmoji: bool,
    userPublicKey: string, userDisplayName: string, reactionId: string) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    self.items[ind].addReaction(emojiId, didIReactWithThisEmoji, userPublicKey, userDisplayName, reactionId)

    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.Reactions.int])

  proc removeReaction*(self: Model, messageId: string, emojiId: EmojiId, reactionId: string, didIRemoveThisReaction: bool) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    self.items[ind].removeReaction(emojiId, reactionId, didIRemoveThisReaction)

    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.Reactions.int])

  proc pinUnpinMessage*(self: Model, messageId: string, pin: bool, pinnedBy: string) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    self.items[ind].pinned = pin
    self.items[ind].pinnedBy = pinnedBy

    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.Pinned.int, ModelRole.PinnedBy.int])

  proc getMessageByIdAsJson*(self: Model, messageId: string): JsonNode =
    for it in self.items:
      if(it.id == messageId):
        return it.toJsonNode()

  proc getMessageByIndexAsJson*(self: Model, index: int): JsonNode =
    if(index < 0 or index >= self.items.len):
      return
    self.items[index].toJsonNode()

  iterator modelContactUpdateIterator*(self: Model, contactId: string): Item =
    for i in 0 ..< self.items.len:
      yield self.items[i]

      var roles: seq[int]
      if(self.items[i].senderId == contactId):
        roles = @[ModelRole.SenderDisplayName.int,
          ModelRole.SenderOptionalName.int,
          ModelRole.SenderIcon.int,
          ModelRole.SenderIsAdded.int,
          ModelRole.SenderTrustStatus.int,
          ModelRole.SenderEnsVerified.int]
      if(self.items[i].pinnedBy == contactId):
        roles.add(ModelRole.PinnedBy.int)
      if(self.items[i].messageContainsMentions):
        roles.add(@[ModelRole.MessageText.int, ModelRole.UnparsedText.int, ModelRole.MessageContainsMentions.int])

      if (self.items[i].quotedMessageFrom == contactId):
        # If there is a quoted message whom the author changed, increase the iterator to force
        # the view to re-fetch the author's details
        self.items[i].quotedMessageFromIterator = self.items[i].quotedMessageFromIterator + 1
        roles.add(ModelRole.QuotedMessageFromIterator.int)

      if(roles.len > 0):
        let index = self.createIndex(i, 0, nil)
        self.dataChanged(index, index, roles)

  proc setEditModeOn*(self: Model, messageId: string)  =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    self.items[ind].editMode = true

    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.EditMode.int])

  proc setEditModeOff*(self: Model, messageId: string)  =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    self.items[ind].editMode = false

    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[ModelRole.EditMode.int])

  proc updateEditedMsg*(
      self: Model,
      messageId: string,
      updatedMsg: string,
      updatedRawMsg: string,
      contentType: int,
      messageContainsMentions: bool,
      links: seq[string],
      mentionedUsersPks: seq[string]
      ) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return

    self.items[ind].messageText = updatedMsg
    self.items[ind].messageContainsMentions = messageContainsMentions
    self.items[ind].isEdited = true
    self.items[ind].links = links
    self.items[ind].mentionedUsersPks = mentionedUsersPks

    let index = self.createIndex(ind, 0, nil)
    self.dataChanged(index, index, @[
      ModelRole.MessageText.int,
      ModelRole.UnparsedText.int,
      ModelRole.MessageContainsMentions.int,
      ModelRole.IsEdited.int,
      ModelRole.Links.int,
      ModelRole.MentionedUsersPks.int
      ])

    # Update replied to messages if there are
    for i in 0 ..< self.items.len:
      if(self.items[i].responseToMessageWithId == messageId):
        self.items[i].quotedMessageParsedText = updatedMsg
        self.items[i].quotedMessageText = updatedRawMsg
        self.items[i].quotedMessageContentType = contentType
        let index = self.createIndex(i, 0, nil)
        self.dataChanged(index, index, @[
          ModelRole.QuotedMessageText.int,
          ModelRole.QuotedMessageParsedText.int,
          ModelRole.QuotedMessageContentType.int,
        ])  

  proc clear*(self: Model) =
    self.beginResetModel()
    self.items = @[]
    self.endResetModel()
    self.countChanged()

  proc refreshItemWithId*(self: Model, messageId: string) =
    let ind = self.findIndexForMessageId(messageId)
    if(ind == -1):
      return
    self.updateItemAtIndex(ind)

  proc setFirstUnseenMessageId*(self: Model, messageId: string) =
    self.firstUnseenMessageId = messageId

  proc getFirstUnseenMessageId*(self: Model): string =
    self.firstUnseenMessageId

  proc newMessagesMarkerIndex*(self: Model): int =
    result = -1
    for i in countdown(self.items.len - 1, 0):
      if self.items[i].contentType == ContentType.NewMessagesMarker:
        return i

  proc removeNewMessagesMarker(self: Model) =
    let index = self.newMessagesMarkerIndex()
    if index == -1:
      return

    let parentModelIndex = newQModelIndex()
    defer: parentModelIndex.delete

    self.beginRemoveRows(parentModelIndex, index, index)
    self.items.delete(index)
    self.endRemoveRows()
    self.countChanged()

  proc resetNewMessagesMarker*(self: Model) =
    self.removeNewMessagesMarker()
    let messageId = self.firstUnseenMessageId
    if messageId == "":
      return

    let index = self.findIndexForMessageId(messageId)
    if index == -1:
      return

    let position = index + 1

    let parentModelIndex = newQModelIndex()
    defer: parentModelIndex.delete

    self.beginInsertRows(parentModelIndex, position, position)
    self.items.insert(initNewMessagesMarkerItem(self.items[index].clock, self.items[index].timestamp), position)
    self.endInsertRows()
    self.countChanged()

  proc getNewMessagesCount*(self: Model): int {.slot.} =
    max(0, self.newMessagesMarkerIndex())
  QtProperty[int]newMessagesCount:
    read = getNewMessagesCount
    notify = countChanged

  proc markAllAsSeen*(self: Model) =
    for i in 0 ..< self.items.len:
      let item = self.items[i]
      if not item.seen:
        item.seen = true
        let index = self.createIndex(i, 0, nil)
        self.dataChanged(index, index, @[ModelRole.Seen.int])
