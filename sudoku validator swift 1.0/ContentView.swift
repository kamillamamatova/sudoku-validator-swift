import Foundation
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO

// Converts UIImage.Orientation to CGImagePropertyOrientation
extension CGImagePropertyOrientation{
    init(_ uiOrientation: UIImage.Orientation){
        switch uiOrientation{
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            @unknown default: self = .up
        }
    }
}

class GridProcessor{

    func process(image: UIImage, completion: @escaping ([[Int]]) -> Void){
        // Finds the Sudoku grid in the image and crop to it.
        findAndCropGrid(from: image) { croppedImage in
            guard let imageToProcess = croppedImage else{
                // Return an empty grid if cropping fails
                completion(Array(repeating: Array(repeating: 0, count: 9), count: 9))
                return
            }

            // Proceeds with the multi-pass text recognition on the cropped image
            self.performTextRecognition(on: imageToProcess, completion: completion)
        }
    }

    private func performTextRecognition(on image: UIImage, completion: @escaping ([[Int]]) -> Void){
        var imageVersions: [CGImage] = []
        let imageOrientation = image.imageOrientation

        // Original unmodified image
        if let originalCgImage = image.cgImage{
            imageVersions.append(originalCgImage)
        }
        // Image enhancement filters
        if let contrastCgImage = enhanceWithAdvancedContrast(image: image){
            imageVersions.append(contrastCgImage)
        }
        if let monochromeCgImage = enhanceWithMonochrome(image: image){
            imageVersions.append(monochromeCgImage)
        }
        if let sharpenedCgImage = enhanceWithSharpen(image: image){
            imageVersions.append(sharpenedCgImage)
        }
        if let noirCgImage = enhanceWithNoir(image: image){
            imageVersions.append(noirCgImage)
        }
        // ADDED: New dilation and erosion filter
        if let dilatedCgImage = enhanceWithDilationAndErosion(image: image){
            imageVersions.append(dilatedCgImage)
        }

        var recognizedGrids: [[[Int]]] = []
        let dispatchGroup = DispatchGroup()
        let resultsLock = NSLock()

        for version in imageVersions{
            dispatchGroup.enter()
            recognizeText(in: version, orientation: imageOrientation){ grid in
                resultsLock.lock()
                recognizedGrids.append(grid)
                resultsLock.unlock()
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main){
            let finalGrid = self.merge(grids: recognizedGrids)
            completion(finalGrid)
        }
    }

    // Finds and crops the grid
    private func findAndCropGrid(from image: UIImage, completion: @escaping (UIImage?) -> Void){
        guard let cgImage = image.cgImage else{
            completion(nil)
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
        let request = VNDetectRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNRectangleObservation],
                  let largestRectangle = observations.first else{
                // Returns to the original image if no rectangle is found
                DispatchQueue.main.async{ completion(image) }
                return
            }

            let cropRect = VNImageRectForNormalizedRect(largestRectangle.boundingBox, cgImage.width, cgImage.height)

            if let croppedCGImage = cgImage.cropping(to: cropRect){
                let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
                DispatchQueue.main.async{ completion(croppedImage) }
            }
            else{
                DispatchQueue.main.async{ completion(image) } // Fallback
            }
        }

        // Configures the request for finding a Sudoku grid
        request.maximumObservations = 1
        request.minimumAspectRatio = 0.8
        request.maximumAspectRatio = 1.2
        request.minimumSize = 0.5 // Testing
        request.minimumConfidence = 0.5

        DispatchQueue.global(qos: .userInitiated).async{
            do{
                try requestHandler.perform([request])
            }
            catch{
                print("Error detecting rectangles: \(error)")
                DispatchQueue.main.async { completion(image) } // Fallback
            }
        }
    }
    
    // Merges multiple grid results into one master grid
    private func merge(grids: [[[Int]]]) -> [[Int]]{
        var masterGrid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        for row in 0..<9{
            for col in 0..<9{
                var counts: [Int: Int] = [:]
                for grid in grids{
                    let number = grid[row][col]
                    if number != 0{
                        counts[number, default: 0] += 1
                    }
                }
                // Find the number with the highest count
                if let mostFrequentNumber = counts.max(by:{ $0.value < $1.value })?.key{
                    masterGrid[row][col] = mostFrequentNumber
                }
            }
        }
        return masterGrid
    }

