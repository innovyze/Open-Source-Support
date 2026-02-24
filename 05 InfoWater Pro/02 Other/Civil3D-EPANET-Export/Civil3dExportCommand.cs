using System;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;

namespace Civil3dEpanetExport
{
    public sealed class Civil3dExportCommand : IExtensionApplication
    {
        public void Initialize()
        {
            // No startup logic required for MVP.
        }

        public void Terminate()
        {
            // No shutdown logic required for MVP.
        }

        [CommandMethod("C3D_EXPORT_EPANET")]
        public void ExportToEpanet()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null)
            {
                return;
            }

            var editor = doc.Editor;
            Civil3dPressureNetworkReader.DiagnosticsEnabled = false;

            var saveOptions = new PromptSaveFileOptions("Save EPANET INP file")
            {
                Filter = "EPANET INP (*.inp)|*.inp",
                DialogCaption = "Export EPANET INP"
            };

            var saveResult = editor.GetFileNameForSave(saveOptions);
            if (saveResult.Status != PromptStatus.OK || string.IsNullOrWhiteSpace(saveResult.StringResult))
            {
                return;
            }

            var units = PromptUnits(editor);
            if (string.IsNullOrWhiteSpace(units))
            {
                return;
            }

            var roughness = PromptRoughness(editor);
            if (roughness == null)
            {
                return;
            }

            var logPath = saveResult.StringResult + ".log";
            Civil3dPressureNetworkReader.LogSink = message =>
            {
                if (!string.IsNullOrWhiteSpace(message))
                {
                    System.IO.File.AppendAllText(logPath, message + Environment.NewLine);
                }
            };
            Civil3dPressureNetworkReader.LogSink($"Export started: {DateTime.Now:O}");

            var model = Civil3dPressureNetworkReader.ReadModel(editor);
            var lengthToMeters = UnitConversion.GetLengthFactorToMeters(doc.Database);
            var lengthFactor = units == "GPM" ? UnitConversion.MetersToFeet(lengthToMeters) : lengthToMeters;
            var diameterFactor = units == "GPM"
                ? UnitConversion.MetersToInches(lengthToMeters)
                : lengthToMeters * 1000.0;

            var writer = new EpanetWriter();
            var options = new EpanetWriteOptions
            {
                Units = units,
                Headloss = "H-W",
                DefaultHazenWilliams = roughness.Value,
                ForceZeroDemand = true,
                LengthFactor = lengthFactor,
                DiameterFactor = diameterFactor,
                ElevationFactor = lengthFactor,
                CoordinateFactor = lengthFactor
            };

            try
            {
                writer.Write(saveResult.StringResult, model, options);
                editor.WriteMessage($"\nEPANET export completed: {saveResult.StringResult}");
                editor.WriteMessage($"\nLog written: {logPath}");
                Civil3dPressureNetworkReader.LogSink($"Export completed: {saveResult.StringResult}");
            }
            catch (System.Exception ex)
            {
                editor.WriteMessage($"\nEPANET export failed: {ex.Message}");
                Civil3dPressureNetworkReader.LogSink($"Export failed: {ex}");
            }
        }

        [CommandMethod("C3D_EXPORT_EPANET_DIAG")]
        public void ExportDiagnostics()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null)
            {
                return;
            }

            var editor = doc.Editor;
            Civil3dPressureNetworkReader.DiagnosticsEnabled = true;
            Civil3dPressureNetworkReader.DumpPipeDiagnostics(editor, "Pressure Pipe - (195)");
        }

        private static string PromptUnits(Editor editor)
        {
            var options = new PromptKeywordOptions("\nUnits [LPS/GPM] <LPS>: ", "LPS GPM")
            {
                AllowNone = true
            };

            var result = editor.GetKeywords(options);
            if (result.Status == PromptStatus.Cancel)
            {
                return null;
            }

            if (result.Status == PromptStatus.None || string.IsNullOrWhiteSpace(result.StringResult))
            {
                return "LPS";
            }

            return result.StringResult;
        }

        private static int? PromptRoughness(Editor editor)
        {
            var options = new PromptIntegerOptions("\nRoughness (Hazen-Williams) <140>: ")
            {
                DefaultValue = 140,
                AllowNegative = false,
                AllowZero = false,
                AllowNone = true
            };

            var result = editor.GetInteger(options);
            if (result.Status == PromptStatus.Cancel)
            {
                return null;
            }

            return result.Status == PromptStatus.None ? options.DefaultValue : result.Value;
        }
    }

    // Civil3dPressureNetworkReader is defined in Civil3dPressureNetworkReader.cs

    internal static class UnitConversion
    {
        public static double GetLengthFactorToMeters(Database database)
        {
            if (database == null)
            {
                return 1.0;
            }

            switch (database.Insunits)
            {
                case UnitsValue.Millimeters:
                    return 0.001;
                case UnitsValue.Centimeters:
                    return 0.01;
                case UnitsValue.Meters:
                    return 1.0;
                case UnitsValue.Inches:
                    return 0.0254;
                case UnitsValue.Feet:
                    return 0.3048;
                default:
                    return 1.0;
            }
        }

        public static double MetersToFeet(double meters)
        {
            return meters / 0.3048;
        }

        public static double MetersToInches(double meters)
        {
            return meters / 0.0254;
        }
    }
}

