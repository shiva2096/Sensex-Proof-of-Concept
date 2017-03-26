#Input File Detail
inputFileName=Poc2InputData.pdf
#Variables Used
mysqlDbName=SensexDb
mysqlTableName=sensex_tab
hiveDbName=sensex_db
hiveTableName=sensex_tab
#Input and Output HDFS Location Names
InputPdfLocation=/Poc2Input
MRLogLocation=/SensexLog
MROutputLocation=/SensexOut
PigDistinctOutputLocation=/PigDistinctPoc2
PigSortOutputLocation=/PigSortPoc2
#Mysql Connection Details
mysqlUser=root
mysqlPass=root

#Code Starts From Here
########################################################################################################

#Removing HDFS Directories
hadoop fs -rmr $PigDistinctOutputLocation $PigSortOutputLocation $InputPdfLocation

#Placing Input Pdf File On HDFS 
hadoop fs -mkdir $InputPdfLocation
hadoop fs -put $inputFileName $InputPdfLocation

#Running MapReduce Job
hadoop jar PdfProcessing.jar com/sensex/poc/PdfDriver $InputPdfLocation/$inputFileName $MRLogLocation $MROutputLocation

#Running Pig Script
pig -p Input=$MROutputLocation/* -p DistinctLoc=$PigDistinctOutputLocation -p SortLoc=$PigSortOutputLocation PocSensex.pig

#Creating MySql Table
mysql -u $mysqlUser -p$mysqlPass << EOF
drop database if exists $mysqlDbName;
create database $mysqlDbName;
create table $mysqlDbName.$mysqlTableName(
sid int PRIMARY KEY,
sname varchar(20),
strade varchar(20),
sloc varchar(20),
sopen int,
sclose int,
sfluc int);
grant all privileges on $mysqlDbName.* to ''@'localhost';
EOF

#Exporting Pig Output to MySql Table
sqoop export --connect jdbc:mysql://localhost/$mysqlDbName --table $mysqlTableName --fields-terminated-by '\t' --export-dir $PigSortOutputLocation/part*;

#Exporting Pig Output To Hive Table
hive << EOF
drop database if exists $hiveDbName cascade;
create database $hiveDbName;
create external table $hiveDbName.$hiveTableName(sid int,sname string,strade string,sloc string,sopen int,sclose int,sfluc int)
row format delimited
fields terminated by '\t'
lines terminated by '\n'
stored as textfile location '$PigSortOutputLocation';
EOF
