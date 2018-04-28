----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Loading XML files into Hive Tables 
----------------------------------------------------------------------------------------------------------------------------------------------------------------
1. Download the XML SerDe from the below link
	XML serDe		:	https://github.com/dvasilen/Hive-XML-SerDe/wiki/XML-data-sources
	
	References		:	https://resources.zaloni.com/blog/xml-processing

2. Add the downloaded JAR file to hive session. Note this method will work only for the current session.
	
	add jar /mnt/home/adineskumar/Desktop/serDe/hivexmlserde-1.0.5.3.jar;
	
3. To make this permanent then do the following
	a.	Edit the $HIVE_HOME/lib/hive-site.xml
	
	 <property>
      <name>hive.aux.jars.path</name>
      <value>path of the JAR file</value>
     </property>
	
	b.	Then restart HiveServer2
	c. 	Use "ps –ef | grep hivexmlserde" to check if the hive process is running

3. Then you can use the XML SerDe to load XML files into hive tables as easily as the normal flat files.
	We will use the "US Treasury Auction" data for demonstration purpose
	You can download the data from the below link 
		https://www.treasurydirect.gov/xml/
		
4. The data will be looking something like

	<bpd:AuctionData xmlns:bpd="http://www.treasurydirect.gov/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.treasurydirect.gov/ http://www.treasurydirect.gov/xsd/Auction_v1_0_0.xsd">
		<AuctionAnnouncement>
			<SecurityTermWeekYear>26-WEEK</SecurityTermWeekYear>
			<SecurityTermDayMonth>182-DAY</SecurityTermDayMonth>
			<SecurityType>BILL</SecurityType>
			<CUSIP>912795G96</CUSIP>
			<AnnouncementDate>2008-04-03</AnnouncementDate>
			<AuctionDate>2008-04-07</AuctionDate>
			........
		</AuctionAnnouncement>
	
	So the XML Input Point will start at => <AuctionAnnouncement>  => START TAG
	So the XML Input Point will end at   => </AuctionAnnouncement> => END TAG
	
	Input format will be as 		=>	STORED AS INPUTFORMAT 'com.ibm.spss.hive.serde2.xml.XmlInputFormat'
	We will choose output format as =>	OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat'
	
	we can be able to access individual column as below 
		For Example :
			To access the tag =>	"<AnnouncementDate>2008-04-03</AnnouncementDate>" we could something like <ROOT>/<COLUMN>/text()
			
			ROW FORMAT SERDE 'com.ibm.spss.hive.serde2.xml.XmlSerDe'
			WITH SERDEPROPERTIES (	"column.xpath.announcedate"="/AuctionAnnouncement/AnnouncementDate/text()" )
			
	Suppose if the XML file format looks something like =>	"<AuctionAnnouncement ID=”ABCD” Security=”EFGH” .../>"
	Then still we are able to extract data using the SERDE 
	
			ROW FORMAT SERDE 'com.ibm.spss.hive.serde2.xml.XmlSerDe'
			WITH SERDEPROPERTIES (	"column.xpath.announcedate"="/AuctionAnnouncement/AnnouncementDate/@ID" )
			
	The same goes for defining Map, Array and Struct datatypes; using a wildcard in your XPath can select an entire tag, along with any subtags, 
	as a single field, which can then be mapped with native Hive types. 
	
5. Creating a HIVE table to load XML files 	
	CREATE TABLE dinesh.xml_auctions
	(
		auctionDate string,
		maturityDate string,
		maturityAmt double 
	 )
	ROW FORMAT SERDE 'com.ibm.spss.hive.serde2.xml.XmlSerDe'
	WITH SERDEPROPERTIES (
							"column.xpath.auctionDate"="/AuctionAnnouncement/AuctionDate/text()",
							"column.xpath.maturityDate"="/AuctionAnnouncement/MaturityDate/text()",
							"column.xpath.maturityAmt"="/AuctionAnnouncement/MatureSecurityAmount/text()"
						)
	STORED AS 
	INPUTFORMAT 'com.ibm.spss.hive.serde2.xml.XmlInputFormat'
	OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat'
	TBLPROPERTIES ( 
	"xmlinput.start"="<AuctionAnnouncement",
	"xmlinput.end"="</AuctionAnnouncement>"
	);

6. Loading data into the above table from the LOCAL
	LOAD DATA LOCAL INPATH '/mnt/home/adineskumar/Desktop/datasets/A_20080403_1.xml' OVERWRITE INTO TABLE dinesh.xml_auctions;
	
7. Then you will be Query like as a normal table in hive.