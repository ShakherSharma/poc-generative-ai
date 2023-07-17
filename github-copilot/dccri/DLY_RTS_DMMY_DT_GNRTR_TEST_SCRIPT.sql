-- This Oracle PLSQL block is a test case for DLY_RTS_DMMY_DT_GNRTR.main method.
-- This method takes no parameter.
-- On successfully completion, message "Success!" will be printed.
-- On failure, error message will be printed.

DECLARE
    l_return_msg VARCHAR2(2000);
    -- variable to store count of records from XXGL_DAILY_RATES_INTF_STG table.
    l_count NUMBER;
BEGIN
    l_return_msg := 'Success!';

    -- Print count of records from XXGL_DAILY_RATES_INTF_STG table.
    SELECT COUNT(1) INTO l_count FROM XXGL_DAILY_RATES_INTF_STG;
    DBMS_OUTPUT.put_line('Count of records in XXGL_DAILY_RATES_INTF_STG table: ' || l_count);


    DLY_RTS_DMMY_DT_GNRTR.main;
    DBMS_OUTPUT.put_line(l_return_msg);

    -- Print count of records from XXGL_DAILY_RATES_INTF_STG table.
    SELECT COUNT(1) INTO l_count FROM XXGL_DAILY_RATES_INTF_STG;
    DBMS_OUTPUT.put_line('Count of records in XXGL_DAILY_RATES_INTF_STG table: ' || l_count);
EXCEPTION   
    WHEN OTHERS THEN
        l_return_msg := 'Error: ' || SQLERRM;
        DBMS_OUTPUT.put_line(l_return_msg);
END;



