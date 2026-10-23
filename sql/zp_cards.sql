CREATE OR REPLACE FUNCTION zp_cards
    (PDATE1 IN DATE, PDATE2 IN DATE)
    RETURN SYS_REFCURSOR
IS
    result_cursor   SYS_REFCURSOR;
    V_STARTED       DATE;
    V_LOG_DESC      VARCHAR2(500);
BEGIN
    V_STARTED := SYSDATE;

    
    OPEN result_cursor FOR
    SELECT pc2.card_order_no AS no,
           pc2.acnt_id,
           pc2.card_id,
           pc2.branch,
           pc2.customer_no,
           pc2.card_prod_type_descr AS c_type,
           CASE
               WHEN LOWER(pc2.card_prod_type_descr) LIKE '%edu%' THEN 'edu'
               ELSE 'zp'
           END AS tip,
           pc2.charge_descr AS charge,
           pc2.issue_date,
           pc2.expired_date_for_pl_cards AS expired_date,
           pc2.agreement_closed AS closed,
           pc2.currency_code AS cur_code,
           pc2.currency,
           pc2.card_limit_vabank AS credit_limit,
           pc2.company_name AS company_code,
           pc2.company_tax_number AS c_tax_number,
           CASE
               WHEN pc3.card_type = 'DB' THEN '?????????'
               WHEN pc3.card_type = 'CR' THEN '?????????'
               WHEN pc3.card_type = 'SALARY' THEN 'SALARY'
           END AS card_type,
           pc.card_status_descr AS card_status,
           pc2.corporation,
           pc2.agreement_inserted_by AS inserted_by,
           pc2.card_risk_level_vabank AS risk_level,
           pc2.cr_agr_no,
           pc2.card_prod_type AS prod_type,
           pc2.free_card_order_reason,
           pc2.free_card_order_comment,
           pc2.personalized_by,
           pc2.personalized_date,
           pc2.cnf_staus_descr,
           pc2.clientno
    FROM bank.fm_abbreviation@standby.unibank.lan f
    INNER JOIN rs.pc_agreements pca
        ON (pca.branch = f.code AND pca.issue_date <= PDATE1 AND f.fds_key = 1127)
    INNER JOIN rs.pc_card pc
        ON (pc.branch = pca.branch AND pc.card_order_no = pca.card_order_no)
    INNER JOIN rs.card_info_dict pc2
        ON (pc.branch = pc2.branch AND pc.card_id = pc2.card_id)
    LEFT JOIN rs.card_type pc3
        ON (pc2.branch = pc3.branch AND pc2.card_id = pc3.card_id)
    WHERE (CASE
               WHEN (pc.card_status = '000' AND pc.expired_date > PDATE2)
                    AND (pca.closed IS NULL OR pca.closed > PDATE2) THEN '1'
               ELSE '2'
           END) LIKE '1'
    AND pc3.card_type = 'SALARY';

    
    INSERT INTO CBDD_TIBCO.REPORTS_USAGE_LOGS
             VALUES (
                        'zp_cards',
                        V_STARTED,
                        SYSDATE,
                        TO_CHAR(PDATE1, 'dd.mm.yyyy') || ';' || TO_CHAR(PDATE2, 'dd.mm.yyyy'),
                        'OK');

    COMMIT;

    RETURN result_cursor;

EXCEPTION
    WHEN OTHERS
    THEN
        V_LOG_DESC := 'Error message: ' || SQLERRM;

        
        INSERT INTO CBDD_TIBCO.REPORTS_USAGE_LOGS
                 VALUES (
                            'zp_cards',
                            V_STARTED,
                            SYSDATE,
                            TO_CHAR(PDATE1, 'dd.mm.yyyy') || ';' || TO_CHAR(PDATE2, 'dd.mm.yyyy'),
                            V_LOG_DESC);

        COMMIT;
END zp_cards;
