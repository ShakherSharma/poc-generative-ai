-- This standalone PLSQL function converts ISBN13 to ISBN10
-- This function is based on the algorithm described at http://www.isbn.org/standards/home/isbn/transition.asp

CREATE OR REPLACE FUNCTION isbn13_to_isbn10 (p_isbn13 IN VARCHAR2) RETURN VARCHAR2 IS
  l_isbn10 VARCHAR2(10);
  l_isbn13 VARCHAR2(13);
  l_isbn10_check_digit NUMBER;
  l_isbn13_check_digit NUMBER;
BEGIN
    l_isbn13 := p_isbn13;
    IF LENGTH(l_isbn13) <> 13 THEN
        RAISE_APPLICATION_ERROR(-20000, 'ISBN13 must be 13 characters long');
    END IF;
    IF SUBSTR(l_isbn13, 1, 3) <> '978' THEN
        RAISE_APPLICATION_ERROR(-20000, 'ISBN13 must start with 978');
    END IF;
    l_isbn13_check_digit := TO_NUMBER(SUBSTR(l_isbn13, 13, 1));
    l_isbn10 := SUBSTR(l_isbn13, 4, 9);
    l_isbn10_check_digit := 0;
    FOR i IN 1..LENGTH(l_isbn10) LOOP
        l_isbn10_check_digit := l_isbn10_check_digit + (11 - i) * TO_NUMBER(SUBSTR(l_isbn10, i, 1));
    END LOOP;
    l_isbn10_check_digit := MOD(l_isbn10_check_digit, 11);
    IF l_isbn10_check_digit = 10 THEN
        l_isbn10_check_digit := 'X';
    END IF;
    RETURN l_isbn10 || l_isbn10_check_digit;
END isbn13_to_isbn10;


-- This standalone Oracle PLSQL block is a test case for isbn13_to_isbn10 

DECLARE
  l_isbn13 VARCHAR2(13);
  l_isbn10 VARCHAR2(10);
BEGIN
    l_isbn13 := '9780596513989';
    l_isbn10 := isbn13_to_isbn10(l_isbn13);
    DBMS_OUTPUT.PUT_LINE('ISBN13: ' || l_isbn13 || ' ISBN10: ' || l_isbn10);
END;

-- This standalone PLSQL function converts ISBN10 to ISBN13
-- This function is based on the algorithm described at http://www.isbn.org/standards/home/isbn/transition.asp

CREATE OR REPLACE FUNCTION isbn10_to_isbn13 (p_isbn10 IN VARCHAR2) RETURN VARCHAR2 IS
  l_isbn10 VARCHAR2(10);
  l_isbn13 VARCHAR2(13);
  l_isbn10_check_digit NUMBER;
  l_isbn13_check_digit NUMBER;
BEGIN
    l_isbn10 := p_isbn10;
    IF LENGTH(l_isbn10) <> 10 THEN
        RAISE_APPLICATION_ERROR(-20000, 'ISBN10 must be 10 characters long');
    END IF;
    l_isbn10_check_digit := TO_NUMBER(SUBSTR(l_isbn10, 10, 1));
    l_isbn13 := '978' || SUBSTR(l_isbn10, 1, 9);
    l_isbn13_check_digit := 0;
    FOR i IN 1..LENGTH(l_isbn13) LOOP
        l_isbn13_check_digit := l_isbn13_check_digit + (11 - i) * TO_NUMBER(SUBSTR(l_isbn13, i, 1));
    END LOOP;
    l_isbn13_check_digit := MOD(l_isbn13_check_digit, 11);
    IF l_isbn13_check_digit = 10 THEN
        l_isbn13_check_digit := 'X';
    END IF;
    RETURN l_isbn13 || l_isbn13_check_digit;
END isbn10_to_isbn13;


-- This standalone Oracle PLSQL block is a test case for isbn10_to_isbn13

