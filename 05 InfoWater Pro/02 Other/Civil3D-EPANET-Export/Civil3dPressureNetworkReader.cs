using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Reflection;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.Civil.ApplicationServices;

namespace Civil3dEpanetExport
{
    internal static class Civil3dPressureNetworkReader
    {
        public static Action<string> LogSink { get; set; }
        public static bool DiagnosticsEnabled { get; set; }

        private static void Log(string message)
        {
            LogSink?.Invoke(message);
        }
        public static void DumpPipeDiagnostics(Editor editor, string pipeNameContains)
        {
            if (editor == null)
            {
                throw new ArgumentNullException(nameof(editor));
            }

            if (!DiagnosticsEnabled)
            {
                editor.WriteMessage("\nDiagnostics are disabled. Enable to run diagnostic dumps.");
                return;
            }

            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null)
            {
                return;
            }

            var db = doc.Database;

            using (var transaction = db.TransactionManager.StartTransaction())
            {
                var pipeIds = TryGetPressurePipeIdsFromModelSpace(db, transaction, editor).ToList();
                if (!pipeIds.Any())
                {
                    editor.WriteMessage("\nDiagnostics: no pressure pipes found in model space.");
                    return;
                }

                foreach (var pipeId in pipeIds)
                {
                    var pipeObj = transaction.GetObject(pipeId, OpenMode.ForRead, false);
                    if (pipeObj == null)
                    {
                        continue;
                    }

                    var name = GetStringProperty(pipeObj, "Name", "PartName", "Description") ?? string.Empty;
                    if (name.IndexOf(pipeNameContains, StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        continue;
                    }

                    editor.WriteMessage($"\nDiagnostics for pipe: {name}");
                    DumpPointProperties(pipeObj, editor);
                    DumpObjectIdProperties(pipeObj, editor);
                    DumpCurveProperties(pipeObj, editor);
                    return;
                }

                editor.WriteMessage($"\nDiagnostics: pipe containing '{pipeNameContains}' not found.");
            }
        }
        public static EpanetModel ReadModel(Editor editor)
        {
            if (editor == null)
            {
                throw new ArgumentNullException(nameof(editor));
            }

            var model = new EpanetModel();
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null)
            {
                return model;
            }

            var db = doc.Database;
            var civilDoc = CivilApplication.ActiveDocument;
            var networkIds = GetPressureNetworkIds(civilDoc, db, editor).ToList();

            if (!networkIds.Any())
            {
                editor.WriteMessage("\nNo pressure pipe networks found. Scanning model space for pressure pipes...");
                Log("No pressure pipe networks found. Scanning model space for pressure pipes...");
                using (var transaction = db.TransactionManager.StartTransaction())
                {
                    var pipeIds = TryGetPressurePipeIdsFromModelSpace(db, transaction, editor).ToList();
                    if (!pipeIds.Any())
                    {
                        editor.WriteMessage("\nNo pressure pipes found in model space.");
                        Log("No pressure pipes found in model space.");
                        return model;
                    }

                    var fittingIds = TryGetPressureFittingIdsFromModelSpace(db, transaction, editor).ToList();
                    var appurtenanceIds = TryGetPressureAppurtenanceIdsFromModelSpace(db, transaction, editor).ToList();
                    var junctionIndexLocal = 1;
                    var junctionMapLocal = new Dictionary<CoordinateKey, string>();
                    var junctionPointsLocal = new Dictionary<string, Point3d>();
                    var fittingIdByCoordLocal = new Dictionary<CoordinateKey, string>();
                    var nodeIdMapLocal = new Dictionary<ObjectId, string>();
                    editor.WriteMessage($"\nFound {pipeIds.Count} pressure pipes in model space.");
                    Log($"Found {pipeIds.Count} pressure pipes in model space.");
                    ReadFittingsFromIds(fittingIds, transaction, model, editor, junctionMapLocal, junctionPointsLocal, fittingIdByCoordLocal, nodeIdMapLocal, ref junctionIndexLocal);
                    ReadPipesFromIds(pipeIds, transaction, model, editor, junctionMapLocal, junctionPointsLocal, fittingIdByCoordLocal, nodeIdMapLocal, ref junctionIndexLocal);
                    ReadValvesFromIds(appurtenanceIds, transaction, model, editor, junctionMapLocal, junctionPointsLocal, fittingIdByCoordLocal, ref junctionIndexLocal);
                    transaction.Commit();
                }

                RemoveUnreferencedJunctions(model);
                editor.WriteMessage(
                    $"\nExported: {model.Pipes.Count} pipes, {model.Junctions.Count} junctions, {model.Valves.Count} valves.");
                Log($"Exported: {model.Pipes.Count} pipes, {model.Junctions.Count} junctions, {model.Valves.Count} valves.");
                LogOriginJunctions(editor, model);
                return model;
            }

            editor.WriteMessage($"\nFound {networkIds.Count} pressure pipe network(s).");
            Log($"Found {networkIds.Count} pressure pipe network(s).");

            var junctionIndex = 1;
            var junctionMap = new Dictionary<CoordinateKey, string>();
            var junctionPoints = new Dictionary<string, Point3d>();
            var fittingIdByCoord = new Dictionary<CoordinateKey, string>();
            var nodeIdMap = new Dictionary<ObjectId, string>();

            using (var transaction = db.TransactionManager.StartTransaction())
            {
                foreach (var networkId in networkIds)
                {
                    var network = transaction.GetObject(networkId, OpenMode.ForRead, false);
                    if (network == null)
                    {
                        continue;
                    }

                    ReadFittings(network, transaction, model, editor, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex);
                    ReadPipes(network, transaction, model, editor, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex);
                    ReadValves(network, transaction, model, editor, junctionMap, junctionPoints, fittingIdByCoord, ref junctionIndex);
                }

                transaction.Commit();
            }

            RemoveUnreferencedJunctions(model);
            editor.WriteMessage(
                $"\nExported: {model.Pipes.Count} pipes, {model.Junctions.Count} junctions, {model.Valves.Count} valves.");
            Log($"Exported: {model.Pipes.Count} pipes, {model.Junctions.Count} junctions, {model.Valves.Count} valves.");
            LogOriginJunctions(editor, model);

            return model;
        }

        private static IEnumerable<ObjectId> GetPressureNetworkIds(CivilDocument civilDoc, Database database, Editor editor)
        {
            if (civilDoc == null)
            {
                yield break;
            }

            var ids = TryInvokeObjectIdCollection(civilDoc, "GetPressurePipeNetworkIds")
                      ?? TryInvokeObjectIdCollection(civilDoc, "GetPressureNetworkIds");

            if (ids != null)
            {
                foreach (ObjectId id in ids)
                {
                    if (!id.IsNull)
                    {
                        yield return id;
                    }
                }

                yield break;
            }

            var collection = TryGetPropertyValue(civilDoc, "PressurePipeNetworks")
                             ?? TryGetPropertyValue(civilDoc, "PressurePipeNetworkCollection")
                             ?? TryGetPropertyValue(civilDoc, "PressurePipeNetworkIds")
                             ?? TryGetPropertyValue(civilDoc, "PressureNetworks");

            foreach (var id in ExtractIds(collection, editor))
            {
                yield return id;
            }

            foreach (var id in TryGetIdsFromPressureNetworkType(database, editor))
            {
                yield return id;
            }
        }

        private static IEnumerable<ObjectId> TryGetIdsFromPressureNetworkType(Database database, Editor editor)
        {
            if (database == null)
            {
                yield break;
            }

            var typeNames = new[]
            {
                "Autodesk.Civil.DatabaseServices.PressurePipeNetwork, AeccPressurePipesMgd",
                "Autodesk.Civil.DatabaseServices.PressureNetwork, AeccPressurePipesMgd"
            };

            foreach (var typeName in typeNames)
            {
                var type = Type.GetType(typeName, false);
                if (type == null)
                {
                    continue;
                }

                foreach (var id in TryInvokeStaticIdMethod(type, database, editor))
                {
                    yield return id;
                }
            }
        }

