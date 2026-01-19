import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void

        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let result = results.first else { return }

            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }

                    guard let uiImage = image as? UIImage else { return }

                    DispatchQueue.main.async {
                        self?.onImageSelected(uiImage)
                        AudioService.shared.playHaptic(.success)
                    }
                }
            }
        }
    }
}

struct PhotoGridPicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))

                    Text("Select a photo")
                        .font(AppFonts.heading(18))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundDark)
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        dismiss()
                    }
                }
            }
            .navigationTitle("Choose Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
