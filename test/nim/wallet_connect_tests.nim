import unittest

import app/modules/main/wallet_section/poc_wallet_connect/helpers

import app/modules/shared_modules/wallet_connect/helpers

suite "wallet connect":

  test "hexToDec":
    check(hexToDec("0x3") == "3")
    check(hexToDec("f") == "15")

  test "convertFeesInfoToHex":
    const feesInfoJson = "{\"maxFees\":\"24528.282681\",\"maxFeePerGas\":1.168013461,\"maxPriorityFeePerGas\":0.036572351,\"gasPrice\":\"1.168013461\"}"

    check(convertFeesInfoToHex(feesInfoJson) == """{"maxFeePerGas":"0x459E7895","maxPriorityFeePerGas":"0x22E0CBF"}""")

  test "parse deep link url":
    const testUrl = "https://status.app/wc?uri=wc%3Aa4f32854428af0f5b6635fb7a3cb2cfe174eaad63b9d10d52ef1c686f8eab862%402%3Frelay-protocol%3Dirn%26symKey%3D4ccbae2b4c81c26fbf4a6acee9de2771705d467de9a1d24c80240e8be59de6be"

    let (resOk, wcUri) = extractAndCheckUriParameter(testUrl)

    check(resOk)
    check(wcUri == "wc:a4f32854428af0f5b6635fb7a3cb2cfe174eaad63b9d10d52ef1c686f8eab862@2?relay-protocol=irn&symKey=4ccbae2b4c81c26fbf4a6acee9de2771705d467de9a1d24c80240e8be59de6be")

  test "parse another valid deep link url":
    const testUrl = "https://status.app/notwc?uri=lt%3Asomevalue"

    let (resOk, wcUri) = extractAndCheckUriParameter(testUrl)

    check(not resOk)
    check(wcUri == "")

  test "parse a WC no-prefix deeplink":
    const testUrl = "https://status.app/wc?uri=w4%3Atest"

    let (resOk, wcUri) = extractAndCheckUriParameter(testUrl)

    check(not resOk)
    check(wcUri == "")
