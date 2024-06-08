# Build a large 1D/2D XPSWMM Model

## Introduction
Working with large models in XPSWMM opens up a world of opportunities and challenges. Some tasks can take a long time to process and might cause unexpected errors. 

In this workshop we’ll learn the best practices of building large 2D models in XPSWMM.

For large models, reference large datasets from external sources can greatly improve the user experience.
- Reference Landuse polygons for materials (manning’s n) and soils (infiltration) from external shapefiles
- Reference DTM from external files (*.asc)
- Divide large background layers into tiles to speed up map rendering

You will learn the best practices through the following exercises,
1. Build a simple 2D model
2. Update manning’s n
3. Update soil infiltration parameters
4. Add culverts
5. Add storm sewer system
6. Review results
7. Add 1D river
8. Use Quadtree and SGS
