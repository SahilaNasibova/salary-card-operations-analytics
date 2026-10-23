CREATE OR REPLACE PROCEDURE RNM_026_SAL_OPS_COM_PRC (
    PBRANCH IN VARCHAR2,
    PDATE1  IN DATE,
    PDATE2  IN DATE,
    PUSER   IN VARCHAR2
) IS
    V_STARTED  DATE;
    V_LOG_DESC VARCHAR2(500);
BEGIN
    V_STARTED := SYSDATE;

    IF PDATE1 >= ADD_MONTHS(SYSDATE - 1, -6) THEN

        -- Öz sxemimizdəki temp cədvəlin təmizlənməsi
        EXECUTE IMMEDIATE ('TRUNCATE TABLE CBDD_TIBCO.RNM_SAL_OPS$TT');

        -- Temp cədvələ məlumatların doldurulması
        INSERT INTO CBDD_TIBCO.RNM_SAL_OPS$TT
        WITH GL AS (
            SELECT GL.VALUE_DATE,
                   GL.BRANCH,
                   AC.SUBLEDGER,
                   GL.ACCOUNT_ID,
                   AC.ACC_NAME          ACC_NAME1,
                   CM.CUST_NAME         CUST_NAME1,
                   GL.COR_ACC_SUBLEDER,
                   GL.COR_ACC_ID,
                   AC2.ACC_NAME         ACC_NAME2,
                   CM.CUST_NAME         CUST_NAME2,
                   GL.CURRENCY_NO,
                   GL.AMOUNT_CUR,
                   GL.AMOUNT_LOC,
                   GL.CLASS_OP,
                   GL.HEADER_NO,
                   GL.REMARKS,
                   GL.CREATED_BY,
                   CM.TAX_NUMBER        INN_1,
                   CM.TAX_NUMBER        INN_2,
                   CR.CUSTOMER_NO
              FROM RS.GL_ENTRIES_CORPORATE GL
              JOIN RS.ACCOUNTS AC
                ON AC.ACCOUNT_ID = GL.ACCOUNT_ID
               AND AC.BRANCH = GL.BRANCH
              JOIN RS.ACCOUNTS AC2
                ON AC2.ACCOUNT_ID = GL.COR_ACC_ID
               AND AC2.BRANCH = GL.BRANCH
              JOIN RS.SUB_GUIDE S
                ON AC.SUBLEDGER = S.BALANS_HESABI
               AND BÖLGÜ IN ('Hüquqi şəxslər_t')
              JOIN RS.CUSTOMERS_RELATION_INFO CR
                ON AC.CUSTOMER_NO = CR.CUSTOMER_NO
               AND AC.BRANCH = CR.BRANCH
              JOIN RS.CUSTOMERS_MAIN_INFO CM
                ON CM.CLIENTNO = CR.CLIENTNO
             WHERE GL.VALUE_DATE BETWEEN PDATE1 AND PDATE2
               AND GL.AMOUNT_LOC > 0
               AND BÖLGÜ IN ('Hüquqi şəxslər_t')
               AND GL.BRANCH = DECODE(PBRANCH, '%', GL.BRANCH, PBRANCH)
        )
        SELECT VALUE_DATE,
               BRANCH,
               SUBLEDGER,
               ACCOUNT_ID,
               ACC_NAME1,
               CUST_NAME1,
               COR_ACC_SUBLEDER,
               COR_ACC_ID,
               ACC_NAME2,
               CUST_NAME2,
               CURRENCY_NO,
               AMOUNT_CUR,
               AMOUNT_LOC,
               CLASS_OP,
               HEADER_NO,
               REMARKS,
               CREATED_BY,
               INN_1,
               INN_2
          FROM GL
         WHERE EXISTS (SELECT 1
                         FROM RS.CUSTOMERS_EMPLOYERS CC
                        WHERE CC.COMP_FACTORING_ACCOUNT = GL.COR_ACC_ID
                          AND CC.EMP_COMPANY_BRANCH = GL.BRANCH)
           AND EXISTS (SELECT 1
                         FROM RS.CUSTOMERS_EMPLOYERS CC
                        WHERE CC.EMP_COMPANY_CUST_NO = GL.CUSTOMER_NO
                          AND CC.EMP_COMPANY_BRANCH = GL.BRANCH);


        INSERT INTO CBDD_TIBCO.RNM_SAL_OPS_COM_RES (
            VALUE_DATE, BRANCH, SUBLEDGER, ACCOUNT_ID, ACC_NAME1, CUST_NAME1,
            INN_1, COR_ACC_SUBLEDER, COR_ACC_ID, ACC_NAME2, CUST_NAME2,
            CURRENCY_NO, AMOUNT_CUR, AMOUNT_LOC, CLASS_OP, COM_AMOUNT,
            REMARKS, CREATED_BY, HEADER_NO
        )
        SELECT R.VALUE_DATE,
               R.BRANCH,
               R.SUBLEDGER,
               R.ACCOUNT_ID,
               R.ACC_NAME1,
               R.CUST_NAME1,
               R.INN_1,
               R.COR_ACC_SUBLEDER,
               R.COR_ACC_ID,
               R.ACC_NAME2,
               R.CUST_NAME2,
               R.CURRENCY_NO,
               R.AMOUNT_CUR,
               R.AMOUNT_LOC,
               R.CLASS_OP,
               (SELECT SUM(AMOUNT_LOC)
                  FROM RS.GL_ENTRIES_CORPORATE G
                 WHERE G.HEADER_NO = R.HEADER_NO
                   AND G.BRANCH = R.BRANCH
                   AND G.COR_ACC_SUBLEDER = 67017) COM_AMOUNT,
               R.REMARKS,
               R.CREATED_BY,
               R.HEADER_NO
          FROM CBDD_TIBCO.RNM_SAL_OPS$TT R;

    ELSE

        EXECUTE IMMEDIATE ('TRUNCATE TABLE CBDD_TIBCO.RNM_SAL_OPS$TT');

        INSERT INTO CBDD_TIBCO.RNM_SAL_OPS$TT
        WITH GL AS (
            SELECT GL.VALUE_DATE,
                   GL.BRANCH,
                   AC.SUBLEDGER,
                   GL.ACCOUNT_ID,
                   AC.ACC_NAME          ACC_NAME1,
                   CM.CUST_NAME         CUST_NAME1,
                   GL.COR_ACC_SUBLEDER,
                   GL.COR_ACC_ID,
                   AC2.ACC_NAME         ACC_NAME2,
                   CM.CUST_NAME         CUST_NAME2,
                   GL.CURRENCY_NO,
                   GL.AMOUNT_CUR,
                   GL.AMOUNT_LOC,
                   GL.CLASS_OP,
                   GL.HEADER_NO,
                   GL.REMARKS,
                   GL.CREATED_BY,
                   CM.TAX_NUMBER        INN_1,
                   CM.TAX_NUMBER        INN_2,
                   CR.CUSTOMER_NO
              FROM RS.GL_ENTRIES_CORPORATE GL
              JOIN RS.ACCOUNTS AC
                ON AC.ACCOUNT_ID = GL.ACCOUNT_ID
               AND AC.BRANCH = GL.BRANCH
              JOIN RS.ACCOUNTS AC2
                ON AC2.ACCOUNT_ID = GL.COR_ACC_ID
               AND AC2.BRANCH = GL.BRANCH
              JOIN RS.SUB_GUIDE S
                ON AC.SUBLEDGER = S.BALANS_HESABI
               AND BÖLGÜ IN ('Hüquqi şəxslər_t')
              JOIN RS.CUSTOMERS_RELATION_INFO CR
                ON AC.CUSTOMER_NO = CR.CUSTOMER_NO
               AND AC.BRANCH = CR.BRANCH
              JOIN RS.CUSTOMERS_MAIN_INFO CM
                ON CM.CLIENTNO = CR.CLIENTNO
             WHERE GL.VALUE_DATE BETWEEN PDATE1 AND PDATE2
               AND GL.AMOUNT_LOC > 0
               AND BÖLGÜ IN ('Hüquqi şəxslər_t')
               AND GL.BRANCH = DECODE(PBRANCH, '%', GL.BRANCH, PBRANCH)
        )
        SELECT VALUE_DATE,
               BRANCH,
               SUBLEDGER,
               ACCOUNT_ID,
               ACC_NAME1,
               CUST_NAME1,
               COR_ACC_SUBLEDER,
               COR_ACC_ID,
               ACC_NAME2,
               CUST_NAME2,
               CURRENCY_NO,
               AMOUNT_CUR,
               AMOUNT_LOC,
               CLASS_OP,
               HEADER_NO,
               REMARKS,
               CREATED_BY,
               INN_1,
               INN_2
          FROM GL
         WHERE EXISTS (SELECT 1
                         FROM RS.CUSTOMERS_EMPLOYERS CC
                        WHERE CC.COMP_FACTORING_ACCOUNT = GL.COR_ACC_ID
                          AND CC.EMP_COMPANY_BRANCH = GL.BRANCH)
           AND EXISTS (SELECT 1
                         FROM RS.CUSTOMERS_EMPLOYERS CC
                        WHERE CC.EMP_COMPANY_CUST_NO = GL.CUSTOMER_NO
                          AND CC.EMP_COMPANY_BRANCH = GL.BRANCH);


        INSERT INTO CBDD_TIBCO.RNM_SAL_OPS_COM_RES (
            VALUE_DATE, BRANCH, SUBLEDGER, ACCOUNT_ID, ACC_NAME1, CUST_NAME1,
            INN_1, COR_ACC_SUBLEDER, COR_ACC_ID, ACC_NAME2, CUST_NAME2,
            CURRENCY_NO, AMOUNT_CUR, AMOUNT_LOC, CLASS_OP, COM_AMOUNT,
            REMARKS, CREATED_BY, HEADER_NO
        )
        SELECT R.VALUE_DATE,
               R.BRANCH,
               R.SUBLEDGER,
               R.ACCOUNT_ID,
               R.ACC_NAME1,
               R.CUST_NAME1,
               R.INN_1,
               R.COR_ACC_SUBLEDER,
               R.COR_ACC_ID,
               R.ACC_NAME2,
               R.CUST_NAME2,
               R.CURRENCY_NO,
               R.AMOUNT_CUR,
               R.AMOUNT_LOC,
               R.CLASS_OP,
               (SELECT SUM(AMOUNT_LOC)
                  FROM RS.GL_ENTRIES_CORPORATE G
                 WHERE G.HEADER_NO = R.HEADER_NO
                   AND G.BRANCH = R.BRANCH
                   AND G.COR_ACC_SUBLEDER = 67017) COM_AMOUNT,
               R.REMARKS,
               R.CREATED_BY,
               R.HEADER_NO
          FROM CBDD_TIBCO.RNM_SAL_OPS$TT R;

    END IF;


    INSERT INTO CBDD_TIBCO.REPORTS_USAGE_LOGS
    VALUES (
        'RNM_026_SAL_OPS_COM',
        V_STARTED,
        SYSDATE,
        TO_CHAR(PDATE1, 'dd.mm.yy') || ';' || TO_CHAR(PDATE2, 'dd.mm.yy') || ';' || PUSER || ';' || PBRANCH,
        'OK'
    );

    COMMIT;
    DBMS_APPLICATION_INFO.SET_ACTION('');

EXCEPTION
    WHEN OTHERS THEN
        V_LOG_DESC := 'Error message: ' || SQLERRM;

        -- Xəta loglanması
        INSERT INTO CBDD_TIBCO.REPORTS_USAGE_LOGS
        VALUES (
            'RNM_026_SAL_OPS_COM',
            V_STARTED,
            SYSDATE,
            TO_CHAR(PDATE1, 'dd.mm.yy') || ';' || TO_CHAR(PDATE2, 'dd.mm.yy') || ';' || PUSER || ';' || PBRANCH,
            V_LOG_DESC
        );

        COMMIT;
        RAISE;
END RNM_026_SAL_OPS_COM_PRC;
