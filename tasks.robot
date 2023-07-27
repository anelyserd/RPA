*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP    # download the csv file
Library             RPA.Excel.Files    # not used
Library             RPA.Tables
Library             RPA.Desktop
Library             OperatingSystem
Library             RPA.PDF
Library             RPA.Desktop.Windows
Library             XML
Library             RPA.FileSystem    # Remove screenshot file
Library             RPA.Archive    # ZIP files
Library             RPA.Dialogs    # Robot Assistant adds UI to the Robot


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}    ${CURDIR}${/}temp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}=    Get orders    # Return the order in csv format
    Open the robot order website    # Will open the robot order website

    FOR    ${row}    IN    @{orders}
        Wait Until Keyword Succeeds    5x    1s    Close the annoying modal
        Run Keyword And Continue On Failure    Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    1s    Preview the robot
        Wait Until Keyword Succeeds    10x    1s    Submit the order

        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Log    ${screenshot}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    5x    2s    Go to order another robot
    END
    Create a ZIP file of the receipts
    Request worker name

Order one Robot testing Keyword
    Open the robot order website
    # ${orders}= Get Orders
    ${excel_file_path}=    Request file URL from user
    Wait Until Keyword Succeeds    5x    1s    Close the annoying modal
    # Run Keyword And Continue On Failure    Fill the form    ${row}
    Wait Until Element Is Enabled    //*[@id="head"]
    Select From List By Value    id:head    3

    Wait Until Element Is Enabled    //*[@id="root"]/div/div[1]/div/div[1]/form/div[2]/div
    Click Element    id:id-body-1    # Click on body

    Wait Until Element Is Enabled    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    4

    Wait Until Element Is Enabled    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input    Adress123

    Wait Until Keyword Succeeds    10x    1s    Preview the robot
    Wait Until Keyword Succeeds    10x    1s    Submit the order

    ${receipt_pdf}=    Store the receipt as a PDF file    order_test
    ${robot_screnshoot}=    Take a screenshot of the robot    screenshot_test
    Embed the robot screenshot to the receipt PDF file    ${robot_screnshoot}    ${receipt_pdf}
    Create a ZIP file of the receipts


*** Keywords ***
Request worker name
    Add heading    Please enter your name
    Add text input    name=username
    ${result}=    Run dialog
    Add heading    Hello ${result.username}, your order were placed.
    Run dialog

Request file URL from user
    Add heading    Order file URL
    Add text    Provide the complete URL to the CSV file with the file orders
    Add text input    url    label=URL for order file
    ${input}=    Run dialog
    RETURN    ${input.url}

Open the robot order website    # 8: Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    # Open the browser
    # Sleep    2s

Get Orders    # 9: Dowload and return as table the order file
    ${link_file}=    Request file URL from user
    Download    ${link_file}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    # ${table}=    Collect Excel link from the user
    RETURN    ${table}

Collect Excel link from the user
    Add heading    I am your RoboCorp Order Genie
    # Add text input    myname    label=What is thy name, oh sire?    placeholder=Give me some input here
    ${result}=    Run dialog
    RETURN    ${result}

Close the annoying modal    # 11: get rid of the modal that pops up
    Wait And Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form    # 12: Filling the form with the data from excel
    [Arguments]    ${table}
    Wait Until Element Is Visible    //*[@id="head"]
    Wait Until Element Is Enabled    //*[@id="head"]
    Select From List By Value    id:head    ${table}[Head]

    Wait Until Element Is Enabled    //*[@id="root"]/div/div[1]/div/div[1]/form/div[2]/div
    Click Element    id:id-body-${table}[Body]    # Click on body

    Wait Until Element Is Enabled    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${table}[Legs]

    Wait Until Element Is Enabled    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input    ${table}[Address]

Preview the robot
    Click Element    id:preview    # 13: Preview the robot
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order    # 14 submit the order
    Click Element    id:order
    Wait Until Element Is Visible    //*[@id="receipt"]

Go to order another robot
    Click Element    id:order-another

Store the receipt as a PDF file    # 15:store the receipt as a PDF file
    [Arguments]    ${pdf_name}
    ${pdf_receipt_html}=    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${pdf_receipt_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${pdf_name}.pdf
    RETURN    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${pdf_name}.pdf

Take a screenshot of the robot    # 16: Take a screen shot of the robot image
    [Arguments]    ${order_number}
    RPA.Browser.Selenium.Screenshot
    ...    id:robot-preview-image
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${order_number}.png
    RETURN    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file    # 17: Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${robot_screenshot}    ${receipt_pdf}    # File paths of both files to be merged
    Open Pdf    ${receipt_pdf}    # Open the receipt pdf
    @{myfiles}=    Create List    ${robot_screenshot}:x=0,y=0    # creating a list
    Add Files To PDF    ${myfiles}    ${receipt_pdf}    append=True
    Close Pdf    ${receipt_pdf}
    RPA.FileSystem.Remove File    ${robot_screenshot}

Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Create Directory    ${OUTPUT_DIR}

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}
    Cleanup temporary PDF directory

Cleanup temporary PDF directory
    RPA.FileSystem.Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True

#####Rest#####
# Wait Until Keyword Succeeds    3x    1s    Close the annoying modal
# Wait Until Keyword Succeeds    10x    2s    Preview the robot
# Wait Until Keyword Succeeds    10x    2s    Submit The Order
# Click Element    css:#head > option:nth-child(3)    #Click head
# Select From List By Value    id:head    3
# Click Element    id:id-body-3    #Click on body
# Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    3    #Input Legs
# Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input    aaaa    #adress
