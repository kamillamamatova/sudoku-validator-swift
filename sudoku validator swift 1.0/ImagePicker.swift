import SwiftUI
import UIKit

// Bridge between UIKit's camera view and SwiftUI
struct ImagePicker: UIViewControllerRepresentable{
    // Holds the image the user selects or captures
    // A 'Binding' is a special two way connection to a @State variable in another view
    @Binding var selectedImage: UIImage?
    
    // Dismisses the camera view once a picture is taken
    @Environment(\.presentationMode) private var presentationMode
    
    // Creates the UIKit view controller
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        
        /* Checks if the camera is actually available on this device
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            // Uses the camera, not the photo library. For a simulator, this will automatically fall back to the photo library.
            imagePicker.sourceType = .camera
        }
        // If the camera isn't avaiable, it falls back on the photo library
        else{
            imagePicker.sourceType = .photoLibrary
        }*/
        
        // For debugging
        imagePicker.sourceType = .photoLibrary
        
        // 'context.coordinator' is the object that will receive messages from the camera view
        imagePicker.delegate = context.coordinator
        
        return imagePicker
    }
    
    // Required function
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context){}
    
    // SwiftUI uses this function to create the 'Coordinator'
    func makeCoordinator() -> Coordinator{
        Coordinator(parent: self)
    }
    
    // Handles communication from the UIImagePickerController
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
        var parent: ImagePicker
        
        init(parent: ImagePicker){
            self.parent = parent
        }
        
        // Called when the user finishes taking a picture
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
            // Unwraps the image from the dictionary and assigns it to the binding
            if let image = info[.originalImage] as? UIImage{
                parent.selectedImage = image
            }
            // Dismisses the camera view
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
