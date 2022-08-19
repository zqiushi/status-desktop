#******************************************************************************
# Status.im
#*****************************************************************************/
#/**
# * \file    test.feature
# *
# * \test    Status Desktop - Community Chat Flows
# * \date    July 2022
# **
# *****************************************************************************/

Feature: Status Desktop community messages

    As a user I want to send messages and interact with channels in a community


    Background:
        Given A first time user lands on the status desktop and generates new key
        When user signs up with username tester123 and password TesTEr16843/!@00
        Then the user lands on the signed in app
        When the user opens the community portal section
        Then the user lands on the community portal section
        When the user creates a community named test_community, with description Community description, intro community intro and outro commmunity outro
        Then the user lands on the community named test_community

    Scenario: User sends a test image
        When the user sends a test image in the current channel
        Then the test image is displayed in the last message

    Scenario: User sends a test image with a message
        When the user sends a test image in the current channel with message Mesage with an image
        Then the test image is displayed just before the last message
        And the message Mesage with an image is displayed in the last message

    Scenario: User sends multiple test images with a message
        When the user sends multiple test images in the current channel with message Mesage with an image again
        Then the test images are displayed just before the last message
        And the message Mesage with an image again is displayed in the last message
