-- This is the PLSQL package body for DLY_RTS_DMMY_DT_GNRTR

CREATE OR REPLACE PACKAGE BODY DLY_RTS_DMMY_DT_GNRTR AS

-- This procedure selects USER_ID of user OPERATIONS. It also selects RESPONSIBILITY_ID and APPLICATION_ID for responsibility 'Application Developer'. 
-- It uses selected values to execute fnd_global.APPS_INITIALIZE.

PROCEDURE APPS_INITIALIZE IS
  v_user_id NUMBER;
  v_resp_id NUMBER;
  v_appl_id NUMBER;
BEGIN
    SELECT user_id INTO v_user_id FROM fnd_user WHERE user_name = 'OPERATIONS';
    SELECT responsibility_id INTO v_resp_id FROM fnd_responsibility_vl WHERE responsibility_name = 'Application Developer';
    SELECT application_id INTO v_appl_id FROM fnd_application_vl WHERE application_short_name = 'SQLAP';
    fnd_global.APPS_INITIALIZE(v_user_id, v_resp_id, v_appl_id);
END APPS_INITIALIZE;

 -- This procedure takes p_from_currency, p_to_currency, and p_file_name as parameters
 --
 -- It insert record into XXGL_DAILY_RATES_INTF_STG table
 -- Values for various columns are set as follows:
 -- FROM_CONVERSION_DATE will be set to current date -1
 -- TO_CONVERSION_DATE will be set to current date 
 -- FROM_CURRENCY will be set to p_from_currency
 -- TO_CURRENCY will be set to p_to_currency
 -- MODE_FLAG will be set to 'I'
 -- CONVERSION_TYPE will be set to 'Corporate'
 -- CONVERSION_RATE will be set to dbms_random.value(1,100)
 -- CREATION_DATE will be set to SYSDATE
 -- CREATED_BY will be set to apps.fnd_global.user_id
 -- LAST_UPDATE_DATE will be set to current date
 -- LAST_UPDATED_BY will be set to fnd_global.user_id
 -- LAST_UPDATE_LOGIN will be set to fnd_global.login_id
 -- REQUEST_ID will be set to 0
 -- FILE_NAME value will be set as p_file_name
 -- LOAD_DATE value will be set as SYSDATE
 -- RECORD_ID value will be set as  XXGL_DAILY_RATES_INTF_STG_S.NEXTVAL 

PROCEDURE INSERT_DUMMY_RECORD(p_from_currency VARCHAR2, p_to_currency VARCHAR2, p_file_name VARCHAR2) IS
  v_from_conversion_date DATE;
  v_to_conversion_date DATE;
  v_from_currency VARCHAR2(3);
  v_to_currency VARCHAR2(3);
  v_mode_flag VARCHAR2(1);
  v_conversion_type VARCHAR2(30);
  v_conversion_rate NUMBER;
  v_creation_date DATE;
  v_created_by NUMBER;
  v_last_update_date DATE;
  v_last_updated_by NUMBER;
  v_last_update_login NUMBER;
  v_request_id NUMBER;
  v_file_name VARCHAR2(100);
  v_load_date DATE;
  v_record_id NUMBER;

BEGIN
    v_from_conversion_date := SYSDATE - 1;
    v_to_conversion_date := SYSDATE;
    v_from_currency := p_from_currency;
    v_to_currency := p_to_currency;
    v_mode_flag := 'I';
    v_conversion_type := 'Corporate';
    v_conversion_rate := dbms_random.value(1,100);
    v_creation_date := SYSDATE;
    v_created_by := fnd_global.user_id;
    v_last_update_date := SYSDATE;
    v_last_updated_by := fnd_global.user_id;
    v_last_update_login := fnd_global.login_id;
    v_request_id := 0;
    v_file_name := p_file_name;
    v_load_date := SYSDATE;
    v_record_id := XXGL_DAILY_RATES_INTF_STG_S.NEXTVAL;
    
    INSERT INTO XXGL_DAILY_RATES_INTF_STG
    (FROM_CONVERSION_DATE, TO_CONVERSION_DATE, FROM_CURRENCY, TO_CURRENCY, MODE_FLAG, CONVERSION_TYPE, CONVERSION_RATE, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, REQUEST_ID, FILE_NAME, LOAD_DATE, RECORD_ID)
    VALUES
    (v_from_conversion_date, v_to_conversion_date, v_from_currency, v_to_currency, v_mode_flag, v_conversion_type, v_conversion_rate, v_creation_date, v_created_by, v_last_update_date, v_last_updated_by, v_last_update_login, v_request_id, v_file_name, v_load_date, v_record_id);
    
    COMMIT;
    END INSERT_DUMMY_RECORD;

-- This procedure selects valid currencies from FND_CURRENCIES table and calls insert_into_daily_rates_intf_stg procedure.
-- Different currencies are passed as parameters to insert_into_daily_rates_intf_stg procedure.
-- Only 100 records should be inserted into XXGL_DAILY_RATES_INTF_STG table at a time.

PROCEDURE INSERT_DUMMY_RECORDS IS
  v_from_currency VARCHAR2(3);
  v_to_currency VARCHAR2(3);
  v_file_name VARCHAR2(100);
BEGIN
    FOR i IN (SELECT currency_code FROM fnd_currencies WHERE enabled_flag = 'Y') LOOP
        v_from_currency := i.currency_code;
        v_to_currency := i.currency_code;
        v_file_name := 'DUMMY';
        INSERT_DUMMY_RECORD(v_from_currency, v_to_currency, v_file_name);
    END LOOP;
END INSERT_DUMMY_RECORDS;

-- This method called "main" will first call APPS_INITIALIZE method, followed by insert_into_daily_rates_intf_stg method.

PROCEDURE main IS
BEGIN
    APPS_INITIALIZE;
    INSERT_DUMMY_RECORDS;
END main;

END DLY_RTS_DMMY_DT_GNRTR;