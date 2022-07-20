-- #use Acme_octagonyel937919;
-- use Widgets;
use dcoda_acme;

CREATE TABLE IF NOT EXISTS `WM_BOOKMARK` (
  `BOOKMARK_ID` mediumint(8) unsigned NOT NULL,
  `USER_ID` varchar(15)  NOT NULL,
  `PLACE_ID` mediumint(8) unsigned NOT NULL,
  `TYPE` tinyint(3) unsigned DEFAULT NULL,
  `TITLE` varchar(255) DEFAULT NULL,
  `KEYWORD_ID` smallint(5) unsigned DEFAULT NULL,
  `FOLDER_TYPE` text,
  `DATEADDED` bigint(20) unsigned DEFAULT NULL,
  `DATE_ADDED` datetime DEFAULT NULL,
  `LASTMODIFIED` bigint(20) unsigned DEFAULT NULL,
  `SHAREABLE` boolean  DEFAULT FALSE,
  `DELETED` boolean DEFAULT FALSE,
  PRIMARY KEY (`BOOKMARK_ID`),
  KEY `WM_BOOKMARKS_ITEMINDEX` (`PLACE_ID`,`TYPE`),
  KEY `WM_BOOKMARKS_ITEMLASTMODIFIEDINDEX` (`PLACE_ID`,`LASTMODIFIED`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

