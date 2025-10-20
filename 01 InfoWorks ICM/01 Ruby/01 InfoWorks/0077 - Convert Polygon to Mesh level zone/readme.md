# Convert Polygon to Mesh Level Zone

## Overview

Converts selected polygon objects (`hw_polygon`) to mesh level zone objects (`hw_mesh_level_zone`) while preserving exact boundary geometry.

## Usage

1. Select polygon objects in your InfoWorks ICM network
2. Run the script
3. New mesh level zones will be created with IDs: `MLZ{polygon.id}`

## Key Features

- Processes only selected polygons
- Preserves exact polygon boundaries (vertices)
- Automatically closes polygons by duplicating the first vertex at the end
- 'Vertex elevation type' must be specified (options: 'Ground model', 'Set', 'Interpolate')

## Database Tables

- **Input**: `hw_polygon`
- **Output**: `hw_mesh_level_zone`

Generated using AI