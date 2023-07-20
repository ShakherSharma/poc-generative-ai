-- Oracle PLSQL Package Body for Daily Rates Interface

CREATE OR REPLACE PACKAGE BODY DLY_RTS_INTF_PKG AS

    -- This procedure selects:
    -- 1. User ID of OPERATIONS user
    -- 2. Responsibility ID and Application ID of responsibility with name as System Administrator
    -- It then uses these values to intialize the apps environment
    PROCEDURE init_apps_env IS
        l_user_id NUMBER;
        l_resp_id NUMBER;
        l_appl_id NUMBER;
    BEGIN
        SELECT user_id
        INTO l_user_id
        FROM fnd_user
        WHERE user_name = 'OPERATIONS';

        SELECT responsibility_id, application_id
        INTO l_resp_id, l_appl_id
        FROM fnd_responsibility_vl
        WHERE responsibility_name = 'System Administrator';

        fnd_global.apps_initialize(l_user_id, l_resp_id, l_appl_id);
    END init_apps_env;




    -- This function retruns false if any of the following conditions are met:
    -- Currency code is null
    -- Currency code don't exists in FND_CURRENCIES table
    -- Currency code is not enabled
    -- Current date is not between start date and end date of currency. 
    --   If start date is null, it is converted to current date-1 
    --     and if end date is null, it is converted to current date.
    -- If all the above conditions are met, it returns true
    FUNCTION is_valid_currency(p_currency_code IN VARCHAR2) RETURN BOOLEAN IS
        l_currency_code VARCHAR2(3);
        l_start_date DATE;
        l_end_date DATE;
        l_curr_enabled VARCHAR2(1);
    BEGIN
        IF p_currency_code IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT currency_code, start_date_active, end_date_active, enabled_flag
        INTO l_currency_code, l_start_date, l_end_date, l_curr_enabled
        FROM fnd_currencies
        WHERE currency_code = p_currency_code;

        IF l_currency_code IS NULL THEN
            RETURN FALSE;
        END IF;

        IF l_curr_enabled = 'N' THEN
            RETURN FALSE;
        END IF;

        IF l_start_date IS NULL THEN
            l_start_date := SYSDATE - 1;
        END IF;

        IF l_end_date IS NULL THEN
            l_end_date := SYSDATE;
        END IF;

        IF SYSDATE NOT BETWEEN l_start_date AND l_end_date THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    END is_valid_currency;

    


    -- This function returns false if record matching following conditions are found in the GL_DAILY_RATES table:
    -- 1. From Currency is equals to currency passed
    -- 2. To Currency is equals to currency passed
    -- 3. From Conversion Date is equals to from conversion date passed
    -- 4. To Conversion Date is equals to to conversion date passed
    -- 5. User conversion type is equals to user conversion type passed
    -- 6. Conversion rate is equal to conversion rate passed
    -- If no record is found, it returns true
    FUNCTION is_duplicate_record(p_from_currency IN VARCHAR2, p_to_currency IN VARCHAR2, p_from_conv_date IN DATE, p_to_conv_date IN DATE, p_user_conv_type IN VARCHAR2, p_conv_rate IN NUMBER) RETURN BOOLEAN IS
        l_from_currency VARCHAR2(3);
        l_to_currency VARCHAR2(3);
        l_from_conv_date DATE;
        l_to_conv_date DATE;
        l_user_conv_type VARCHAR2(30);
        l_conv_rate NUMBER;
    BEGIN
        SELECT from_currency, to_currency, conversion_date, conversion_date, conversion_type, conversion_rate
        INTO l_from_currency, l_to_currency, l_from_conv_date, l_to_conv_date, l_user_conv_type, l_conv_rate
        FROM gl_daily_rates
        WHERE from_currency = p_from_currency
        AND to_currency = p_to_currency
        AND ( conversion_date = p_from_conv_date or conversion_date = p_to_conv_date )
        AND conversion_type = p_user_conv_type
        AND conversion_rate = p_conv_rate;

        RETURN FALSE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN TRUE;
    END is_duplicate_record;

    -- This function retruns false if any of the following conditions are met:
    -- From Currency is null
    -- To Currency is null
    -- From Conversion Date is null
    -- To Conversion Date is null
    -- From Conversion Date is not a date
    -- To Conversion Date is not a date
    -- User Conversion Type is null
    -- Mode Flag is null
    -- Conversion Rate is null
    -- Conversion Rate is not a number
    -- If all the above conditions are met, it returns true
    FUNCTION is_valid_record(p_from_currency IN VARCHAR2, p_to_currency IN VARCHAR2, p_from_conv_date IN VARCHAR2, p_to_conv_date IN VARCHAR2, p_user_conv_type IN VARCHAR2, p_mode_flag IN VARCHAR2, p_conv_rate IN VARCHAR2) RETURN BOOLEAN IS
        l_from_conv_date DATE;
        l_to_conv_date DATE;
        l_conv_rate NUMBER;
    BEGIN
        IF p_from_currency IS NULL THEN
            RETURN FALSE;
        END IF;

        IF p_to_currency IS NULL THEN
            RETURN FALSE;
        END IF;

        IF p_from_conv_date IS NULL THEN
            RETURN FALSE;
        END IF;

        IF p_to_conv_date IS NULL THEN
            RETURN FALSE;
        END IF;

        IF p_user_conv_type IS NULL THEN
            RETURN FALSE;
        END IF;

        IF p_mode_flag IS NULL THEN
            RETURN FALSE;
        END IF;

        IF p_conv_rate IS NULL THEN
            RETURN FALSE;
        END IF;

        BEGIN
            l_from_conv_date := TO_DATE(p_from_conv_date, 'DD-MON-YYYY');
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;

        BEGIN
            l_to_conv_date := TO_DATE(p_to_conv_date, 'DD-MON-YYYY');
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;

        BEGIN
            l_conv_rate := TO_NUMBER(p_conv_rate);
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;

        RETURN TRUE;
    END is_valid_record;

    -- Procedure to earmark invalid records
    PROCEDURE earmark_invalid_records IS

    -- Open a cursor for update to select all records with status as I from XXGL_DAILY_RATES_INTF_STG table where status is I
    CURSOR c_dly_rts_intf IS
        SELECT from_currency, to_currency, from_conversion_date, to_conversion_date, user_conversion_type, mode_flag, conversion_rate
        FROM XXGL_DAILY_RATES_INTF_STG
        WHERE status = 'I'
        FOR UPDATE;
    
    -- flag to maintain error status
    l_error_flag BOOLEAN := FALSE;

    -- variable to maintain error message
    l_error_msg VARCHAR2(2000);

    BEGIN
        -- traverse records from cursor
        FOR r_dly_rts_intf IN c_dly_rts_intf LOOP
            -- check if record is valid. if not, set error flag to true and store message as: Invalid record
            IF is_valid_record(r_dly_rts_intf.from_currency, r_dly_rts_intf.to_currency, r_dly_rts_intf.from_conversion_date, r_dly_rts_intf.to_conversion_date, r_dly_rts_intf.user_conversion_type, r_dly_rts_intf.mode_flag, r_dly_rts_intf.conversion_rate) = FALSE THEN
                l_error_flag := TRUE;
                l_error_msg := 'Invalid record';
            END IF;

            -- if error flag is false, check if from currency and to currency are valid. if not, set error flag to true and store message as: Invalid From Currency or Invalid To Currency
            IF l_error_flag = FALSE THEN
                IF is_valid_currency(r_dly_rts_intf.from_currency) = FALSE OR is_valid_currency(r_dly_rts_intf.to_currency) = FALSE THEN
                    l_error_flag := TRUE;
                    l_error_msg := 'Invalid From Currency or Invalid To Currency';
                END IF;
            END IF;

            -- if error flag is false, check if from currency is equal to to currency. if yes, set error flag to true and store message as: From currency and To currency cannot be same
            IF l_error_flag = FALSE THEN
                IF r_dly_rts_intf.from_currency = r_dly_rts_intf.to_currency THEN
                    l_error_flag := TRUE;
                    l_error_msg := 'From currency and To currency cannot be same';
                END IF;
            END IF;

            -- if error flag is false, check if record is duplicate. if yes, set error flag to true and store message as: Duplicate record
            IF l_error_flag = FALSE THEN
                IF is_duplicate_record(r_dly_rts_intf.from_currency, r_dly_rts_intf.to_currency, r_dly_rts_intf.from_conversion_date, r_dly_rts_intf.to_conversion_date, r_dly_rts_intf.user_conversion_type, r_dly_rts_intf.conversion_rate) = FALSE THEN
                    l_error_flag := TRUE;
                    l_error_msg := 'Duplicate record';
                END IF;
            END IF;

            -- if error flag is true, update status as E and error message in XXGL_DAILY_RATES_INTF_STG table
            IF l_error_flag = TRUE THEN
                UPDATE XXGL_DAILY_RATES_INTF_STG
                SET status = 'E', error_message = l_error_msg
                WHERE CURRENT OF c_dly_rts_intf;
            END IF;


        END LOOP;

        -- commit the changes
        COMMIT;

    END earmark_invalid_records;

    
    
    -- Proecure to start processing of Daily Rates Interface
    PROCEDURE start_dly_rts_intf IS
        -- This cursor selects all records with status as I from XXGL_DAILY_RATES_INTF_STG table
        CURSOR c_dly_rts_intf IS
            SELECT from_currency, to_currency, from_conversion_date, to_conversion_date, user_conversion_type, mode_flag, conversion_rate
            FROM XXGL_DAILY_RATES_INTF_STG
            WHERE status = 'I';
        -- This is an error flag
        l_error_flag BOOLEAN := FALSE;
    BEGIN
        -- initialize apps environment
        init_apps_env;

        -- call earmark invalid records procedure
        earmark_invalid_records;

    END start_dly_rts_intf;

END DLY_RTS_INTF_PKG;
