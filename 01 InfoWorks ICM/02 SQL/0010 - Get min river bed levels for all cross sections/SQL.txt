SELECT Min(Min(sections.z)) DP 3
GROUP BY oid,sections.key
ORDER BY sections.key*1 ASC