DECLARE
  l_isbn10 VARCHAR2(10);
  l_isbn13 VARCHAR2(13);
BEGIN
    l_isbn10 := '0596513987';
    l_isbn13 := isbn10_to_isbn13(l_isbn10);
    DBMS_OUTPUT.PUT_LINE('ISBN10: ' || l_isbn10 || ' ISBN13: ' || l_isbn13);
END;


-- This standalone PLSQL function validates email addresses
-- This function is based on the algorithm described at http://www.regular-expressions.info/email.html

CREATE OR REPLACE FUNCTION is_valid_email (p_email IN VARCHAR2) RETURN BOOLEAN IS
  l_valid BOOLEAN;
BEGIN
    l_valid := REGEXP_LIKE(p_email, '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$', 'i');
    RETURN l_valid;
END is_valid_email;

-- This standalone Oracle PLSQL block is a test case for is_valid_email
-- It prints Valid if the email address is valid, otherwise it prints Invalid

DECLARE
  l_email VARCHAR2(100);
  l_valid BOOLEAN;
BEGIN
    l_email := 'shakher.sharma@outlook.com';
    l_valid := is_valid_email(l_email);
    IF l_valid THEN
        DBMS_OUTPUT.PUT_LINE('Valid');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Invalid');
    END IF;
END;


-- This standalone PLSQL function validates URLs
-- This function is based on the algorithm described at http://www.regular-expressions.info/email.html

CREATE OR REPLACE FUNCTION is_valid_url (p_url IN VARCHAR2) RETURN BOOLEAN IS
  l_valid BOOLEAN;
BEGIN
    l_valid := REGEXP_LIKE(p_url, '^(http|https|ftp)://[A-Z0-9.-]+\.[A-Z]{2,4}$', 'i');
    RETURN l_valid;
END is_valid_url;

-- This standalone PLSQL block is a test case for is_valid_url
-- It prints Valid if the URL is valid, otherwise it prints Invalid

DECLARE
  l_url VARCHAR2(100);
  l_valid BOOLEAN;
BEGIN
    l_url := 'http://www.shakher.com';
    l_valid := is_valid_url(l_url);
    IF l_valid THEN
        DBMS_OUTPUT.PUT_LINE('Valid');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Invalid');
    END IF;
END;


-- This standalone PLSQL function validates that the name passed to it has no special characters
-- This function is based on the algorithm described at http://www.regular-expressions.info/email.html

CREATE OR REPLACE FUNCTION is_valid_name (p_name IN VARCHAR2) RETURN BOOLEAN IS
  l_valid BOOLEAN;
BEGIN
    l_valid := REGEXP_LIKE(p_name, '^[A-Z0-9 ]+$', 'i');
    RETURN l_valid;
END is_valid_name;

-- This standalone Oracle PLSQL block is a test case for is_valid_name
-- It prints Valid if the name is valid, otherwise it prints Invalid

DECLARE
  l_name VARCHAR2(100);
  l_valid BOOLEAN;
BEGIN
    l_name := 'Shakher Sharma';
    l_valid := is_valid_name(l_name);
    IF l_valid THEN
        DBMS_OUTPUT.PUT_LINE('Valid');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Invalid');
    END IF;
END;

-- This standalone Oracle PLSQL method takes user name as input and returns the user id from FND_USER table

CREATE OR REPLACE FUNCTION get_user_id (p_user_name IN VARCHAR2) RETURN NUMBER IS
  l_user_id NUMBER;
BEGIN
    SELECT user_id
    INTO l_user_id
    FROM fnd_user
    WHERE user_name = p_user_name;
    RETURN l_user_id;
END get_user_id;

-- This standalone Oracle PLSQL block is a test case for get_user_id

DECLARE
  l_user_id NUMBER;
BEGIN
    l_user_id := get_user_id('OPERATIONS');
    DBMS_OUTPUT.PUT_LINE('User Id: ' || l_user_id);
END;
