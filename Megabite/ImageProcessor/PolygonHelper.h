//
//  PolygonHelper.h
//  Megabite
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

@class Polygon;

@interface PolygonHelper : NSObject

+ (NSArray*)binPolygonsForTemplateBasedOnItemPolygons:(NSArray*)itemPolygons;
+ (NSArray*)sortPolygonsBySurfaceArea:(NSArray*)polygons;
+ (Polygon*)rotatePolygonToCoverPolygon:(Polygon*)item bin:(Polygon*)bin maxNumPolygonRotations:(int)maxNumPolygonRotations;
+ (int)calculateSurfaceAreaCoverageForBin:(Polygon*)bin item:(Polygon*)item rotation:(int)rotation;
+ (UIImage*)addItemPolygon:(Polygon*)itemPolygon toImage:(UIImage*)image atBinPolygon:(Polygon*)binPolygon;
+ (UIImage*)displayBinTemplateLayout:(NSArray*)binPolygons usingSize:(CGSize)size;

@end