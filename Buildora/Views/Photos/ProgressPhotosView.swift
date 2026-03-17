import SwiftUI
import PhotosUI

struct ProgressPhotosView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var selectedPhase: PhotoPhase? = nil
    @State private var selectedPhoto: ProgressPhoto? = nil

    var filteredPhotos: [ProgressPhoto] {
        if let phase = selectedPhase { return dataVM.photos.filter { $0.phase == phase } }
        return dataVM.photos
    }

    var grouped: [(PhotoPhase, [ProgressPhoto])] {
        PhotoPhase.allCases.compactMap { phase in
            let items = filteredPhotos.filter { $0.phase == phase }
            return items.isEmpty ? nil : (phase, items)
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Phase filter
                    HStack(spacing: 8) {
                        Button("All") { withAnimation { selectedPhase = nil } }
                            .font(.bCaption())
                            .foregroundColor(selectedPhase == nil ? .white : .bNavy)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selectedPhase == nil ? Color.bNavy : Color.bGrayBeige).cornerRadius(20)

                        ForEach(PhotoPhase.allCases, id: \.self) { phase in
                            Button(action: { withAnimation { selectedPhase = selectedPhase == phase ? nil : phase } }) {
                                HStack(spacing: 5) {
                                    Image(systemName: phase.icon).font(.system(size: 12))
                                    Text(phase.rawValue).font(.bCaption())
                                }
                                .foregroundColor(selectedPhase == phase ? .white : Color(hex: phase.color))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(selectedPhase == phase ? Color(hex: phase.color) : Color(hex: phase.color).opacity(0.12)).cornerRadius(20)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)

                    if dataVM.photos.isEmpty {
                        BEmptyState(icon: "photo.on.rectangle", title: "No Photos Yet", subtitle: "Document your renovation progress", buttonTitle: "Add Photo", onButton: { showAdd = true })
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 20) {
                                ForEach(grouped, id: \.0) { (phase, photos) in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: phase.icon).foregroundColor(Color(hex: phase.color))
                                            Text(phase.rawValue).font(.bSubhead()).foregroundColor(.bNavy)
                                            Text("(\(photos.count))").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                                        }

                                        LazyVGrid(columns: columns, spacing: 8) {
                                            ForEach(photos) { photo in
                                                PhotoCell(photo: photo)
                                                    .environmentObject(dataVM)
                                                    .onTapGesture { selectedPhoto = photo }
                                            }
                                        }
                                    }
                                }
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BFAB(action: { showAdd = true }, color: .bGreen)
                            .padding(.trailing, 24).padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Progress Photos")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddPhotoView().environmentObject(dataVM).environmentObject(appState)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo).environmentObject(dataVM)
        }
    }
}

// MARK: - Photo Cell

struct PhotoCell: View {
    @EnvironmentObject var dataVM: DataViewModel
    let photo: ProgressPhoto

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let path = photo.imagePath,
                   let data = DataStore.shared.loadImage(from: path),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(hex: photo.phase.color).opacity(0.2)
                        Image(systemName: photo.phase.icon)
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: photo.phase.color))
                    }
                }
            }
            .frame(height: 110)
            .cornerRadius(14)
            .clipped()

            // Phase badge
            BTag(text: photo.phase.rawValue, color: Color(hex: photo.phase.color))
                .padding(6)
        }
        .cornerRadius(14)
        .bShadow(0.08)
    }
}

// MARK: - Photo Detail

struct PhotoDetailView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let photo: ProgressPhoto

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Image
                        if let path = photo.imagePath,
                           let data = DataStore.shared.loadImage(from: path),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                        } else {
                            ZStack {
                                Color(hex: photo.phase.color).opacity(0.2).cornerRadius(16)
                                VStack(spacing: 12) {
                                    Image(systemName: photo.phase.icon)
                                        .font(.system(size: 60)).foregroundColor(Color(hex: photo.phase.color))
                                    Text("No image").font(.bBody()).foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .frame(height: 300)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(photo.title).font(.bHeadline()).foregroundColor(.white)
                                Spacer()
                                BTag(text: photo.phase.rawValue, color: Color(hex: photo.phase.color))
                            }
                            Text(photo.createdAt.formatted(.dateTime.day().month().year()))
                                .font(.bCaption()).foregroundColor(.white.opacity(0.6))
                            if !photo.notes.isEmpty {
                                Text(photo.notes).font(.bBody()).foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(photo.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.white),
                trailing: Button(role: .destructive) {
                    dataVM.deletePhoto(photo)
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "trash").foregroundColor(.bRed)
                }
            )
        }
    }
}

// MARK: - Add Photo

struct AddPhotoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var phase: PhotoPhase = .during
    @State private var notes = ""
    @State private var selectedRoomId: UUID? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Image picker
                        Button(action: { showImagePicker = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.bGrayBeige)
                                    .frame(height: 200)
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(height: 200).cornerRadius(20).clipped()
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40)).foregroundColor(.bNavy.opacity(0.4))
                                        Text("Tap to select photo")
                                            .font(.bBody()).foregroundColor(.bNavy.opacity(0.5))
                                    }
                                }
                            }
                        }

                        BTextField(placeholder: "Photo title *", text: $title, icon: "photo")

                        // Phase selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phase").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            HStack(spacing: 8) {
                                ForEach(PhotoPhase.allCases, id: \.self) { p in
                                    Button(action: { phase = p }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: p.icon).font(.system(size: 14))
                                            Text(p.rawValue).font(.bCaption())
                                        }
                                        .foregroundColor(phase == p ? .white : Color(hex: p.color))
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(phase == p ? Color(hex: p.color) : Color(hex: p.color).opacity(0.1)).cornerRadius(12)
                                    }
                                }
                            }
                        }

                        // Room assignment
                        if !dataVM.rooms.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Room").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Button("General") { selectedRoomId = nil }
                                            .font(.bCaption())
                                            .foregroundColor(selectedRoomId == nil ? .white : .bNavy)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(selectedRoomId == nil ? Color.bNavy : Color.bGrayBeige).cornerRadius(20)
                                        ForEach(dataVM.rooms) { room in
                                            Button(room.name) { selectedRoomId = room.id }
                                                .font(.bCaption())
                                                .foregroundColor(selectedRoomId == room.id ? .white : .bNavy)
                                                .padding(.horizontal, 12).padding(.vertical, 8)
                                                .background(selectedRoomId == room.id ? Color.bBlue : Color.bGrayBeige).cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")
                        if !errorMsg.isEmpty { Text(errorMsg).font(.bCaption()).foregroundColor(.bRed) }
                        Button("Add Photo") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("New Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Please enter a title."; return }
        let imageData = selectedImage.flatMap { $0.jpegData(compressionQuality: 0.7) }
        dataVM.addPhoto(roomId: selectedRoomId, phase: phase, title: title, notes: notes, imageData: imageData)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Image Picker (UIViewControllerRepresentable)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
