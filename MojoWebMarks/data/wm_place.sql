-- #use Acme_octagonyel937919;
-- use Widgets;
use dcoda_acme;

CREATE TABLE IF NOT EXISTS `WM_PLACE` (
  `PLACE_ID` mediumint(8) unsigned NOT NULL,
  `URL` varchar(255) DEFAULT NULL,
  `TYPE` tinyint(3) unsigned DEFAULT NULL,
  `TITLE` varchar(255) DEFAULT NULL,
  `REV_HOST` varchar(255) DEFAULT NULL,
  `VISIT_COUNT` tinyint(3) unsigned DEFAULT '0',
  `FREQUENCY` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `LAST_VISIT_DATE` tinyint(3) unsigned DEFAULT NULL,
  PRIMARY KEY (`PLACE_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

