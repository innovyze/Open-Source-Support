using System.Collections.Generic;

namespace Civil3dEpanetExport
{
    internal sealed class EpanetModel
    {
        public List<Junction> Junctions { get; } = new List<Junction>();
        public List<Pipe> Pipes { get; } = new List<Pipe>();
        public List<Valve> Valves { get; } = new List<Valve>();
        public List<Coordinate> Coordinates { get; } = new List<Coordinate>();
    }

    internal sealed class Junction
    {
        public string Id { get; set; } = string.Empty;
        public string OriginalId { get; set; } = string.Empty;
        public double Elevation { get; set; }
        public double Demand { get; set; }
    }

    internal sealed class Pipe
    {
        public string Id { get; set; } = string.Empty;
        public string OriginalId { get; set; } = string.Empty;
        public string Node1 { get; set; } = string.Empty;
        public string Node2 { get; set; } = string.Empty;
        public double Length { get; set; }
        public double Diameter { get; set; }
        public double Roughness { get; set; }
        public double MinorLoss { get; set; }
        public string Status { get; set; } = "Open";
    }

    internal sealed class Valve
    {
        public string Id { get; set; } = string.Empty;
        public string OriginalId { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Node1 { get; set; } = string.Empty;
        public string Node2 { get; set; } = string.Empty;
        public double Diameter { get; set; }
        public string Type { get; set; } = "TCV";
        public double Setting { get; set; }
        public double MinorLoss { get; set; }
        public string Status { get; set; } = "Open";
    }

    internal sealed class Coordinate
    {
        public string Id { get; set; } = string.Empty;
        public double X { get; set; }
        public double Y { get; set; }
    }
}


