*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Close process


*** Keywords ***
Open the robot order website
    #get url from vault
    ${secret}=    Get Secret    orders

    #Open Browser
    Open Available Browser    ${secret}[url]

Get orders
    #Ask user to input url
    Add heading    Input file source
    Add text input    url
    ...    label=Please provide the URL of the orders CSV file:
    ...    placeholder=Please Enter URL here
    ${result}=    Run dialog
    #Download and read file
    Download    ${result.url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${reciept_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf
    ...    ${reciept_html}
    ...    ${OUTPUT_DIR}${/}receipt${/}reciept${row}.pdf
    ...    overwrite=True
    RETURN    ${OUTPUT_DIR}${/}receipt${/}reciept${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}picture${/}robot${row}.png
    RETURN    ${OUTPUT_DIR}${/}picture${/}robot${row}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${file}=    Create List    ${pdf}    ${screenshot}
    Add Files To PDF    ${file}    ${pdf}
    Close Pdf

Go to order another robot
    Wait Until Keyword Succeeds    10x    0.5 sec    Click Button    Order another robot

Create a ZIP file of the receipts
    ${zip_file}=    Set Variable    ${OUTPUT_DIR}/Receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipt
    ...    ${zip_file}

Close process
    Close Browser