    // A more advanced filter to enhance local contrast and sharpen the image
    private func enhanceWithAdvancedContrast(image: UIImage) -> CGImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)

        // 1. Convert to grayscale
        let grayscaleFilter = CIFilter.photoEffectMono()
        grayscaleFilter.inputImage = ciImage
        
        guard let grayscaleOutput = grayscaleFilter.outputImage else{ return nil }

        // 2. Sharpen the image
        let sharpenFilter = CIFilter.unsharpMask()
        sharpenFilter.inputImage = grayscaleOutput
        sharpenFilter.radius = 2.5
        sharpenFilter.intensity = 0.7
        
        guard let sharpenedOutput = sharpenFilter.outputImage else{ return nil }

        // 3. Enhance local contrast
        let toneCurveFilter = CIFilter.toneCurve()
        toneCurveFilter.inputImage = sharpenedOutput
        // CORRECTED: Used CGPoint instead of CIVector for the points
        toneCurveFilter.point0 = CGPoint(x: 0.0, y: 0.0)
        toneCurveFilter.point1 = CGPoint(x: 0.25, y: 0.15)
        toneCurveFilter.point2 = CGPoint(x: 0.5, y: 0.5)
        toneCurveFilter.point3 = CGPoint(x: 0.75, y: 0.85)
        toneCurveFilter.point4 = CGPoint(x: 1.0, y: 1.0)

        if let outputImage = toneCurveFilter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent){
            return cgImage
        }
        return nil
    }

    // Filters for high contrast black & white
    private func enhanceWithMonochrome(image: UIImage) -> CGImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        // Removes all color
        filter.saturation = 0.0
        filter.contrast = 8.0
        if let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: ciImage.extent){
            return cgImage
        }
        return nil
    }
    
    // Filters to sharpen the image
    private func enhanceWithSharpen(image: UIImage) -> CGImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = ciImage
        filter.sharpness = 2.0 // A strong sharpen value
        if let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: outputImage.extent){
            return cgImage
        }
        return nil
    }
    
    // Filters for a high-contrast "noir" effect which is good for text
    private func enhanceWithNoir(image: UIImage) -> CGImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.photoEffectNoir()
        filter.inputImage = ciImage
        if let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: outputImage.extent){
            return cgImage
        }
        return nil
    }
    
    // Adds a new filter for dilation and erosion to enhance text
    private func enhanceWithDilationAndErosion(image: UIImage) -> CGImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)

        // Creates a grayscale version of the image first
        let grayscaleFilter = CIFilter.colorControls()
        grayscaleFilter.inputImage = ciImage
        grayscaleFilter.saturation = 0
        grayscaleFilter.contrast = 2.0 // Moderate contrast

        guard let grayscaleOutput = grayscaleFilter.outputImage else{ return nil }

        // Applies dilation to thicken the text
        let dilationFilter = CIFilter.morphologyMaximum()
        dilationFilter.inputImage = grayscaleOutput
        dilationFilter.radius = 1.0

        guard let dilatedOutput = dilationFilter.outputImage else{ return nil }

        if let cgImage = context.createCGImage(dilatedOutput, from: dilatedOutput.extent){
            return cgImage
        }
        return nil
    }

    // Core text recognition function
    private func recognizeText(in cgImage: CGImage, orientation: UIImage.Orientation, completion: @escaping ([[Int]]) -> Void) {
        let visionOrientation = CGImagePropertyOrientation(orientation)
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: visionOrientation)
        
        let request = VNRecognizeTextRequest { (request, error) in
            var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(grid)
                return
            }
            
            let frame = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            let cellWidth = frame.width / 9.0
            let cellHeight = frame.height / 9.0
            
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first,
                      let digit = Int(candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)) else { continue }
                
                let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(frame.width), Int(frame.height))
                let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
                
                let row = Int((frame.height - center.y) / cellHeight)
                let col = Int(center.x / cellWidth)
                
                if row >= 0 && row < 9 && col >= 0 && col < 9 {
                    if grid[row][col] == 0 { grid[row][col] = digit }
                }
            }
            completion(grid)
        }
        
        if #available(iOS 16.0, *) { request.revision = VNRecognizeTextRequestRevision3 }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // MODIFIED: A final, balanced adjustment to the text height
        request.minimumTextHeight = 0.008
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            }
            catch {
                completion(Array(repeating: Array(repeating: 0, count: 9), count: 9))
            }
        }
    }
}
