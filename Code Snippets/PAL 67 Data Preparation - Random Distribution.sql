SET SCHEMA PAL;

-- cleanup
DROP TYPE PAL_T_RD_DIST;
DROP TYPE PAL_T_RD_PARAMS;
DROP TYPE PAL_T_RD_RESULTS;
DROP TABLE PAL_RD_SIGNATURE;
CALL SYSTEM.AFL_WRAPPER_ERASER ('PAL_RD');
DROP TABLE RD_RESULTS;

-- PAL setup
CREATE TYPE PAL_T_RD_DIST AS TABLE (NAME VARCHAR(60), VALUE VARCHAR(60));
CREATE TYPE PAL_T_RD_PARAMS AS TABLE (NAME VARCHAR(60), INTARGS INTEGER, DOUBLEARGS DOUBLE, STRINGARGS VARCHAR (100));
CREATE TYPE PAL_T_RD_RESULTS AS TABLE (ID INTEGER, VALUE DOUBLE);

CREATE COLUMN TABLE PAL_RD_SIGNATURE (ID INTEGER, TYPENAME VARCHAR(100), DIRECTION VARCHAR(100));
INSERT INTO PAL_RD_SIGNATURE VALUES (1, 'PAL.PAL_T_RD_DIST', 'in');
INSERT INTO PAL_RD_SIGNATURE VALUES (2, 'PAL.PAL_T_RD_PARAMS', 'in');
INSERT INTO PAL_RD_SIGNATURE VALUES (3, 'PAL.PAL_T_RD_RESULTS', 'out');

GRANT SELECT ON PAL_RD_SIGNATURE TO SYSTEM;
CALL SYSTEM.AFL_WRAPPER_GENERATOR ('PAL_RD', 'AFLPAL', 'DISTRRANDOM', PAL_RD_SIGNATURE);

-- app setup
CREATE COLUMN TABLE RD_RESULTS LIKE PAL_T_RD_RESULTS;

-- app runtime
DROP TABLE #RD_DIST;
CREATE LOCAL TEMPORARY COLUMN TABLE #RD_DIST LIKE PAL_T_RD_DIST;
INSERT INTO #RD_DIST VALUES ('DISTRIBUTIONNAME', 'UNIFORM'); -- uniform, normal, weibull, gamma
INSERT INTO #RD_DIST VALUES ('MIN', '0'); -- uniform
INSERT INTO #RD_DIST VALUES ('MAX', '1'); -- uniform
INSERT INTO #RD_DIST VALUES ('MEAN', '0'); -- normal
INSERT INTO #RD_DIST VALUES ('VARIANCE', '1'); -- normal
INSERT INTO #RD_DIST VALUES ('SHAPE', '1'); -- weibull, gamma
INSERT INTO #RD_DIST VALUES ('SCALE', '1'); -- weibull, gamma

DROP TABLE #RD_PARAMS;
CREATE LOCAL TEMPORARY COLUMN TABLE #RD_PARAMS LIKE PAL_T_RD_PARAMS;
INSERT INTO #RD_PARAMS VALUES ('THREAD_NUMBER', 2, null, null);
INSERT INTO #RD_PARAMS VALUES ('NUM_RANDOM', 200, null, null);
INSERT INTO #RD_PARAMS VALUES ('SEED', 0, null, null); -- 0: use system time as seed, otherwise specify seed explicitly

TRUNCATE TABLE RD_RESULTS;

CALL _SYS_AFL.PAL_RD (#RD_DIST, #RD_PARAMS, RD_RESULTS) WITH OVERVIEW;

SELECT * FROM RD_RESULTS;