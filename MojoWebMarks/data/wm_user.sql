-- #use Acme_octagonyel937919;
-- use Widgets;
use dcoda_acme;

CREATE TABLE IF NOT EXISTS `WM_USER` (
  `USER_ID` varchar(15) NOT NULL,
  `USER_NAME` varchar(15) NOT NULL,
  `USER_PASSWD` varchar(25) NOT NULL,
  `FNAME` varchar(25) DEFAULT NULL,
  `LNAME` varchar(25) DEFAULT NULL,
  `ADDRESS1` varchar(25) DEFAULT NULL,
  `ADDRESS2` varchar(25) DEFAULT NULL,
  `ZIP_CODE` decimal(5,0) DEFAULT NULL,
  `PHONE` decimal(10,0) DEFAULT NULL,
  `EMAIL_ADDRESS` varchar(50) DEFAULT NULL,
  `STATE` varchar(20) DEFAULT NULL,
  `CITY` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`USER_NAME`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
