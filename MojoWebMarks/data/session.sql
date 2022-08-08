use dcoda_acme;
CREATE TABLE session (
        appl varchar(20),
        sessionid varchar(25) PRIMARY KEY,  
        userid char(25),
        username char(35),
        DATE_TS datetime,
        UPDATE_TS datetime,
        rowcount int(1),
        sort varchar(25),
        SESSIONDATA varchar(15000)
);
