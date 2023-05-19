//
//  ImagePicker.swift
//  film24
//
//  Created by Igor Ryazancev on 15.05.2023.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    
    @Binding var showPicker: Bool
    var selectionLimit: Int
    
    var videoSelected: ((URL?)->())
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = selectionLimit
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {

        var parent: ImagePickerView
        
        init(parent: ImagePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            parent.showPicker.toggle()
            
            for result in results {
                let prov = result.itemProvider
                prov.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, err in
                    guard let url = url else { return }
                    
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                    guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else { return }
                    
                    do {
                        if FileManager.default.fileExists(atPath: targetURL.path) {
                            try FileManager.default.removeItem(at: targetURL)
                        }
                        
                        try FileManager.default.copyItem(at: url, to: targetURL)
                        
                        DispatchQueue.main.sync { [weak self] in
                            self?.parent.videoSelected(targetURL)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                }
            }
        }
    }
}
