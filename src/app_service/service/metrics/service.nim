import NimQml, json, chronicles, times
include ../../common/json_utils

import backend/response_type
import status_go
import constants
import ./dto

logScope:
  topics = "metrics"

QtObject:
  type MetricsService* = ref object of QObject

  proc delete*(self: MetricsService) =
    self.QObject.delete

  proc newService*(): MetricsService =
    new(result, delete)
    result.QObject.setup

  # for testing, needs to be discussed
  proc addCentralizedMetric*(self: MetricsService) =
    try:
      var metric = CentralizedMetricDto()
      metric.userId = "123456"
      metric.eventName = "desktop-event"
      metric.eventValue = parseJson("""{"action": "section-changed"}""")
      metric.timestamp = now().toTime().toUnix()
      metric.platform = hostOS
      metric.appVersion = APP_VERSION

      let payload = %* {"metric": metric.toJsonNode}
      let response = status_go.addCentralizedMetric($payload)
      let jsonObj = response.parseJson
      if jsonObj.hasKey("error"):
        error "addCentralizedMetric", errorMsg=jsonObj["error"].getStr
    except Exception:
      discard

  proc centralizedMetricsEnabledChaned*(self: MetricsService) {.signal.}
  proc isCentralizedMetricsEnabled*(self: MetricsService): bool {.slot.} =
    try:
      let response = status_go.centralizedMetricsInfo()
      let jsonObj = response.parseJson
      if jsonObj.hasKey("error"):
        error "isCentralizedMetricsEnabled", errorMsg=jsonObj["error"].getStr
        return false
      let metricsInfo = toCentralizedMetricsInfoDto(jsonObj)
      return metricsInfo.enabled
    except Exception:
      return false

  QtProperty[bool] isCentralizedMetricsEnabled:
    read = isCentralizedMetricsEnabled
    notify = centralizedMetricsEnabledChaned

  proc toggleCentralizedMetrics*(self: MetricsService, enabled: bool) {.slot.} =
    try:
      let isEnabled = self.isCentralizedMetricsEnabled()
      if enabled == isEnabled:
        return
      let payload = %* {"enabled": enabled}
      let response = status_go.toggleCentralizedMetrics($payload)
      let jsonObj = response.parseJson
      if jsonObj{"error"}.getStr.len > 0:
        error "toggleCentralizedMetrics", errorMsg=jsonObj["error"].getStr
      else:
        self.centralizedMetricsEnabledChaned()
    except Exception as e:
      error "toggleCentralizedMetrics", exceptionMsg = e.msg