        private static IEnumerable<ObjectId> TryInvokeStaticIdMethod(Type type, Database database, Editor editor)
        {
            var methods = type.GetMethods(BindingFlags.Public | BindingFlags.Static);
            foreach (var method in methods)
            {
                if (!method.Name.Contains("Pressure", StringComparison.OrdinalIgnoreCase) ||
                    !method.Name.Contains("Id", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var parameters = method.GetParameters();
                if (parameters.Length == 1 && parameters[0].ParameterType == typeof(Database))
                {
                    object result = null;
                    try
                    {
                        result = method.Invoke(null, new object[] { database });
                    }
                    catch
                    {
                        continue;
                    }

                    foreach (var id in ExtractIds(result, editor))
                    {
                        yield return id;
                    }
                }
            }
        }

        private static void ReadPipes(
            DBObject network,
            Transaction transaction,
            EpanetModel model,
            Editor editor,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            Dictionary<ObjectId, string> nodeIdMap,
            ref int junctionIndex)
        {
            var pipeIds = TryGetIds(network, editor,
                "PressurePipeIds",
                "PressurePipes",
                "PipeIds",
                "Pipes",
                "GetPressurePipeIds",
                "GetPipeIds")
                .Distinct()
                .ToList();

            if (!pipeIds.Any())
            {
                pipeIds = TryGetIdsByTypeName(network, editor, "PressurePipe")
                    .Distinct()
                    .ToList();

                if (pipeIds.Any())
                {
                    editor.WriteMessage($"\nResolved {pipeIds.Count} pipes using type-name fallback.");
                }
                else
                {
                    editor.WriteMessage("\nNo pressure pipes found on network using known members.");
                }
            }

            foreach (var pipeId in pipeIds)
            {
                var pipeObj = transaction.GetObject(pipeId, OpenMode.ForRead, false);
                if (pipeObj == null)
                {
                    continue;
                }

                if (!TryResolvePipeEndpoints(pipeObj, transaction, editor, out var start, out var end, out var startNodeObj, out var endNodeObj))
                {
                    continue;
                }

                var searchRadius = GetConnectionSearchRadius();
                string node1;
                if (startNodeObj != null)
                {
                    node1 = GetOrCreateJunctionFromNode(startNodeObj, start, model, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex);
                }
                else
                {
                    var nearbyStart = FindNearbyJunctionId(start, junctionPoints, searchRadius);
                    node1 = !string.IsNullOrWhiteSpace(nearbyStart)
                        ? nearbyStart
                        : GetOrCreateJunction(start, model, junctionMap, junctionPoints, fittingIdByCoord, ref junctionIndex);
                }

                string node2;
                if (endNodeObj != null)
                {
                    node2 = GetOrCreateJunctionFromNode(endNodeObj, end, model, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex);
                }
                else
                {
                    var nearbyEnd = FindNearbyJunctionId(end, junctionPoints, searchRadius);
                    node2 = !string.IsNullOrWhiteSpace(nearbyEnd)
                        ? nearbyEnd
                        : GetOrCreateJunction(end, model, junctionMap, junctionPoints, fittingIdByCoord, ref junctionIndex);
                }

                var length = GetPipeLength(pipeObj, start, end);

                var diameter = GetDoubleProperty(pipeObj, "InnerDiameter", "InsideDiameter", "NominalDiameter", "Diameter");
                var pipeOriginalId = GetStringProperty(pipeObj, "Name", "PartName", "Description");
                var pipeIdValue = SanitizeId(pipeOriginalId) ?? $"P{model.Pipes.Count + 1}";

                if (IsOriginPoint(start) || IsOriginPoint(end))
                {
                    LogPipeEndpointIssue(editor, pipeObj, pipeOriginalId ?? pipeIdValue, start, end);
                }

                if (diameter <= 0 || IsOriginLike(start, end))
                {
                    editor.WriteMessage($"\nSkipping pipe {pipeOriginalId ?? pipeIdValue}: invalid geometry or diameter.");
                    Log($"Skipping pipe {pipeOriginalId ?? pipeIdValue}: invalid geometry or diameter.");
                    continue;
                }

                model.Pipes.Add(new Pipe
                {
                    Id = pipeIdValue,
                    OriginalId = pipeOriginalId ?? pipeIdValue,
                    Node1 = node1,
                    Node2 = node2,
                    Length = length,
                    Diameter = diameter,
                    Roughness = 0.0,
                    MinorLoss = 0.0,
                    Status = "Open"
                });
            }
        }

        private static void ReadPipesFromIds(
            List<ObjectId> pipeIds,
            Transaction transaction,
            EpanetModel model,
            Editor editor,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            Dictionary<ObjectId, string> nodeIdMap,
            ref int junctionIndex)
        {

            foreach (var pipeId in pipeIds)
            {
                var pipeObj = transaction.GetObject(pipeId, OpenMode.ForRead, false);
                if (pipeObj == null)
                {
                    continue;
                }

                if (!TryResolvePipeEndpoints(pipeObj, transaction, editor, out var start, out var end, out var startNodeObj, out var endNodeObj))
                {
                    continue;
                }

                var searchRadius = GetConnectionSearchRadius();
                string node1;
                if (startNodeObj != null)
                {
                    node1 = GetOrCreateJunctionFromNode(startNodeObj, start, model, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex);
                }
                else
                {
                    var nearbyStart = FindNearbyJunctionId(start, junctionPoints, searchRadius);
                    node1 = !string.IsNullOrWhiteSpace(nearbyStart)
                        ? nearbyStart
                        : GetOrCreateJunction(start, model, junctionMap, junctionPoints, fittingIdByCoord, ref junctionIndex);
                }

                string node2;
                if (endNodeObj != null)
                {
                    node2 = GetOrCreateJunctionFromNode(endNodeObj, end, model, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex);
                }
                else
                {
                    var nearbyEnd = FindNearbyJunctionId(end, junctionPoints, searchRadius);
                    node2 = !string.IsNullOrWhiteSpace(nearbyEnd)
                        ? nearbyEnd
                        : GetOrCreateJunction(end, model, junctionMap, junctionPoints, fittingIdByCoord, ref junctionIndex);
                }

                var length = GetPipeLength(pipeObj, start, end);

                var diameter = GetDoubleProperty(pipeObj, "InnerDiameter", "InsideDiameter", "NominalDiameter", "Diameter");
                var pipeOriginalId = GetStringProperty(pipeObj, "Name", "PartName", "Description");
                var pipeIdValue = SanitizeId(pipeOriginalId) ?? $"P{model.Pipes.Count + 1}";

                if (IsOriginPoint(start) || IsOriginPoint(end))
                {
                    LogPipeEndpointIssue(editor, pipeObj, pipeOriginalId ?? pipeIdValue, start, end);
                }

                if (diameter <= 0 || IsOriginLike(start, end))
                {
                    editor.WriteMessage($"\nSkipping pipe {pipeOriginalId ?? pipeIdValue}: invalid geometry or diameter.");
                    Log($"Skipping pipe {pipeOriginalId ?? pipeIdValue}: invalid geometry or diameter.");
                    continue;
                }

                model.Pipes.Add(new Pipe
                {
                    Id = pipeIdValue,
                    OriginalId = pipeOriginalId ?? pipeIdValue,
                    Node1 = node1,
                    Node2 = node2,
                    Length = length,
                    Diameter = diameter,
                    Roughness = 0.0,
                    MinorLoss = 0.0,
                    Status = "Open"
                });
            }
        }

        private static void ReadFittingsFromIds(
            List<ObjectId> fittingIds,
            Transaction transaction,
            EpanetModel model,
            Editor editor,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            Dictionary<ObjectId, string> nodeIdMap,
            ref int junctionIndex)
        {
            foreach (var fittingId in fittingIds)
            {
                var fittingObj = transaction.GetObject(fittingId, OpenMode.ForRead, false);
                if (fittingObj == null)
                {
                    continue;
                }

                if (!TryGetPoint(fittingObj, out var location, "Location", "Position", "CenterPoint", "Point"))
                {
                    continue;
                }

                var fittingName = GetStringProperty(fittingObj, "Name", "PartName", "Description");
                GetOrCreateJunctionFromNode(fittingObj, location, model, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex, fittingName);
            }
        }

        private static void ReadFittings(
            DBObject network,
            Transaction transaction,
            EpanetModel model,
            Editor editor,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            Dictionary<ObjectId, string> nodeIdMap,
            ref int junctionIndex)
        {
            var fittingIds = TryGetIds(network, editor,
                "FittingIds",
                "PressureFittingIds",
                "Fittings",
                "PressureFittings",
                "GetFittingIds",
                "GetPressureFittingIds");

            foreach (var fittingId in fittingIds)
            {
                var fittingObj = transaction.GetObject(fittingId, OpenMode.ForRead, false);
                if (fittingObj == null)
                {
                    continue;
                }

                if (!TryGetPoint(fittingObj, out var location, "Location", "Position", "CenterPoint", "Point"))
                {
                    continue;
                }

                var fittingName = GetStringProperty(fittingObj, "Name", "PartName", "Description");
                GetOrCreateJunctionFromNode(fittingObj, location, model, junctionMap, junctionPoints, fittingIdByCoord, nodeIdMap, ref junctionIndex, fittingName);
            }
        }

        private static void ReadValves(
            DBObject network,
            Transaction transaction,
            EpanetModel model,
            Editor editor,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            ref int junctionIndex)
        {
            var appurtenanceIds = TryGetIds(network, editor,
                "AppurtenanceIds",
                "PressureAppurtenanceIds",
                "Appurtenances",
                "PressureAppurtenances",
                "GetAppurtenanceIds",
                "GetPressureAppurtenanceIds");

            foreach (var appId in appurtenanceIds)
            {
                var appObj = transaction.GetObject(appId, OpenMode.ForRead, false);
                if (appObj == null)
                {
                    continue;
                }

                if (!IsValve(appObj))
                {
                    continue;
                }

                if (!TryGetPoint(appObj, out var location, "Location", "Position", "CenterPoint", "Point"))
                {
                    continue;
                }

                var valveId = GetStringProperty(appObj, "Name", "PartName", "Description")
                              ?? $"V{model.Valves.Count + 1}";
                var valveIdBase = SanitizeId(valveId) ?? $"V{model.Valves.Count + 1}";
                var valveIdSanitized = EnsureUniqueValveId(model, valveIdBase);

                var valveType = GetStringProperty(appObj, "PartType", "ValveType", "PartName", "Name");
                if (string.IsNullOrWhiteSpace(valveType) || !IsEpanetValveType(valveType))
                {
                    valveType = "TCV";
                }

                var diameter = GetNominalDiameter(appObj);
                var description = GetStringProperty(appObj, "Description", "PartDescription", "LongDescription", "FullDescription");

                var upstreamId = EnsureUniqueJunctionId(model, $"{valveIdSanitized}_US");
                var downstreamId = EnsureUniqueJunctionId(model, $"{valveIdSanitized}_DS");

                CreateJunctionAtPoint(upstreamId, valveId + "_US", location, model, junctionMap, junctionPoints, fittingIdByCoord);
                CreateJunctionAtPoint(downstreamId, valveId + "_DS", location, model, junctionMap, junctionPoints, fittingIdByCoord);

                if (!RewirePipesForValve(location, upstreamId, downstreamId, model, junctionPoints))
                {
                    editor.WriteMessage($"\nValve {valveId}: unable to rewire pipes to US/DS nodes.");
                }

                model.Valves.Add(new Valve
                {
                    Id = valveIdSanitized,
                    OriginalId = valveId,
                    Description = description ?? string.Empty,
                    Node1 = upstreamId,
                    Node2 = downstreamId,
                    Diameter = diameter,
                    Type = valveType,
                    Setting = 0.0,
                    MinorLoss = 0.0,
                    Status = "Open"
                });
            }
        }

        private static void ReadValvesFromIds(
            List<ObjectId> appurtenanceIds,
            Transaction transaction,
            EpanetModel model,
            Editor editor,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            ref int junctionIndex)
        {
            var appCount = 0;
            var valveCount = 0;
            var sampleDescriptors = new List<string>();
            var sampleDetailsLogged = 0;

            foreach (var appId in appurtenanceIds)
            {
                var appObj = transaction.GetObject(appId, OpenMode.ForRead, false);
                if (appObj == null)
                {
                    continue;
                }

                appCount++;
                if (!IsValve(appObj))
                {
                    if (sampleDescriptors.Count < 10)
                    {
                        var desc = GetStringProperty(appObj, "Name", "PartName", "PartType", "Type", "Description") ?? appObj.GetType().Name;
                        sampleDescriptors.Add(desc);
                        if (sampleDetailsLogged < 3)
                        {
                            DumpStringProperties(appObj, editor);
                            sampleDetailsLogged++;
                        }
                    }
                    continue;
                }

                if (!TryGetPoint(appObj, out var location, "Location", "Position", "CenterPoint", "Point"))
                {
                    continue;
                }

                var valveId = GetStringProperty(appObj, "Name", "PartName", "Description")
                              ?? $"V{model.Valves.Count + 1}";
                var valveIdBase = SanitizeId(valveId) ?? $"V{model.Valves.Count + 1}";
                var valveIdSanitized = EnsureUniqueValveId(model, valveIdBase);

                var valveType = GetStringProperty(appObj, "PartType", "ValveType", "PartName", "Name");
                if (string.IsNullOrWhiteSpace(valveType) || !IsEpanetValveType(valveType))
                {
                    valveType = "TCV";
                }

                var diameter = GetNominalDiameter(appObj);
                var description = GetStringProperty(appObj, "Description", "PartDescription", "LongDescription", "FullDescription");

                var upstreamId = EnsureUniqueJunctionId(model, $"{valveIdSanitized}_US");
                var downstreamId = EnsureUniqueJunctionId(model, $"{valveIdSanitized}_DS");

                CreateJunctionAtPoint(upstreamId, valveId + "_US", location, model, junctionMap, junctionPoints, fittingIdByCoord);
                CreateJunctionAtPoint(downstreamId, valveId + "_DS", location, model, junctionMap, junctionPoints, fittingIdByCoord);

                if (!RewirePipesForValve(location, upstreamId, downstreamId, model, junctionPoints))
                {
                    editor.WriteMessage($"\nValve {valveId}: unable to rewire pipes to US/DS nodes.");
                    Log($"Valve {valveId}: unable to rewire pipes to US/DS nodes.");
                }

                model.Valves.Add(new Valve
                {
                    Id = valveIdSanitized,
                    OriginalId = valveId,
                    Description = description ?? string.Empty,
                    Node1 = upstreamId,
                    Node2 = downstreamId,
                    Diameter = diameter,
                    Type = valveType,
                    Setting = 0.0,
                    MinorLoss = 0.0,
                    Status = "Open"
                });

                valveCount++;
            }

            Log($"Appurtenances scanned: {appCount}, valves detected: {valveCount}");
            if (valveCount == 0 && sampleDescriptors.Any())
            {
                Log($"Appurtenance samples: {string.Join(" | ", sampleDescriptors)}");
            }
        }

        private static string GetOrCreateJunction(
            Point3d point,
            EpanetModel model,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            ref int junctionIndex,
            string preferredOriginalId = null)
        {
            var key = new CoordinateKey(point);
            if (junctionMap.TryGetValue(key, out var existingId))
            {
                return existingId;
            }

            if (preferredOriginalId == null && fittingIdByCoord.TryGetValue(key, out var mappedFittingId))
            {
                preferredOriginalId = mappedFittingId;
            }

            var sanitizedPreferred = SanitizeId(preferredOriginalId);
            var id = !string.IsNullOrWhiteSpace(sanitizedPreferred) && !IsReservedId(model, sanitizedPreferred)
                && !LooksLikePipeId(preferredOriginalId)
                ? sanitizedPreferred
                : $"J{junctionIndex++}";

            if (junctionPoints.ContainsKey(id))
            {
                id = $"{id}_{junctionIndex++}";
            }
            junctionMap[key] = id;
            junctionPoints[id] = point;

            if (!string.IsNullOrWhiteSpace(preferredOriginalId))
            {
                fittingIdByCoord[key] = preferredOriginalId;
            }

            model.Junctions.Add(new Junction
            {
                Id = id,
                OriginalId = preferredOriginalId ?? id,
                Elevation = point.Z,
                Demand = 0.0
            });

            model.Coordinates.Add(new Coordinate
            {
                Id = id,
                X = point.X,
                Y = point.Y
            });

            return id;
        }

        private static string GetOrCreateJunctionFromNode(
            DBObject nodeObj,
            Point3d point,
            EpanetModel model,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord,
            Dictionary<ObjectId, string> nodeIdMap,
            ref int junctionIndex,
            string preferredOriginalId = null)
        {
            if (nodeObj != null && nodeIdMap.TryGetValue(nodeObj.ObjectId, out var existingId))
            {
                return existingId;
            }

            var originalId = preferredOriginalId ?? GetStringProperty(nodeObj, "Name", "PartName", "Description");
            if (nodeObj != null)
            {
                var typeName = nodeObj.GetType().Name;
                if (typeName.IndexOf("PressurePipe", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    originalId = null;
                }
            }
            var id = GetOrCreateJunction(point, model, junctionMap, junctionPoints, fittingIdByCoord, ref junctionIndex, originalId);

            if (nodeObj != null)
            {
                nodeIdMap[nodeObj.ObjectId] = id;
            }

            return id;
        }

        private static bool IsReservedId(EpanetModel model, string candidate)
        {
            if (model == null || string.IsNullOrWhiteSpace(candidate))
            {
                return false;
            }

            return model.Pipes.Any(pipe => string.Equals(pipe.Id, candidate, StringComparison.OrdinalIgnoreCase))
                   || model.Valves.Any(valve => string.Equals(valve.Id, candidate, StringComparison.OrdinalIgnoreCase));
        }

        private static bool LooksLikePipeId(string originalId)
        {
            if (string.IsNullOrWhiteSpace(originalId))
            {
                return false;
            }

            return originalId.IndexOf("Pressure Pipe", StringComparison.OrdinalIgnoreCase) >= 0
                   || originalId.IndexOf("PressurePipe", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static bool TryGetPoint(DBObject obj, out Point3d point, params string[] propertyNames)
        {
            foreach (var name in propertyNames)
            {
                var value = TryGetPropertyValue(obj, name);
                if (value is Point3d pt)
                {
                    point = pt;
                    return true;
                }
            }

            point = Point3d.Origin;
            return false;
        }

        private static bool TryGetCurveEndpoints(DBObject obj, out Point3d start, out Point3d end)
        {
            start = Point3d.Origin;
            end = Point3d.Origin;

            var candidates = new[]
            {
                "Centerline",
                "CenterLine",
                "CenterlineGeometry",
                "CenterLineGeometry",
                "CenterlineCurve",
                "Curve",
                "Geometry",
                "Alignment",
                "Axis"
            };

            foreach (var name in candidates)
            {
                var value = TryGetPropertyValue(obj, name);
                if (value is Curve curve)
                {
                    start = curve.StartPoint;
                    end = curve.EndPoint;
                    return true;
                }
            }

            var methodCandidates = new[]
            {
                "GetCenterline",
                "GetCenterLine",
                "GetCurve",
                "GetGeometry",
                "GetAlignment"
            };

            foreach (var name in methodCandidates)
            {
                var method = obj.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.Public);
                if (method != null && method.GetParameters().Length == 0)
                {
                    var result = method.Invoke(obj, null);
                    if (result is Curve methodCurve)
                    {
                        start = methodCurve.StartPoint;
                        end = methodCurve.EndPoint;
                        return true;
                    }
                }
            }

            return false;
        }

        private static bool TryGetPointByNameContains(DBObject obj, string contains, out Point3d point)
        {
            var properties = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var property in properties)
            {
                if (property.PropertyType != typeof(Point3d))
                {
                    continue;
                }

                if (property.Name.IndexOf(contains, StringComparison.OrdinalIgnoreCase) < 0)
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = property.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    Log($"Point3d {property.Name} read error: {ex.Message}");
                    continue;
                }

                if (value is Point3d pt)
                {
                    point = pt;
                    return true;
                }
            }

            point = Point3d.Origin;
            return false;
        }

        private static bool TryResolvePipeEndpoints(
            DBObject pipeObj,
            Transaction transaction,
            Editor editor,
            out Point3d start,
            out Point3d end,
            out DBObject startNodeObj,
            out DBObject endNodeObj)
        {
            start = Point3d.Origin;
            end = Point3d.Origin;
            startNodeObj = null;
            endNodeObj = null;

            var pipeStart = Point3d.Origin;
            var pipeEnd = Point3d.Origin;
            _ = TryGetPoint(pipeObj, out pipeStart, "StartPoint", "StartPoint3d", "StartPoint3D", "Start", "StartLocation", "StartPosition");
            _ = TryGetPoint(pipeObj, out pipeEnd, "EndPoint", "EndPoint3d", "EndPoint3D", "End", "EndLocation", "EndPosition");

            if (TryGetConnectedNode(pipeObj, transaction, out startNodeObj,
                    "StartNode",
                    "StartNodeId",
                    "FromNode",
                    "FromNodeId",
                    "StartFitting",
                    "StartFittingId",
                    "StartPressureFitting",
                    "StartPressureFittingId",
                    "StartStructure",
                    "StartStructureId",
                    "StartNodeObjectId")
                && TryGetPoint(startNodeObj, out var startFromNode, "Location", "Position", "Point", "CenterPoint", "InsertionPoint"))
            {
                if (!IsOriginPoint(startFromNode))
                {
                    start = startFromNode;
                }
            }
            else if (!TryGetPoint(pipeObj, out start, "StartPoint", "StartPoint3d", "StartPoint3D", "Start", "StartLocation", "StartPosition")
                     && !TryGetPointByNameContains(pipeObj, "Start", out start)
                     && !TryGetCurveEndpoints(pipeObj, out start, out _))
            {
                start = Point3d.Origin;
            }

            if (TryGetConnectedNode(pipeObj, transaction, out endNodeObj,
                    "EndNode",
                    "EndNodeId",
                    "ToNode",
                    "ToNodeId",
                    "EndFitting",
                    "EndFittingId",
                    "EndPressureFitting",
                    "EndPressureFittingId",
                    "EndStructure",
                    "EndStructureId",
                    "EndNodeObjectId")
                && TryGetPoint(endNodeObj, out var endFromNode, "Location", "Position", "Point", "CenterPoint", "InsertionPoint"))
            {
                if (!IsOriginPoint(endFromNode))
                {
                    end = endFromNode;
                }
            }
            else if (!TryGetPoint(pipeObj, out end, "EndPoint", "EndPoint3d", "EndPoint3D", "End", "EndLocation", "EndPosition")
                     && !TryGetPointByNameContains(pipeObj, "End", out end)
                     && !TryGetCurveEndpoints(pipeObj, out _, out end))
            {
                end = Point3d.Origin;
            }

            if (IsOriginPoint(start) && !IsOriginPoint(pipeStart))
            {
                start = pipeStart;
            }

            if (IsOriginPoint(end) && !IsOriginPoint(pipeEnd))
            {
                end = pipeEnd;
            }

            if (IsOriginLike(start, end))
            {
                editor.WriteMessage($"\nSkipping pipe {pipeObj.ObjectId}: unresolved endpoints (origin).");
                return false;
            }

            return true;
        }

        private static bool IsOriginLike(Point3d start, Point3d end)
        {
            return start.DistanceTo(Point3d.Origin) < 0.001 && end.DistanceTo(Point3d.Origin) < 0.001;
        }

        private static bool IsOriginPoint(Point3d point)
        {
            return point.DistanceTo(Point3d.Origin) < 0.001;
        }

        private static void LogPipeEndpointIssue(Editor editor, DBObject pipeObj, string pipeLabel, Point3d start, Point3d end)
        {
            if (editor == null || pipeObj == null)
            {
                return;
            }

            editor.WriteMessage($"\nEndpoint issue for pipe {pipeLabel}: start=({start.X},{start.Y},{start.Z}) end=({end.X},{end.Y},{end.Z})");
            Log($"Endpoint issue for pipe {pipeLabel}: start=({start.X},{start.Y},{start.Z}) end=({end.X},{end.Y},{end.Z})");
            DumpPointProperties(pipeObj, editor);
            DumpObjectIdProperties(pipeObj, editor);
            DumpCurveProperties(pipeObj, editor);
        }

        private static void LogOriginJunctions(Editor editor, EpanetModel model)
        {
            if (editor == null || model == null)
            {
                return;
            }

            var originIds = model.Coordinates
                .Where(coord => IsOriginPoint(new Point3d(coord.X, coord.Y, 0)))
                .Select(coord => coord.Id)
                .Distinct()
                .ToList();

            if (!originIds.Any())
            {
                return;
            }

            editor.WriteMessage($"\nOrigin junctions detected: {string.Join(", ", originIds)}");
            Log($"Origin junctions detected: {string.Join(", ", originIds)}");

            foreach (var id in originIds)
            {
                var relatedPipes = model.Pipes
                    .Where(pipe => pipe.Node1 == id || pipe.Node2 == id)
                    .Select(pipe => pipe.OriginalId ?? pipe.Id)
                    .Distinct()
                    .ToList();

                if (relatedPipes.Any())
                {
                    editor.WriteMessage($"\n  Junction {id} used by pipes: {string.Join(", ", relatedPipes)}");
                    Log($"Junction {id} used by pipes: {string.Join(", ", relatedPipes)}");
                }
                else
                {
                    editor.WriteMessage($"\n  Junction {id} has no pipe references.");
                    Log($"Junction {id} has no pipe references.");
                }
            }
        }

        private static void RemoveUnreferencedJunctions(EpanetModel model)
        {
            if (model == null)
            {
                return;
            }

            var referenced = new HashSet<string>(
                model.Pipes.SelectMany(pipe => new[] { pipe.Node1, pipe.Node2 })
                    .Concat(model.Valves.SelectMany(valve => new[] { valve.Node1, valve.Node2 }))
                    .Where(id => !string.IsNullOrWhiteSpace(id)));

            model.Junctions.RemoveAll(junction => !referenced.Contains(junction.Id));
            model.Coordinates.RemoveAll(coord => !referenced.Contains(coord.Id));
        }

        private static string SanitizeId(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            var filtered = new string(value.Where(char.IsLetterOrDigit).ToArray());
            return string.IsNullOrWhiteSpace(filtered) ? null : filtered;
        }

        private static bool TryGetConnectedNode(
            DBObject pipeObj,
            Transaction transaction,
            out DBObject nodeObj,
            params string[] propertyNames)
        {
            foreach (var name in propertyNames)
            {
                var value = TryGetPropertyValue(pipeObj, name);
                if (value is ObjectId objectId && !objectId.IsNull)
                {
                    nodeObj = transaction.GetObject(objectId, OpenMode.ForRead, false);
                    if (nodeObj != null)
                    {
                        return true;
                    }
                }

                if (value is DBObject dbo)
                {
                    nodeObj = dbo;
                    return true;
                }
            }

            nodeObj = null;
            return false;
        }

        private static double GetDoubleProperty(DBObject obj, params string[] propertyNames)
        {
            return GetDoublePropertyFromObject(obj, propertyNames);
        }

        private static double GetDoublePropertyFromObject(object obj, params string[] propertyNames)
        {
            if (obj == null)
            {
                return 0.0;
            }

            foreach (var name in propertyNames)
            {
                var value = TryGetPropertyValue(obj, name);
                if (TryConvertToDouble(value, out var number))
                {
                    return number;
                }
            }

            return 0.0;
        }

        private static string GetStringProperty(DBObject obj, params string[] propertyNames)
        {
            foreach (var name in propertyNames)
            {
                var value = TryGetPropertyValue(obj, name);
                if (value is string text && !string.IsNullOrWhiteSpace(text))
                {
                    return text.Trim();
                }
            }

            return null;
        }

        private static object TryGetPropertyValue(object obj, string propertyName)
        {
            if (obj == null)
            {
                return null;
            }

            var property = obj.GetType().GetProperty(propertyName, BindingFlags.Instance | BindingFlags.Public);
            if (property == null)
            {
                return null;
            }

            try
            {
                return property.GetValue(obj);
            }
            catch (System.Exception ex)
            {
                Log($"Property read error {obj.GetType().Name}.{propertyName}: {ex.Message}");
                return null;
            }
        }

        private static IEnumerable<ObjectId> TryGetIds(DBObject network, Editor editor, params string[] memberNames)
        {
            foreach (var name in memberNames)
            {
                var propertyValue = TryGetPropertyValue(network, name);
                foreach (var id in ExtractIds(propertyValue, editor))
                {
                    yield return id;
                }

                var method = network.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.Public);
                if (method != null && method.GetParameters().Length == 0)
                {
                    var result = method.Invoke(network, null);
                    foreach (var id in ExtractIds(result, editor))
                    {
                        yield return id;
                    }
                }
            }
        }

        private static IEnumerable<ObjectId> TryGetPressurePipeIdsFromModelSpace(Database database, Transaction transaction, Editor editor)
        {
            if (database == null || transaction == null)
            {
                yield break;
            }

            var blockTable = (BlockTable)transaction.GetObject(database.BlockTableId, OpenMode.ForRead);
            var modelSpace = (BlockTableRecord)transaction.GetObject(blockTable[BlockTableRecord.ModelSpace], OpenMode.ForRead);

            foreach (ObjectId id in modelSpace)
            {
                var entity = transaction.GetObject(id, OpenMode.ForRead, false);
                if (entity == null)
                {
                    continue;
                }

                var typeName = entity.GetType().FullName ?? entity.GetType().Name;
                if (typeName.IndexOf("PressurePipe", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (IsNetworkPlaceholder(entity))
                    {
                        if (DiagnosticsEnabled)
                        {
                            Log($"Skipping model space entity likely not a pipe: {GetStringProperty(entity, "Name", "PartName", "Description") ?? typeName}");
                        }
                        continue;
                    }

                    yield return id;
                }
            }
        }

        private static void DumpPointProperties(DBObject obj, Editor editor)
        {
            if (!DiagnosticsEnabled)
            {
                return;
            }

            var props = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var prop in props)
            {
                if (prop.PropertyType != typeof(Point3d))
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = prop.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    editor.WriteMessage($"\n  Point3d {prop.Name}: <error: {ex.Message}>");
                    Log($"Point3d {prop.Name} read error: {ex.Message}");
                    continue;
                }

                if (value is Point3d pt)
                {
                    editor.WriteMessage($"\n  Point3d {prop.Name}: {pt.X},{pt.Y},{pt.Z}");
                    Log($"Point3d {prop.Name}: {pt.X},{pt.Y},{pt.Z}");
                }
            }
        }

