INSERT INTO subcatchment.suds_controls (
  subcatchment_id,
  suds_controls.id,
  suds_controls.control_type,
  suds_controls.area
)
SELECT
  oid,
  "1",
  "LivingRoofs(Retrofit)",
  total_area * 7600
FROM Subcatchment