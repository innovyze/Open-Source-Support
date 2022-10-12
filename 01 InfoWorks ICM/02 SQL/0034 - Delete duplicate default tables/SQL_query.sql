UPDATE ALL [Shape] SET $default_shapes = 1 WHERE shape_id = 'ARCH'
OR shape_id = 'ARCHSPRUNG'
OR shape_id = 'CIRC'
OR shape_id = 'CNET'
OR shape_id = 'EGG'
OR shape_id = 'EGG2'
OR shape_id = 'OEGB'
OR shape_id = 'OEGN'
OR shape_id = 'OREC'
OR shape_id = 'OT1:1'
OR shape_id = 'OT1:2'
OR shape_id = 'OT1:4'
OR shape_id = 'OT1:6'
OR shape_id = 'OT2:1'
OR shape_id = 'OT4:1'
OR shape_id = 'OU'
OR shape_id = 'OVAL'
OR shape_id = 'RECT'
OR shape_id = 'UTOP';

UPDATE ALL [Headloss Curve] SET $default_headloss = 1 WHERE headloss_type = 'NONE'
OR headloss_type = 'NORMAL'
OR headloss_type = 'HIGH'
OR headloss_type = 'FIXED'
OR headloss_type = 'FHWA';

UPDATE ALL [Sediment grading] SET $default_sediment = 1 WHERE grading_id = 'Default';

DELETE ALL FROM [Shape] WHERE $default_shapes <> 1;
DELETE ALL FROM [Headloss Curve] WHERE $default_headloss <> 1;
DELETE ALL FROM [Sediment grading] WHERE $default_sediment <> 1;