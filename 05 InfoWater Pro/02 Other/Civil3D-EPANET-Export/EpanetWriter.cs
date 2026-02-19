using System;
using System.Globalization;
using System.IO;
using System.Linq;

namespace Civil3dEpanetExport
{
    internal sealed class EpanetWriter
    {
        public void Write(string outputPath, EpanetModel model, EpanetWriteOptions options)
        {
            if (string.IsNullOrWhiteSpace(outputPath))
            {
                throw new ArgumentException("Output path is required.", nameof(outputPath));
            }

            if (model == null)
            {
                throw new ArgumentNullException(nameof(model));
            }

            if (options == null)
            {
                throw new ArgumentNullException(nameof(options));
            }

            using (var writer = new StreamWriter(outputPath))
            {
                WriteJunctions(writer, model, options);
                WritePipes(writer, model, options);
                WriteValves(writer, model, options);
                WriteCoordinates(writer, model, options);
                WriteOptions(writer, options);
                WriteTimes(writer);
                WriteReport(writer);
                WriteEnd(writer);
            }
        }

        private static void WriteJunctions(StreamWriter writer, EpanetModel model, EpanetWriteOptions options)
        {
            writer.WriteLine("[JUNCTIONS]");
            writer.WriteLine(";ID    Elevation    Demand");

            foreach (var junction in model.Junctions)
            {
                var demand = options.ForceZeroDemand ? 0.0 : junction.Demand;
                var line = $"{junction.Id} {Format(ApplyFactor(junction.Elevation, options.ElevationFactor))} {Format(demand)}";
                if (!string.IsNullOrWhiteSpace(junction.OriginalId))
                {
                    line += $" ;{junction.OriginalId}";
                }

                writer.WriteLine(line);
            }

            writer.WriteLine();
        }

        private static void WritePipes(StreamWriter writer, EpanetModel model, EpanetWriteOptions options)
        {
            writer.WriteLine("[PIPES]");
            writer.WriteLine(";ID    Node1    Node2    Length    Diameter    Roughness    MinorLoss    Status");

            foreach (var pipe in model.Pipes)
            {
                var roughness = pipe.Roughness > 0 ? pipe.Roughness : options.DefaultHazenWilliams;
                var status = string.IsNullOrWhiteSpace(pipe.Status) ? "Open" : pipe.Status;

                var line = $"{pipe.Id} {pipe.Node1} {pipe.Node2} {Format(ApplyFactor(pipe.Length, options.LengthFactor))} {Format(ApplyFactor(pipe.Diameter, options.DiameterFactor))} {Format(roughness)} {Format(pipe.MinorLoss)} {status}";
                if (!string.IsNullOrWhiteSpace(pipe.OriginalId))
                {
                    line += $" ;{pipe.OriginalId}";
                }

                writer.WriteLine(line);
            }

            writer.WriteLine();
        }

        private static void WriteValves(StreamWriter writer, EpanetModel model, EpanetWriteOptions options)
        {
            if (!model.Valves.Any())
            {
                return;
            }

            writer.WriteLine("[VALVES]");
            writer.WriteLine(";ID    Node1    Node2    Diameter    Type    Setting    MinorLoss");

            foreach (var valve in model.Valves)
            {
                var type = string.IsNullOrWhiteSpace(valve.Type) ? "TCV" : valve.Type;
                var line = $"{valve.Id} {valve.Node1} {valve.Node2} {Format(ApplyFactor(valve.Diameter, options.DiameterFactor))} {type} {Format(valve.Setting)} {Format(valve.MinorLoss)}";
                if (!string.IsNullOrWhiteSpace(valve.Description))
                {
                    line += $"; {valve.Description}";
                }
                else if (!string.IsNullOrWhiteSpace(valve.OriginalId))
                {
                    line += $"; {valve.OriginalId}";
                }

                writer.WriteLine(line);
            }

            writer.WriteLine();
        }

        private static void WriteCoordinates(StreamWriter writer, EpanetModel model, EpanetWriteOptions options)
        {
            writer.WriteLine("[COORDINATES]");

            foreach (var coord in model.Coordinates)
            {
                writer.WriteLine($"{coord.Id} {Format(ApplyFactor(coord.X, options.CoordinateFactor))} {Format(ApplyFactor(coord.Y, options.CoordinateFactor))}");
            }

            writer.WriteLine();
        }

        private static void WriteOptions(StreamWriter writer, EpanetWriteOptions options)
        {
            writer.WriteLine("[OPTIONS]");
            writer.WriteLine($"UNITS     {options.Units}");
            writer.WriteLine($"HEADLOSS  {options.Headloss}");
            writer.WriteLine();
        }

        private static void WriteTimes(StreamWriter writer)
        {
            writer.WriteLine("[TIMES]");
            writer.WriteLine("; Use EPANET defaults unless otherwise specified");
            writer.WriteLine();
        }

        private static void WriteReport(StreamWriter writer)
        {
            writer.WriteLine("[REPORT]");
            writer.WriteLine("STATUS YES");
            writer.WriteLine();
        }

        private static void WriteEnd(StreamWriter writer)
        {
            writer.WriteLine("[END]");
        }

        private static string Format(double value)
        {
            return value.ToString("0.###", CultureInfo.InvariantCulture);
        }

        private static double ApplyFactor(double value, double factor)
        {
            return value * factor;
        }
    }

    internal sealed class EpanetWriteOptions
    {
        public string Units { get; set; } = "LPS";
        public string Headloss { get; set; } = "H-W";
        public double DefaultHazenWilliams { get; set; } = 150.0;
        public bool ForceZeroDemand { get; set; } = true;
        public double LengthFactor { get; set; } = 1.0;
        public double DiameterFactor { get; set; } = 1.0;
        public double ElevationFactor { get; set; } = 1.0;
        public double CoordinateFactor { get; set; } = 1.0;
    }
}


