*** Settings ***
Library                         QWeb
Library                         String
Library                         FakerLibrary


*** Variables ***
# ${eum_org_name}               CXOps RoboticTesting CREDITS
${product_key}                  MAPPER-OTC1-DESKTOP
${product_description}          PIX4Dcloud Advanced, Monthly, Subscription
# credit amount view ui variable
${credit_amount_ui}             1,000
${total_user_credit}            2200
${product_credit_1000}          CLOUD-CREDITS-1000,CLOUD-ADVANCED-MONTH-SUBS
${url_buy_product}              https://dev.account.pix4d.com/complete-purchase?PROD_KEYS=${product_credit_1000}
${url_dev}                      https://dev.cloud.pix4d.com
${url_account_dev}              https://dev.account.pix4d.com
# Remove credentials tehy'e going github XXXXXXXX
${card_number}                  4111111111111111
${card_expiration_date}         0130
${card_security_code}           234
${cart_holder_name}             John Doe
${pandora_migration_task}       https://dev.cloud.pix4d.com/admin/common/admintask/63/change/?_changelist_filters=q%3Dpandora
${admin_tasks}                  https://dev.cloud.pix4d.com/admin/common/admintask/




*** Keywords ***
Robot_Login_To_Staging_AP
    [Documentation]             Robot loging to staging Admin Panel
    GoTo                        ${url_dev}/admin_panel/     timeout=5
    TypeText                    Enter email                 ${robot_username}
    ClickText                   Continue
    VerifyText                  Log in
    TypeText                    Enter password              ${robot_password}
    ClickText                   Log in                      anchor=Back


Create_Random_Person_Data
    [Documentation]             This will create a random person with first_name, last_name, email, password
    ${fake_user_first_name}=    FakerLibrary.first_name
    Set Suite Variable          ${fake_user_first_name}
    ${fake_user_last_name}=     FakerLibrary.last_name
    Set Suite Variable          ${fake_user_last_name}
    ${fake_user_email}=         FakerLibrary.email          domain=pix4d.work
    Set Suite Variable          ${fake_user_email}
    ${fake_user_password}=      FakerLibrary.Password
    Set Suite Variable          ${fake_user_password}
    Log To Console              Created user: ${fake_user_first_name}, ${fake_user_last_name}, ${fake_user_email}, ${fake_user_password}
    Return From Keyword

Fill_User_Form_And_Verify
    [Documentation]             Fill the user form and verify 'Billing info'. Retry up to 3 times if verification fails.
    ${retries}=                 Set Variable                3
    FOR                         ${index}                    IN RANGE                    ${retries} # with varibale not working
        CreateRandomPersonData
        GoTo                    ${url_dev}/admin_panel/pixuser/new/
        VerifyText              New User
        Type Text               id_first_name               ${fake_user_first_name}
        Type Text               Last name                   ${fake_user_last_name}
        Type Text               Email address               ${fake_user_email}
        Type Text               Password                    ${fake_user_password}
        Type Text               Password confirmation       ${fake_user_password}
        Click Text              SAVE
        ${status}=              Is Text                     Billing info                timeout=5
        IF                      ${status}
            Log To Console      Billing info verified.
            Return From Keyword
        ELSE
            Log To Console      Billing info not found, retrying...
            Refresh Page
            Sleep               2                           # Wait for 2 seconds before retrying
        END
    END
    Fail                        Billing info could not be verified after: ${retries} retries.

Get_User_Data_And_Save
    [Documentation]             Get user url, id, uuid and store to variable
    VerifyAll                   ${fake_user_email}, Profile info
    ${fake_user_url}            GetUrl
    Set Suite Variable          ${fake_user_url}
    Log To Console              ${fake_user_url}
    @{url_parts}=               Split String                ${fake_user_url}            /
    ${fake_user_id}=            Set Variable                ${url_parts}[5]
    Log To Console              ${fake_user_id}
    Set Suite Variable          ${fake_user_id}
    ${full_uuid_text}           GetText                     //div[contains(@class, 'mdl-cell-full') and contains(., 'UUID:')]
    Log To Console              ${full_uuid_text}
    @{split_text}=              Split String                ${full_uuid_text}           UUID:
    ${fake_user_uuid}=          Strip String                ${split_text}[1]
    Log To Console              ${fake_user_uuid}
    Set Suite Variable          ${fake_user_uuid}
Add_QA_Comment_To_User
    TypeText                    id_comment                  TEST_CXOps_QA
    ClickText                   SAVE PROFILE

Create_New_Rondom_User
    [Documentation]             This will create a new user in the Admin Panel application
    GoTo                        ${url_dev}/admin_panel/pixuser/new/
    Sleep                       3
    Fill User Form And Verify
    Refresh Page
    Get_User_Data_And_Save
    Add_QA_Comment_To_User

Login_As_User
    [Documentation]             Login as fake user
    TypeText                    Enter email                 ${fake_user_email}
    ClickText                   Continue
    VerifyText                  Log in
    TypeText                    Enter password              ${fake_user_password}
    ClickText                   Log in                      anchor=Back

GDPR_Deletion_Rondom_User
    [Documentation]             GDPR deletion of the test pixuser
    GoTo                        ${fake_user_url}
    VerifyAll                   ${fake_user_email}, Profile info, ${fake_user_uuid}
    ClickText                   GDPR Deletion               tag=button
    CloseAlert                  accept                      10s
    VerifyText                  Account disabled upon GDPR request from data subject

