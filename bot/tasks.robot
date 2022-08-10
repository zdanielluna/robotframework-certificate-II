* Settings *
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the Screenshot of the Ordered Bot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           RPA.FileSystem

* Variables *
${webpage}        https://robotsparebinindustries.com/#/robot-order
${csv_url}        https://robotsparebinindustries.com/orders.csv

${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output
${ss_folder}      ${CURDIR}${/}screenshots

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip

* Tasks *
Orders robots from RobotSpareBin Industries Inc
    Create Outpup Directory

    Get Secrets From Vault
    ${username}=    Get The User Name

    Download the csv File
    Open the Intranet website
    
    ${index}                Set Variable            0
    ${orders}=              Get Orders              ${orders_file}
    ${rows}  ${columns}=    Get table dimensions    ${orders}
       
    WHILE    ${index} < ${rows}
        Close the Annoying Modal
        Wait Until Keyword Succeeds                10x   0.5s   Fill the Form                 ${orders}[${index}]
        Wait Until Keyword Succeeds                15x    1s    Preview the Bot
        ${ss_path}=                                Saves the SS of the Ordered Bot            ${orders}[${index}][0]
        Wait Until Keyword Succeeds                15x    1s    Submit the Order
        ${pdf_path}=                               Store the Receipt as a PDF File            ${orders}[${index}][0]
        Embed the bot SS to the receipt PDF file   ${ss_path}                                 ${pdf_path}
        Wait Until Keyword Succeeds                15x    1s    Order Another Bot

        ${index}    Evaluate    ${index}+1
    END

    Create a Zip File of the Receipts
    Display the success dialog  user_name=${username}
    Directory Cleanup
    [Teardown]    Close Browser
      

* Keywords *

Get The User Name
    Add heading             RoboCorp Order Assistant
    Add text input          my_name    label=What should I call you?    placeholder=Input here
    ${result}=              Run dialog
    [Return]                ${result.my_name}

Get Secrets From Vault
    ${secret}=              Get Secret             secrets
    Log To Console          ${secret}[username]

Create a Zip File of the Receipts
    Archive Folder With ZIP         ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

Show the Success Dialog
    [Arguments]   ${user_name}
    Add icon      Success
    Add heading   Your orders have been processed
    Add text      ${user_name} - All orders have been processed!
    Run dialog    title=Success

Download the CSV File
    Download    ${csv_url}    target_file=${CURDIR}    

Get Orders
    [Arguments]       ${csv_path}    
    ${orders} =       Read table from CSV   ${csv_path}
    RETURN            ${orders}

Open the Intranet website
    Open Available Browser    ${webpage}  

Close the Annoying Modal
    ${button}      Set Variable    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button   ${button}

Fill the Form
    [Arguments]                  ${row}

    ${head_xpath}                Set Variable        //*[@id="head"]
    ${body_xpath}                Set Variable        //*[@id="id-body-${row}[2]"]
    ${legs_xpath}                Set Variable        //*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/p/following::input[1]
    ${address_xpath}             Set Variable        //*[@id="address"]
    
    Select From List By Value    ${head_xpath}       ${row}[1]
    Click Element                ${body_xpath}
    Input Text                   ${legs_xpath}       ${row}[3]
    Input Text                   ${address_xpath}    ${row}[4]

Preview the Bot
    ${bt_preview_xpath}    Set Variable            //*[@id="preview"]
    Click Button           ${bt_preview_xpath}

Saves the SS of the Ordered Bot   
    [Arguments]   ${order_number}
    
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    ${ss_path}                          Set Variable                      ${ss_folder}${/}${order_number}.png
    
    Sleep                            1sec
    Screenshot                       //*[@id="robot-preview-image"]    ${ss_path}
    
    RETURN    ${ss_path}

Submit the Order
    ${bt_order_xpath}              Set Variable            //*[@id="order"]
    ${receipt}                     Set Variable            //*[@id="receipt"]

    Click Button                   ${bt_order_xpath}
    Page Should Contain Element    ${receipt} 

Store the Receipt as a PDF File
    [Arguments]                     ${order_number}

    Wait Until Element Is Visible   //*[@id="receipt"]
    ${order_receipt_html}=          Get Element Attribute            //*[@id="receipt"]    outerHTML
    ${pdf_path}                     Set Variable                     ${pdf_folder}${/}${order_number}.pdf

    Html To Pdf                     content=${order_receipt_html}    output_path=${pdf_path}
    RETURN                          ${pdf_path}

Embed the bot SS to the receipt PDF file
    [Arguments]         ${img_file}     ${pdf_file}
     
    Open Pdf            ${pdf_file}
    @{myfiles}=         Create List     ${img_file}:align=center
    Add Files To PDF    ${myfiles}      ${pdf_file}             ${True}
    Close All Pdfs
    
Order Another Bot
    ${bt_neworder_xpath}   Set Variable            //*[@id="order-another"]
    Click Button           ${bt_neworder_xpath}

Display the success dialog
    [Arguments]   ${user_name}
    Add icon      Success
    Add heading   Your orders have been processed
    Add text      Dear ${user_name}, all orders have been processed! See you soon <3
    Run dialog    title=Success

Create Outpup Directory
    Create Directory    ${output_folder}

Directory Cleanup
    # ${directory_not_exists}=    Does Directory Exist    ${output_folder}
    
    # IF    ${directory_not_exists}
    #     Remove directory    ${output_folder}    recursive=${True}
    # END

    ${directory_not_exists}=    Does Directory Exist    ${pdf_folder}
    IF    ${directory_not_exists}
        Remove directory    ${pdf_folder}       recursive=${True}
    END

    ${directory_not_exists}=    Does Directory Exist    ${ss_folder}
    IF    ${directory_not_exists}
        Remove directory    ${ss_folder}        recursive=${True}
    END
   
    ${file_exists}=    Does File Exist    ${orders_file}
    IF    ${file_exists}
        Remove File    ${orders_file}    
    END
    
