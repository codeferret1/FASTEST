

Feature: Find a window
    As a developer
    So as to easily find windows on screen
    I want to able to select windows by name or attributes

    Scenario: Find existing window by title
        Given I have "notepad.exe" open
        When  I search for window named "notepad"
        Then  I should have a window whose class name is "Notepad"
        And   I should have a window whose process is "notepad.exe"

