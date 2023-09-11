from gui.objects_map.main_names import statusDesktop_mainWindow

mainWindow_ProfileLayout = {"container": statusDesktop_mainWindow, "type": "ProfileLayout", "unnamed": 1, "visible": True}
mainWindow_StatusSectionLayout_ContentItem = {"container": mainWindow_ProfileLayout, "objectName": "StatusSectionLayout", "type": "ContentItem", "visible": True}

# Left Panel
mainWindow_LeftTabView = {"container": mainWindow_StatusSectionLayout_ContentItem, "type": "LeftTabView", "unnamed": 1, "visible": True}
mainWindow_Settings_StatusNavigationPanelHeadline = {"container": mainWindow_LeftTabView, "type": "StatusNavigationPanelHeadline", "unnamed": 1, "visible": True}
mainWindow_scrollView_StatusScrollView = {"container": mainWindow_LeftTabView, "id": "scrollView", "type": "StatusScrollView", "unnamed": 1, "visible": True}
scrollView_AppMenuItem_StatusNavigationListItem = {"container": mainWindow_scrollView_StatusScrollView, "type": "StatusNavigationListItem", "visible": True}

# Communities View
mainWindow_CommunitiesView = {"container": statusDesktop_mainWindow, "type": "CommunitiesView", "unnamed": 1, "visible": True}
mainWindow_settingsContentBaseScrollView_StatusScrollView = {"container": mainWindow_CommunitiesView, "objectName": "settingsContentBaseScrollView", "type": "StatusScrollView", "visible": True}
settingsContentBaseScrollView_listItem_StatusListItem = {"container": mainWindow_settingsContentBaseScrollView_StatusScrollView, "id": "listItem", "type": "StatusListItem", "unnamed": 1, "visible": True}
# Templates to generate Real Name in test
settings_iconOrImage_StatusSmartIdenticon = {"id": "iconOrImage", "type": "StatusSmartIdenticon", "unnamed": 1, "visible": True}
settings_Name_StatusTextWithLoadingState = {"type": "StatusTextWithLoadingState", "unnamed": 1, "visible": True}
settings_statusListItemSubTitle = {"objectName": "statusListItemSubTitle", "type": "StatusTextWithLoadingState", "visible": True}
settings_member_StatusTextWithLoadingState = {"text": "1 member", "type": "StatusTextWithLoadingState", "unnamed": 1, "visible": True}
settings_StatusFlatButton = {"type": "StatusFlatButton", "unnamed": 1, "visible": True}

# Messaging View
mainWindow_MessagingView = {"container": statusDesktop_mainWindow, "type": "MessagingView", "unnamed": 1, "visible": True}
contactsListItem_btn_StatusContactRequestsIndicatorListItem = {"container": mainWindow_MessagingView, "objectName": "MessagingView_ContactsListItem_btn", "type": "StatusContactRequestsIndicatorListItem", "visible": True}

# Contacts View
mainWindow_ContactsView = {"container": statusDesktop_mainWindow, "type": "ContactsView", "unnamed": 1, "visible": True}
mainWindow_Send_contact_request_to_chat_key_StatusButton = {"checkable": False, "container": mainWindow_ContactsView, "objectName": "ContactsView_ContactRequest_Button", "type": "StatusButton", "visible": True}
contactsTabBar_Pending_Requests_StatusTabButton = {"checkable": True, "container": mainWindow_ContactsView, "objectName": "ContactsView_PendingRequest_Button", "type": "StatusTabButton", "visible": True}
settingsContentBaseScrollView_ContactListPanel = {"container": mainWindow_ContactsView, "objectName": "ContactListPanel_ListView", "type": "StatusListView", "visible": True}
