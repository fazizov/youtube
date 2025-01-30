With getStreamingProgress AS (
select queryName,batchId, inputRowsPerSecond, processedRowsPerSecond,
 inputRowsPerSecond-processedRowsPerSecond  as backlogRowsPerSecond  
 from streaming_monitor),
getPreviousBacklog AS (
select queryName,batchId, inputRowsPerSecond, processedRowsPerSecond, backlogRowsPerSecond, 
lag(backlogRowsPerSecond,1) over (order by batchId) as previous_backlogRowsPerSecond
from getStreamingProgress where queryName='iot_measurements')
select * from getPreviousBacklog where  
backlogRowsPerSecond>0 and 
backlogRowsPerSecond > previous_backlogRowsPerSecond
order by  BatchId