        private static void DumpObjectIdProperties(DBObject obj, Editor editor)
        {
            if (!DiagnosticsEnabled)
            {
                return;
            }

            var props = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var prop in props)
            {
                if (prop.PropertyType != typeof(ObjectId))
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = prop.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    editor.WriteMessage($"\n  ObjectId {prop.Name}: <error: {ex.Message}>");
                    Log($"ObjectId {prop.Name} read error: {ex.Message}");
                    continue;
                }

                if (value is ObjectId id && !id.IsNull)
                {
                    editor.WriteMessage($"\n  ObjectId {prop.Name}: {id}");
                    Log($"ObjectId {prop.Name}: {id}");
                }
            }
        }

        private static void DumpCurveProperties(DBObject obj, Editor editor)
        {
            if (!DiagnosticsEnabled)
            {
                return;
            }

            var props = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var prop in props)
            {
                if (!typeof(Curve).IsAssignableFrom(prop.PropertyType))
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = prop.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    editor.WriteMessage($"\n  Curve {prop.Name}: <error: {ex.Message}>");
                    Log($"Curve {prop.Name} read error: {ex.Message}");
                    continue;
                }

                if (value is Curve curve)
                {
                    editor.WriteMessage($"\n  Curve {prop.Name}: {curve.StartPoint.X},{curve.StartPoint.Y},{curve.StartPoint.Z} -> {curve.EndPoint.X},{curve.EndPoint.Y},{curve.EndPoint.Z}");
                    Log($"Curve {prop.Name}: {curve.StartPoint.X},{curve.StartPoint.Y},{curve.StartPoint.Z} -> {curve.EndPoint.X},{curve.EndPoint.Y},{curve.EndPoint.Z}");
                }
            }
        }

        private static IEnumerable<ObjectId> TryGetPressureFittingIdsFromModelSpace(Database database, Transaction transaction, Editor editor)
        {
            if (database == null || transaction == null)
            {
                yield break;
            }

            var blockTable = (BlockTable)transaction.GetObject(database.BlockTableId, OpenMode.ForRead);
            var modelSpace = (BlockTableRecord)transaction.GetObject(blockTable[BlockTableRecord.ModelSpace], OpenMode.ForRead);

            foreach (ObjectId id in modelSpace)
            {
                var entity = transaction.GetObject(id, OpenMode.ForRead, false);
                if (entity == null)
                {
                    continue;
                }

                var typeName = entity.GetType().FullName ?? entity.GetType().Name;
                if (typeName.IndexOf("PressureFitting", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    yield return id;
                }
            }
        }

        private static IEnumerable<ObjectId> TryGetPressureAppurtenanceIdsFromModelSpace(Database database, Transaction transaction, Editor editor)
        {
            if (database == null || transaction == null)
            {
                yield break;
            }

            var blockTable = (BlockTable)transaction.GetObject(database.BlockTableId, OpenMode.ForRead);
            var modelSpace = (BlockTableRecord)transaction.GetObject(blockTable[BlockTableRecord.ModelSpace], OpenMode.ForRead);

            foreach (ObjectId id in modelSpace)
            {
                var entity = transaction.GetObject(id, OpenMode.ForRead, false);
                if (entity == null)
                {
                    continue;
                }

                var typeName = entity.GetType().FullName ?? entity.GetType().Name;
                if (typeName.IndexOf("Appurtenance", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    yield return id;
                }
            }
        }

        private static IEnumerable<ObjectId> TryGetIdsByTypeName(DBObject network, Editor editor, string typeNameContains)
        {
            var type = network.GetType();
            var properties = type.GetProperties(BindingFlags.Instance | BindingFlags.Public);

            foreach (var property in properties)
            {
                object value = null;
                try
                {
                    value = property.GetValue(network);
                }
                catch
                {
                    continue;
                }

                foreach (var id in ExtractIdsByTypeName(value, typeNameContains))
                {
                    yield return id;
                }
            }
        }

        private static IEnumerable<ObjectId> ExtractIdsByTypeName(object value, string typeNameContains)
        {
            if (value == null)
            {
                yield break;
            }

            if (value is IEnumerable enumerable)
            {
                foreach (var item in enumerable)
                {
                    if (item == null)
                    {
                        continue;
                    }

                    var typeName = item.GetType().Name;
                    if (typeName.IndexOf(typeNameContains, StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        continue;
                    }

                    if (item is ObjectId id && !id.IsNull)
                    {
                        yield return id;
                        continue;
                    }

                    if (item is DBObject dbo)
                    {
                        yield return dbo.ObjectId;
                        continue;
                    }

                    var objectIdProp = item.GetType().GetProperty("ObjectId", BindingFlags.Instance | BindingFlags.Public);
                    if (objectIdProp?.GetValue(item) is ObjectId objectId && !objectId.IsNull)
                    {
                        yield return objectId;
                    }
                }
            }
        }

        private static ObjectIdCollection TryInvokeObjectIdCollection(object obj, string methodName)
        {
            var method = obj.GetType().GetMethod(methodName, BindingFlags.Instance | BindingFlags.Public);
            if (method == null)
            {
                return null;
            }

            var result = method.Invoke(obj, null);
            return result as ObjectIdCollection;
        }

        private static IEnumerable<ObjectId> ExtractIds(object value, Editor editor)
        {
            if (value == null)
            {
                yield break;
            }

            if (value is ObjectIdCollection collection)
            {
                foreach (ObjectId id in collection)
                {
                    if (!id.IsNull)
                    {
                        yield return id;
                    }
                }

                yield break;
            }

            if (value is IEnumerable enumerable)
            {
                foreach (var item in enumerable)
                {
                    if (item is ObjectId id && !id.IsNull)
                    {
                        yield return id;
                        continue;
                    }

                    if (item is DBObject dbo)
                    {
                        yield return dbo.ObjectId;
                        continue;
                    }

                    var objectIdProp = item?.GetType().GetProperty("ObjectId", BindingFlags.Instance | BindingFlags.Public);
                    if (objectIdProp != null)
                    {
                        var idValue = objectIdProp.GetValue(item);
                        if (idValue is ObjectId objectId && !objectId.IsNull)
                        {
                            yield return objectId;
                        }
                    }
                }

                yield break;
            }

            editor?.WriteMessage("\nUnable to extract pressure network IDs from Civil 3D collection.");
        }

        private static bool IsValve(DBObject appurtenance)
        {
            var text = GetStringProperty(appurtenance, "PartType", "ValveType", "PartName", "Name");
            var descriptionText = GetStringProperty(appurtenance, "Description", "PartDescription", "LongDescription", "FullDescription");
            if (!string.IsNullOrWhiteSpace(descriptionText) &&
                descriptionText.IndexOf("valve", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return true;
            }

            var styleText = GetStringProperty(appurtenance, "StyleName", "AppurtenanceStyleName", "Style");
            var styleId = TryGetPropertyValue(appurtenance, "StyleId")
                          ?? TryGetPropertyValue(appurtenance, "AppurtenanceStyleId")
                          ?? TryGetPropertyValue(appurtenance, "Style");
            if (styleId is ObjectId styleObjId && !styleObjId.IsNull)
            {
                try
                {
                    var styleObj = appurtenance.Database.TransactionManager.GetObject(styleObjId, OpenMode.ForRead, false);
                    var styleName = GetStringProperty(styleObj as DBObject, "Name", "Description");
                    if (!string.IsNullOrWhiteSpace(styleName))
                    {
                        styleText = styleName;
                    }
                }
                catch
                {
                    // ignore style read errors
                }
            }

            if (!string.IsNullOrWhiteSpace(styleText) &&
                styleText.IndexOf("valve", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return true;
            }

            if (string.IsNullOrWhiteSpace(text))
            {
                var typeText = GetStringProperty(appurtenance, "AppurtenanceType", "AppurtenanceTypeName", "TypeName", "Description");
                if (!string.IsNullOrWhiteSpace(typeText) &&
                    typeText.IndexOf("valve", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    return true;
                }

                return HasStringPropertyContaining(appurtenance, "valve");
            }

            if (text.IndexOf("valve", StringComparison.OrdinalIgnoreCase) >= 0
                || IsEpanetValveType(text))
            {
                return true;
            }

            return HasStringPropertyContaining(appurtenance, "valve");
        }

        private static string EnsureUniqueValveId(EpanetModel model, string candidate)
        {
            if (model == null || string.IsNullOrWhiteSpace(candidate))
            {
                return candidate;
            }

            var id = candidate;
            var index = 1;
            while (model.Valves.Any(v => string.Equals(v.Id, id, StringComparison.OrdinalIgnoreCase))
                   || model.Pipes.Any(p => string.Equals(p.Id, id, StringComparison.OrdinalIgnoreCase)))
            {
                id = $"{candidate}_{index++}";
            }

            return id;
        }

        private static double GetNominalDiameter(DBObject appurtenance)
        {
            var diameter = GetDoubleProperty(appurtenance,
                "NominalDiameter",
                "NominalDiam",
                "NominalSize",
                "InnerDiameter",
                "InsideDiameter",
                "Diameter");

            if (diameter > 0.0)
            {
                return diameter;
            }

            var partObj = TryGetPropertyValue(appurtenance, "Part")
                          ?? TryGetPropertyValue(appurtenance, "PartData")
                          ?? TryGetPropertyValue(appurtenance, "PartRef");
            if (partObj is DBObject partDbObj)
            {
                diameter = GetDoubleProperty(partDbObj,
                    "NominalDiameter",
                    "NominalDiam",
                    "NominalSize",
                    "InnerDiameter",
                    "InsideDiameter",
                    "Diameter");
            }

            return diameter;
        }

        private static bool HasStringPropertyContaining(DBObject obj, string token)
        {
            if (obj == null || string.IsNullOrWhiteSpace(token))
            {
                return false;
            }

            var props = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var prop in props)
            {
                if (prop.PropertyType != typeof(string))
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = prop.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    Log($"String {prop.Name} read error: {ex.Message}");
                    continue;
                }

                if (value is string text &&
                    text.IndexOf(token, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    return true;
                }
            }

            return false;
        }

        private static void DumpStringProperties(DBObject obj, Editor editor)
        {
            if (!DiagnosticsEnabled)
            {
                return;
            }

            var props = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            var lines = new List<string>();
            foreach (var prop in props)
            {
                if (prop.PropertyType != typeof(string))
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = prop.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    lines.Add($"{prop.Name}=<error:{ex.Message}>");
                    continue;
                }

                if (value is string text && !string.IsNullOrWhiteSpace(text))
                {
                    lines.Add($"{prop.Name}={text}");
                }
            }

            if (lines.Any())
            {
                var joined = string.Join(" | ", lines);
                editor?.WriteMessage($"\nAppurtenance strings: {joined}");
                Log($"Appurtenance strings: {joined}");
            }
        }

        private static string EnsureUniqueJunctionId(EpanetModel model, string candidate)
        {
            if (model == null || string.IsNullOrWhiteSpace(candidate))
            {
                return candidate;
            }

            var id = candidate;
            var index = 1;
            while (model.Junctions.Any(j => string.Equals(j.Id, id, StringComparison.OrdinalIgnoreCase)))
            {
                id = $"{candidate}_{index++}";
            }

            return id;
        }

        private static void CreateJunctionAtPoint(
            string id,
            string originalId,
            Point3d point,
            EpanetModel model,
            Dictionary<CoordinateKey, string> junctionMap,
            Dictionary<string, Point3d> junctionPoints,
            Dictionary<CoordinateKey, string> fittingIdByCoord)
        {
            var key = new CoordinateKey(point);
            if (junctionPoints.ContainsKey(id))
            {
                return;
            }

            junctionMap[key] = id;
            junctionPoints[id] = point;
            fittingIdByCoord[key] = originalId;

            model.Junctions.Add(new Junction
            {
                Id = id,
                OriginalId = originalId ?? id,
                Elevation = point.Z,
                Demand = 0.0
            });

            model.Coordinates.Add(new Coordinate
            {
                Id = id,
                X = point.X,
                Y = point.Y
            });
        }

        private static bool RewirePipesForValve(
            Point3d location,
            string upstreamId,
            string downstreamId,
            EpanetModel model,
            Dictionary<string, Point3d> junctionPoints)
        {
            if (model == null || junctionPoints == null)
            {
                return false;
            }

            var endpoints = new List<(Pipe pipe, bool isNode1, double distance)>();
            foreach (var pipe in model.Pipes)
            {
                if (junctionPoints.TryGetValue(pipe.Node1, out var p1))
                {
                    endpoints.Add((pipe, true, p1.DistanceTo(location)));
                }

                if (junctionPoints.TryGetValue(pipe.Node2, out var p2))
                {
                    endpoints.Add((pipe, false, p2.DistanceTo(location)));
                }
            }

            var closest = endpoints
                .OrderBy(item => item.distance)
                .ToList();

            var first = closest.FirstOrDefault();
            var second = closest.Skip(1).FirstOrDefault(item => item.pipe != first.pipe || item.isNode1 != first.isNode1);

            if (first.pipe == null || second.pipe == null)
            {
                return false;
            }

            if (first.isNode1)
            {
                first.pipe.Node1 = upstreamId;
            }
            else
            {
                first.pipe.Node2 = upstreamId;
            }

            if (second.isNode1)
            {
                second.pipe.Node1 = downstreamId;
            }
            else
            {
                second.pipe.Node2 = downstreamId;
            }

            return true;
        }

        private static bool IsEpanetValveType(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            var normalized = value.Trim().ToUpperInvariant();
            return normalized == "PRV"
                   || normalized == "PSV"
                   || normalized == "PBV"
                   || normalized == "FCV"
                   || normalized == "TCV";
        }

        private static List<string> FindNearestJunctions(Point3d location, Dictionary<string, Point3d> junctionPoints, int count)
        {
            return junctionPoints
                .OrderBy(pair => pair.Value.DistanceTo(location))
                .Take(count)
                .Select(pair => pair.Key)
                .ToList();
        }

        private static double GetPipeLength(DBObject pipeObj, Point3d start, Point3d end)
        {
            var length = GetDoubleProperty(pipeObj,
                "Length3d",
                "Length3D",
                "Length3DCenterToCenter",
                "CenterToCenterLength3D",
                "3DLength",
                "TrueLength",
                "CenterlineLength3d",
                "CenterlineLength3D",
                "CenterlineLength",
                "PipeLength",
                "Length");

            if (length > 0)
            {
                if (length <= 1.01)
                {
                    LogPipeLengthDiagnostics(pipeObj, start, end, length, "Length property returned <= 1.01");
                }

                return length;
            }

            if (TryGetNestedPipeLength(pipeObj, out var nestedLength, out var nestedSource))
            {
                if (nestedLength <= 1.01)
                {
                    LogPipeLengthDiagnostics(pipeObj, start, end, nestedLength, $"Nested length returned <= 1.01 ({nestedSource})");
                }

                return nestedLength;
            }

            if (TryGetCurveLength(pipeObj, out var curveLength))
            {
                if (curveLength <= 1.01)
                {
                    LogPipeLengthDiagnostics(pipeObj, start, end, curveLength, "Curve length returned <= 1.01");
                }

                if (curveLength <= 1.01)
                {
                    var distance = start.DistanceTo(end);
                    if (distance > 1.01)
                    {
                        LogPipeLengthDiagnostics(pipeObj, start, end, distance, "Using start/end distance instead of curve length");
                        return distance;
                    }
                }

                return curveLength;
            }

            LogPipeLengthDiagnostics(pipeObj, start, end, 0.0, "Falling back to start/end distance");
            return start.DistanceTo(end);
        }

        private static bool TryGetNestedPipeLength(DBObject pipeObj, out double length, out string source)
        {
            length = 0.0;
            source = null;
            if (pipeObj == null)
            {
                return false;
            }

            var nestedNames = new[]
            {
                "Geometry",
                "GeometryData",
                "GeometryObject",
                "PartData",
                "Part",
                "PartSize",
                "Size"
            };

            var lengthNames = new[]
            {
                "Length3d",
                "Length3D",
                "Length3DCenterToCenter",
                "CenterToCenterLength3D",
                "3DLength",
                "TrueLength",
                "CenterlineLength3d",
                "CenterlineLength3D",
                "CenterlineLength",
                "PipeLength",
                "Length"
            };

            foreach (var nestedName in nestedNames)
            {
                var nested = TryGetPropertyValue(pipeObj, nestedName);
                if (nested == null)
                {
                    continue;
                }

                length = GetDoublePropertyFromObject(nested, lengthNames);
                if (length > 0)
                {
                    source = nestedName;
                    return true;
                }
            }

            return false;
        }

        private static bool TryGetCurveLength(DBObject pipeObj, out double length)
        {
            length = 0.0;
            if (pipeObj == null)
            {
                return false;
            }

            foreach (var name in new[] { "Centerline", "CenterlineCurve", "PipeCurve", "BaseCurve", "Curve" })
            {
                var value = TryGetPropertyValue(pipeObj, name);
                if (value is Curve curve)
                {
                    try
                    {
                        var startDistance = curve.GetDistanceAtParameter(curve.StartParam);
                        var endDistance = curve.GetDistanceAtParameter(curve.EndParam);
                        length = Math.Abs(endDistance - startDistance);
                        return length > 0;
                    }
                    catch (System.Exception ex)
                    {
                        Log($"Curve length read error {name}: {ex.Message}");
                        return false;
                    }
                }
            }

            return false;
        }

        private static bool TryConvertToDouble(object value, out double result)
        {
            result = 0.0;
            if (value == null)
            {
                return false;
            }

            switch (value)
            {
                case double dbl:
                    result = dbl;
                    return true;
                case float flt:
                    result = flt;
                    return true;
                case int integer:
                    result = integer;
                    return true;
                case long longValue:
                    result = longValue;
                    return true;
                case decimal dec:
                    result = (double)dec;
                    return true;
                case string text:
                    if (TryParseLengthString(text, out result))
                    {
                        return true;
                    }

                    return false;
            }

            var valueType = value.GetType();
            var valueProp = valueType.GetProperty("Value", BindingFlags.Instance | BindingFlags.Public);
            if (valueProp != null)
            {
                try
                {
                    var inner = valueProp.GetValue(value);
                    return TryConvertToDouble(inner, out result);
                }
                catch (System.Exception ex)
                {
                    Log($"Value property read error {valueType.Name}: {ex.Message}");
                }
            }

            return false;
        }

        private static bool TryParseLengthString(string text, out double result)
        {
            result = 0.0;
            if (string.IsNullOrWhiteSpace(text))
            {
                return false;
            }

            var trimmed = text.Trim();
            if (double.TryParse(trimmed, NumberStyles.Float, CultureInfo.InvariantCulture, out result))
            {
                return true;
            }

            if (double.TryParse(trimmed, NumberStyles.Float, CultureInfo.CurrentCulture, out result))
            {
                return true;
            }

            var filtered = new string(trimmed.Where(ch => char.IsDigit(ch) || ch == '.' || ch == '-' || ch == '+').ToArray());
            if (double.TryParse(filtered, NumberStyles.Float, CultureInfo.InvariantCulture, out result))
            {
                return true;
            }

            return double.TryParse(filtered, NumberStyles.Float, CultureInfo.CurrentCulture, out result);
        }

        private static void LogPipeLengthDiagnostics(DBObject pipeObj, Point3d start, Point3d end, double length, string reason)
        {
            if (!DiagnosticsEnabled)
            {
                return;
            }

            if (pipeObj == null)
            {
                return;
            }

            var name = GetStringProperty(pipeObj, "Name", "PartName", "Description") ?? pipeObj.ObjectId.ToString();
            Log($"Pipe length diagnostics ({reason}) for {name}: length={length}, start/end distance={start.DistanceTo(end)}");

            foreach (var propName in new[]
                     {
                         "Length3d",
                         "Length3D",
                         "Length3DCenterToCenter",
                         "CenterToCenterLength3D",
                         "3DLength",
                         "TrueLength",
                         "CenterlineLength3d",
                         "CenterlineLength3D",
                         "CenterlineLength",
                         "PipeLength",
                         "Length"
                     })
            {
                var raw = TryGetPropertyValue(pipeObj, propName);
                if (raw == null)
                {
                    continue;
                }

                var rawType = raw.GetType().FullName;
                var parsed = TryConvertToDouble(raw, out var parsedValue) ? parsedValue.ToString(CultureInfo.InvariantCulture) : "<unparsed>";
                Log($"  {propName}: {raw} (type {rawType}) parsed={parsed}");
            }

            LogLengthLikeProperties(pipeObj, "  ");

            foreach (var nestedName in new[] { "Geometry", "GeometryData", "GeometryObject", "PartData", "Part", "PartSize", "Size" })
            {
                var nested = TryGetPropertyValue(pipeObj, nestedName);
                if (nested == null)
                {
                    continue;
                }

                Log($"  Nested {nestedName}: type {nested.GetType().FullName}");
                LogLengthLikeProperties(nested, $"    {nestedName}.");
                foreach (var propName in new[]
                         {
                             "Length3d",
                             "Length3D",
                             "Length3DCenterToCenter",
                             "CenterToCenterLength3D",
                             "3DLength",
                             "TrueLength",
                             "CenterlineLength3d",
                             "CenterlineLength3D",
                             "CenterlineLength",
                             "PipeLength",
                             "Length"
                         })
                {
                    var raw = TryGetPropertyValue(nested, propName);
                    if (raw == null)
                    {
                        continue;
                    }

                    var rawType = raw.GetType().FullName;
                    var parsed = TryConvertToDouble(raw, out var parsedValue) ? parsedValue.ToString(CultureInfo.InvariantCulture) : "<unparsed>";
                    Log($"    {nestedName}.{propName}: {raw} (type {rawType}) parsed={parsed}");
                }
            }
        }

        private static void LogLengthLikeProperties(object obj, string prefix)
        {
            if (!DiagnosticsEnabled)
            {
                return;
            }

            if (obj == null)
            {
                return;
            }

            var props = obj.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var prop in props)
            {
                if (prop.GetIndexParameters().Length > 0)
                {
                    continue;
                }

                var name = prop.Name ?? string.Empty;
                if (name.IndexOf("Length", StringComparison.OrdinalIgnoreCase) < 0
                    && name.IndexOf("3D", StringComparison.OrdinalIgnoreCase) < 0)
                {
                    continue;
                }

                object value = null;
                try
                {
                    value = prop.GetValue(obj);
                }
                catch (System.Exception ex)
                {
                    Log($"{prefix}{name}: <error {ex.Message}>");
                    continue;
                }

                if (value == null)
                {
                    continue;
                }

                var rawType = value.GetType().FullName;
                var parsed = TryConvertToDouble(value, out var parsedValue) ? parsedValue.ToString(CultureInfo.InvariantCulture) : "<unparsed>";
                Log($"{prefix}{name}: {value} (type {rawType}) parsed={parsed}");
            }
        }

        private static bool IsNetworkPlaceholder(DBObject entity)
        {
            var name = GetStringProperty(entity, "Name", "PartName", "Description");
            if (string.IsNullOrWhiteSpace(name))
            {
                return false;
            }

            return name.IndexOf("Pressure Network", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static string FindNearbyJunctionId(Point3d location, Dictionary<string, Point3d> junctionPoints, double radius)
        {
            if (junctionPoints == null || junctionPoints.Count == 0 || radius <= 0.0)
            {
                return null;
            }

            var closest = junctionPoints
                .Select(pair => new { pair.Key, Distance = pair.Value.DistanceTo(location) })
                .Where(item => item.Distance <= radius)
                .OrderBy(item => item.Distance)
                .FirstOrDefault();

            return closest?.Key;
        }

        private static double GetConnectionSearchRadius()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            var metersPerUnit = UnitConversion.GetLengthFactorToMeters(doc?.Database);
            var isImperial = doc?.Database?.Insunits == UnitsValue.Feet
                             || doc?.Database?.Insunits == UnitsValue.Inches;
            var desiredMeters = isImperial ? 0.3048 : 0.5;
            return metersPerUnit <= 0.0 ? desiredMeters : desiredMeters / metersPerUnit;
        }

        private readonly struct CoordinateKey : IEquatable<CoordinateKey>
        {
            private readonly double _x;
            private readonly double _y;
            private readonly double _z;

            public CoordinateKey(Point3d point)
            {
                _x = Math.Round(point.X, 3);
                _y = Math.Round(point.Y, 3);
                _z = Math.Round(point.Z, 3);
            }

            public bool Equals(CoordinateKey other)
            {
                return _x.Equals(other._x) && _y.Equals(other._y) && _z.Equals(other._z);
            }

            public override bool Equals(object obj)
            {
                return obj is CoordinateKey other && Equals(other);
            }

            public override int GetHashCode()
            {
                unchecked
                {
                    var hash = 17;
                    hash = (hash * 23) + _x.GetHashCode();
                    hash = (hash * 23) + _y.GetHashCode();
                    hash = (hash * 23) + _z.GetHashCode();
                    return hash;
                }
            }
        }
    }
}


