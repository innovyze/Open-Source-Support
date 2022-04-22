/*Find where there are Links with the same ID as each other - as there are mulitple Link object types, a Link ID can be a duplicate between the different object tables.
//Object Type: All Links
//Spatial Search: blank
*/


SELECT COUNT(*) GROUP BY oid HAVING COUNT(*)>1