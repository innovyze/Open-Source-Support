# Export the field values in UPPERCASE (.upcase) / LOWERCASE (.downcase)

class Exporter
       def Exporter.UpperSystemType(obj)
              return obj['system_type'].upcase
       end
       
       def Exporter.UpperNodeType(obj)
              return obj['node_type'].upcase
       end
       
       def Exporter.UpperStatus(obj)
              return obj['status'].downcase
       end
end