SET SCHEMA PAL;

-- PAL setup

CREATE TYPE PAL_AP_T_DATA AS TABLE ("CUSTOMERID" INT, "PRODUCTID" INT);
CREATE TYPE PAL_AP_T_PARAMS AS TABLE (NAME VARCHAR(60), INTARGS INTEGER, DOUBLEARGS DOUBLE, STRINGARGS VARCHAR (100));
CREATE TYPE PAL_AP_T_RULES AS TABLE ("PRERULE" VARCHAR(500), "POSTRULE" VARCHAR(500), "SUPPORT" DOUBLE, "CONFIDENCE" DOUBLE, "LIFT" DOUBLE);
CREATE TYPE PAL_AP_T_PMML AS TABLE ("ID" INT, "PMMLMODEL" VARCHAR(5000));

CREATE COLUMN TABLE PAL_AP_SIGNATURE (ID INTEGER, TYPENAME VARCHAR(100), DIRECTION VARCHAR(100));
INSERT INTO PAL_AP_SIGNATURE VALUES (1, 'PAL.PAL_AP_T_DATA', 'in');
INSERT INTO PAL_AP_SIGNATURE VALUES (2, 'PAL.PAL_AP_T_PARAMS', 'in');
INSERT INTO PAL_AP_SIGNATURE VALUES (3, 'PAL.PAL_AP_T_RULES', 'out');
INSERT INTO PAL_AP_SIGNATURE VALUES (4, 'PAL.PAL_AP_T_PMML', 'out');

CALL SYSTEM.AFL_WRAPPER_GENERATOR ('PAL_AP_L', 'AFLPAL', 'LITEAPRIORIRULE', PAL_AP_SIGNATURE);

-- app setup

CREATE VIEW V_AP_DATA AS 
	SELECT "CUSTOMERID", "PRODUCTID" 
		FROM FCTCUSTOMERORDER 
		ORDER BY "ORDERID", "PRODUCTID"
	;
CREATE COLUMN TABLE AP_PARAMS LIKE PAL_AP_T_PARAMS;
CREATE COLUMN TABLE AP_RULES LIKE PAL_AP_T_RULES;
CREATE COLUMN TABLE AP_PMML LIKE PAL_AP_T_PMML;

INSERT INTO AP_PARAMS VALUES ('MIN_SUPPORT', null, 0.001, null);
INSERT INTO AP_PARAMS VALUES ('MIN_CONFIDENCE', null, 0.001, null);
INSERT INTO AP_PARAMS VALUES ('THREAD_NUMBER', 2, null, null);
INSERT INTO AP_PARAMS VALUES ('MAX_ITEM_LENGTH', 10, null, null);
INSERT INTO AP_PARAMS VALUES ('PMML_EXPORT', 0, null, null);
INSERT INTO AP_PARAMS VALUES ('OPTIMIZATION_TYPE', 0, null, null);
INSERT INTO AP_PARAMS VALUES ('IS_RECALCULATE', 0, null, null);

CREATE VIEW V_AP_RULES AS
 SELECT "PRERULE" || ' => ' || "POSTRULE" AS "RULE", 
		ROUND("SUPPORT", 4) AS "SUPPORT", 
		ROUND("CONFIDENCE", 4) AS "CONFIDENCE", 
		ROUND("LIFT", 4) AS "LIFT"
  FROM AP_RULES
 ;

-- app runtime

UPDATE AP_PARAMS SET DOUBLEARGS=0.001 WHERE NAME='MIN_SUPPORT';
UPDATE AP_PARAMS SET DOUBLEARGS=0.001 WHERE NAME='MIN_CONFIDENCE';
UPDATE AP_PARAMS SET INTARGS=0 WHERE NAME='PMML_EXPORT';
UPDATE AP_PARAMS SET INTARGS=1, DOUBLEARGS=0.7 WHERE NAME='OPTIMIZATION_TYPE';

TRUNCATE TABLE AP_RULES;
TRUNCATE TABLE AP_PMML;

CALL _SYS_AFL.PAL_AP_L (V_AP_DATA, AP_PARAMS, AP_RULES, AP_PMML) WITH OVERVIEW;
