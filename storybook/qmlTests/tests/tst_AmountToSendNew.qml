import QtQuick 2.15
import QtQuick.Controls 2.15

import QtTest 1.15

import shared.popups.send.views 1.0

Item {
    id: root

    Component {
        id: componentUnderTest

        AmountToSendNew {
            decimalPoint: "."
        }
    }

    property AmountToSendNew amountToSend

    TestCase {
        name: "AmountToSendNew"
        when: windowShown

        function type(key, times = 1) {
            for (let i = 0; i < times; i++) {
                keyPress(key)
                keyRelease(key)
            }
        }

        function init() {
            amountToSend = createTemporaryObject(componentUnderTest, root)
        }

        function test_empty() {
            compare(amountToSend.valid, false)
            compare(amountToSend.empty, true)
            compare(amountToSend.amount, "0")
            compare(amountToSend.fiatMode, false)
        }

        function test_settingValueInCryptoMode() {
            const textField = findChild(amountToSend, "amountToSend_textField")

            amountToSend.multiplierIndex = 3
            amountToSend.setValue("2.5")

            compare(textField.text, "2.5")
            compare(amountToSend.amount, "2500")
            compare(amountToSend.valid, true)

            amountToSend.setValue("2.12345678")

            compare(textField.text, "2.123")
            compare(amountToSend.amount, "2123")
            compare(amountToSend.valid, true)

            amountToSend.setValue("2.1239")

            compare(textField.text, "2.124")
            compare(amountToSend.amount, "2124")
            compare(amountToSend.valid, true)

            amountToSend.setValue(".1239")

            compare(textField.text, "0.124")
            compare(amountToSend.amount, "124")
            compare(amountToSend.valid, true)

            amountToSend.setValue("1.0000")

            compare(textField.text, "1")
            compare(amountToSend.amount, "1000")
            compare(amountToSend.valid, true)

            amountToSend.setValue("0.0000")

            compare(textField.text, "0")
            compare(amountToSend.amount, "0")
            compare(amountToSend.valid, true)

            amountToSend.setValue("x")

            compare(textField.text, "NaN")
            compare(amountToSend.amount, "0")
            compare(amountToSend.valid, false)

            // exceeding maxium allowed integral part
            amountToSend.setValue("1234567890000")
            compare(textField.text, "1234567890000")
            compare(amountToSend.amount, "0")
            compare(amountToSend.valid, false)
        }

        function test_settingValueInFiatMode() {
            const textField = findChild(amountToSend, "amountToSend_textField")
            const mouseArea = findChild(amountToSend, "amountToSend_mouseArea")

            amountToSend.price = 0.5
            amountToSend.multiplierIndex = 3

            mouseClick(mouseArea)
            compare(amountToSend.fiatMode, true)

            amountToSend.setValue("2.5")

            compare(textField.text, "2.50")
            compare(amountToSend.amount, "5000")
            compare(amountToSend.valid, true)

            amountToSend.setValue("2.12345678")

            compare(textField.text, "2.12")
            compare(amountToSend.amount, "4240")
            compare(amountToSend.valid, true)

            amountToSend.setValue("2.129")

            compare(textField.text, "2.13")
            compare(amountToSend.amount, "4260")
            compare(amountToSend.valid, true)

            // exceeding maxium allowed integral part
            amountToSend.setValue("1234567890000")
            compare(textField.text, "1234567890000.00")
            compare(amountToSend.amount, "0")
            compare(amountToSend.valid, false)
        }

        function test_switchingMode() {
            const textField = findChild(amountToSend, "amountToSend_textField")
            const mouseArea = findChild(amountToSend, "amountToSend_mouseArea")

            amountToSend.price = 0.5
            amountToSend.multiplierIndex = 3

            amountToSend.setValue("10.5")
            compare(amountToSend.amount, "10500")

            mouseClick(mouseArea)
            compare(amountToSend.fiatMode, true)
            compare(textField.text, "5.25")
            compare(amountToSend.amount, "10500")

            mouseClick(mouseArea)
            compare(amountToSend.fiatMode, false)
            compare(textField.text, "10.5")
            compare(amountToSend.amount, "10500")

            mouseClick(mouseArea)
            compare(amountToSend.fiatMode, true)
            amountToSend.price = 0.124
            amountToSend.setValue("1")
            compare(textField.text, "1.00")

            mouseClick(mouseArea)
            compare(amountToSend.fiatMode, false)
            compare(textField.text, "8.065")
            compare(amountToSend.amount, "8065")
        }

        function test_clear() {
            const textField = findChild(amountToSend, "amountToSend_textField")

            amountToSend.setValue("10.5")
            amountToSend.clear()

            compare(amountToSend.amount, "0")
            compare(textField.text, "")
        }
    }
}
