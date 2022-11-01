UPDATE ALL [Shape] SET $duplicate_shapes = 1
WHERE shape_id LIKE 'ARCH?*'
OR shape_id LIKE 'ARCHSPRUNG?*'
OR shape_id LIKE 'CIRC?*'
OR shape_id LIKE 'CNET?*'
OR shape_id LIKE 'EGG?*'
OR shape_id LIKE 'EGG2?*'
OR shape_id LIKE 'OEGB?*'
OR shape_id LIKE 'OEGN?*'
OR shape_id LIKE 'OREC?*'
OR shape_id LIKE 'OT1:1?*'
OR shape_id LIKE 'OT1:2?*'
OR shape_id LIKE 'OT1:4?*'
OR shape_id LIKE 'OT1:6?*'
OR shape_id LIKE 'OT2:1?*'
OR shape_id LIKE 'OT4:1?*'
OR shape_id LIKE 'OU?*'
OR shape_id LIKE 'OVAL?*'
OR shape_id LIKE 'RECT?*'
OR shape_id LIKE 'UTOP?*'
AND shape_type = 'Builtin'
;

UPDATE ALL [Headloss Curve] SET $duplicate_headloss = 1
WHERE headloss_type LIKE 'NONE?*'
OR headloss_type LIKE 'NORMAL?*'
OR headloss_type LIKE 'HIGH?*'
OR headloss_type LIKE 'FIXED?*'
OR headloss_type LIKE 'FHWA?*'
AND curve_type = 'Builtin'
;

UPDATE ALL [Sediment grading] SET $duplicate_sediment = 1
WHERE grading_id LIKE 'Default?*'
AND grading_type = 'Builtin'
;

DELETE ALL FROM [Shape] WHERE $duplicate_shapes = 1;
DELETE ALL FROM [Headloss Curve] WHERE $duplicate_headloss = 1;
DELETE ALL FROM [Sediment grading] WHERE $duplicate_sediment = 1;