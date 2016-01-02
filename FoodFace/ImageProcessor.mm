//
//  ImageProcessor.m
//  FoodFace
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "ImageProcessor.h"
#import "ImageProcessorResult.h"
#import "ImageHelper.h"
#import <opencv2/opencv.hpp>
#import "ContourAnalyser.h"
#import "Polygon.h"
#import "PolygonHelper.h"

@implementation ImageProcessor {
    UIImage *inputImage;
    UIImage *croppedImage;
    cv::Mat imageMatrix;
    cv::Mat imageMatrixAll;
    cv::Mat imageMatrixFiltered;
    std::vector<std::vector<cv::Point>> allContours;
    std::vector<std::vector<cv::Point>> filteredContours;
    NSMutableArray *contourImages;
    NSMutableArray *extractedPolygons;
}

-(id)initWithImage:(UIImage*)image {
    self = [super init];
    if (self) {
        inputImage = image;
    }
    return self;
}

-(ImageProcessorResult*)prepareImage {
    // Crop the image
    croppedImage = [ImageHelper roundedRectImageFromImage:inputImage size:inputImage.size withCornerRadius:inputImage.size.height/2];
    
    // Convert the image into a matrix
    imageMatrix = [ImageHelper cvMatFromUIImage:croppedImage];
    imageMatrix.copyTo(imageMatrixAll);
    imageMatrix.copyTo(imageMatrixFiltered);
    
    return [self results:@[croppedImage] images:@[]];
}

-(ImageProcessorResult*)findContours {
    // Detect all contours within the image matrix, and filter for those that match detection criteria
    allContours = [ContourAnalyser findContoursInImage:imageMatrixAll];
    
    // Highlight the contours in the image
    cv::Mat cvMatWithSquaresAll = [ImageHelper highlightContoursInImage:allContours image:imageMatrixAll];
    UIImage *highlightedContours = [ImageHelper UIImageFromCVMat:cvMatWithSquaresAll];
    
    return [self results:@[] images:@[highlightedContours]];
}

-(ImageProcessorResult*)filterContours {
    filteredContours = [ContourAnalyser filterContours:allContours];
    
    // Highlight the contours in the image
     cv::Mat cvMatWithSquaresFiltered = [ImageHelper highlightContoursInImage:filteredContours image:imageMatrixFiltered];
    UIImage *highlightedContours = [ImageHelper UIImageFromCVMat:cvMatWithSquaresFiltered];
    
    return [self results:@[] images:@[highlightedContours]];
}

-(ImageProcessorResult*)extractContourBoundingBoxImages {
    // Extract highlighted contours
    cv::vector<cv::Mat> extractedContours = [ImageHelper cutContoursFromImage:filteredContours image:imageMatrix];
    
    // Crop extracted contours to the size of the contour, and make background transparent
    contourImages = [ContourAnalyser reduceContoursToBoundingBox:extractedContours];
    
    return [self results:@[] images:@[]];
}

-(ImageProcessorResult*)boundingBoxImagesToPolygons {
    // Construct Polygon objects from the extracted images
    extractedPolygons = [NSMutableArray array];
    for (int i = 0; i < contourImages.count; i++) {
        Polygon *polygon = [[Polygon alloc] initWithImage:contourImages[i]];
        [extractedPolygons addObject:polygon];
    }
    
    return [self results:@[] images:@[]];
}

-(ImageProcessorResult*)placePolygonsOnTargetTemplate {
    // Get the bin Polygons based on the item Polygons we've extracted
    NSArray *binPolygons = [PolygonHelper binPolygonsForTemplateBasedOnItemPolygons:extractedPolygons];
    
    // Sort the polygons by surface area
    NSArray *sortedBinPolygons = [PolygonHelper sortPolygonsBySurfaceArea:binPolygons];
    NSArray *sortedExtractedPolygons = [PolygonHelper sortPolygonsBySurfaceArea:extractedPolygons];
    
    UIImage *testImage = [UIImage imageNamed:@"EmptyPlate"];
    
    for (int i = 0; i < sortedBinPolygons.count; i++) {
        Polygon *currentBinPolygon = sortedBinPolygons[i];
        Polygon *currentExtractedPolygon = sortedExtractedPolygons[i];
        
        currentExtractedPolygon = [PolygonHelper rotatePolygonToCoverPolygon:currentExtractedPolygon bin:currentBinPolygon];
        
        // Add current item Polygon to the image at the bin Polygon position
        testImage = [PolygonHelper addItemPolygon:currentExtractedPolygon toImage:testImage atBinPolygon:currentBinPolygon];
    }
    
    return [self results:@[testImage] images:@[]];
}

-(ImageProcessorResult*)results:(NSArray*)results images:(NSArray*)images {
    return [[ImageProcessorResult alloc] initWithResults:results images:images];
}


@end