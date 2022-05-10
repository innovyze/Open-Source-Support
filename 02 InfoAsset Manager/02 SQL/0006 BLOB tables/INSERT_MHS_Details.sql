INSERT INTO [Manhole Survey].details (id,details.distance,details.code)
SELECT oid,'0.0','MHS' WHERE count(details.code)=0