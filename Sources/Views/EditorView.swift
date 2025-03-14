import SwiftUI
import PhotosUI

struct EditorView: View {
    let project: Project
    let projectManager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    @State private var items: [CollageItem] = []
    @State private var selectedItem: CollageItem?
    @State private var background: Color = .white
    @State private var backgroundImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingBackgroundPicker = false
    @State private var format: CanvasFormat = .square
    @State private var canvasSize: CGSize = .zero
    @State private var showingExportConfirmation = false
    
    // Undo/redo state
    @State private var undoStack: [(items: [CollageItem], background: Color, backgroundImage: UIImage?)] = []
    @State private var redoStack: [(items: [CollageItem], background: Color, backgroundImage: UIImage?)] = []
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear  // Background that covers entire screen
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = nil
                }
                .overlay {
                    ScrollView([.horizontal, .vertical]) {
                        let size = format.size(fitting: geometry.size.width, height: geometry.size.height)
                        
                        ZStack {
                            BackgroundView(backgroundImage: backgroundImage, backgroundColor: background)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = nil
                                }
                            CollageItemsView(
                                items: $items,
                                selectedItem: $selectedItem,
                                canvasSize: size,
                                onItemsChanged: saveState
                            )
                        }
                        .frame(width: size.width, height: size.height)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 8)
                        .onAppear {
                            canvasSize = size
                            loadProjectState()
                        }
                        .onChange(of: format) { _ in
                            canvasSize = size
                        }
                    }
                    .background(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = nil
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker { image in
                        var newItem = CollageItem.newPhoto(image: image)
                        newItem.position = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
                        items.append(newItem)
                        selectedItem = newItem
                        saveState()
                    }
                }
                .sheet(isPresented: $showingBackgroundPicker) {
                    BackgroundPicker(color: $background, image: $backgroundImage)
                }
                .alert("Success", isPresented: $showingExportConfirmation) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Image saved to photo library")
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        // Item-specific controls
                        if let selectedItem = selectedItem {
                            ItemControlsView(
                                item: binding(for: selectedItem),
                                onDelete: {
                                    if let index = items.firstIndex(where: { $0.id == selectedItem.id }) {
                                        items.remove(at: index)
                                        self.selectedItem = nil
                                        saveState()
                                    }
                                }
                            )
                            .transition(.move(edge: .bottom))
                            .padding(.vertical, 8)
                        }
                        
                        Divider()
                        
                        // Bottom toolbar
                        VStack(spacing: 16) {
                            if selectedItem == nil {
                                // Format picker only shown when no item is selected
                                Picker("Format", selection: $format) {
                                    ForEach(CanvasFormat.allCases, id: \.self) { format in
                                        Text(format.rawValue).tag(format)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                // Main actions
                                HStack(spacing: 32) {
                                    Button(action: { showingImagePicker = true }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "photo")
                                                .font(.title2)
                                            Text("Add Photo")
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Button(action: {
                                        var newItem = CollageItem.newText()
                                        newItem.position = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
                                        items.append(newItem)
                                        selectedItem = newItem
                                        saveState()
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "textformat")
                                                .font(.title2)
                                            Text("Add Text")
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Button(action: { showingBackgroundPicker = true }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "rectangle.fill")
                                                .font(.title2)
                                            Text("Background")
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .background(.ultraThinMaterial)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: exportToGallery) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 16) {
                            Button(action: undo) {
                                Image(systemName: "arrow.uturn.backward")
                            }
                            .disabled(undoStack.isEmpty)
                            
                            Button(action: redo) {
                                Image(systemName: "arrow.uturn.forward")
                            }
                            .disabled(redoStack.isEmpty)
                        }
                    }
                }
                .onDisappear {
                    saveProjectState()
                }
        }
    }
    
    private func loadProjectState() {
        if let savedData = projectManager.loadProject(project) {
            // First set the format if it was saved
            format = savedData.format
            
            // Initialize canvas size before setting items
            let screenSize = UIScreen.main.bounds.size
            canvasSize = format.size(fitting: screenSize.width, height: screenSize.height)
            
            // Now set the items and other state
            items = savedData.items
            background = savedData.background
            backgroundImage = savedData.backgroundImage
            
            // Ensure all items have valid positions within the canvas
            for (index, item) in items.enumerated() {
                var updatedItem = item
                // If position is zero or outside bounds, center it
                if item.position == .zero || 
                   item.position.x < 0 || item.position.x > canvasSize.width ||
                   item.position.y < 0 || item.position.y > canvasSize.height {
                    updatedItem.position = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
                    items[index] = updatedItem
                }
            }
        }
    }
    
    private func saveProjectState() {
        projectManager.saveProject(
            project,
            items: items,
            background: background,
            backgroundImage: backgroundImage,
            format: format
        )
    }
    
    private func exportToGallery() {
        let renderer = ImageRenderer(content: 
            ZStack {
                BackgroundView(backgroundImage: backgroundImage, backgroundColor: background)
                CollageItemsView(
                    items: $items,
                    selectedItem: .constant(nil),
                    canvasSize: canvasSize,
                    onItemsChanged: {}  // Empty closure since we don't need to track changes during export
                )
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .background(Color.white)
        )
        
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showingExportConfirmation = true
        }
    }
    
    private func saveState() {
        undoStack.append((items: items, background: background, backgroundImage: backgroundImage))
        redoStack.removeAll() // Clear redo stack when new changes are made
        saveProjectState()
    }
    
    private func undo() {
        guard !undoStack.isEmpty else { return }
        let currentState = (items: items, background: background, backgroundImage: backgroundImage)
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        items = previousState.items
        background = previousState.background
        backgroundImage = previousState.backgroundImage
        saveProjectState()
    }
    
    private func redo() {
        guard !redoStack.isEmpty else { return }
        let currentState = (items: items, background: background, backgroundImage: backgroundImage)
        undoStack.append(currentState)
        
        let nextState = redoStack.removeLast()
        items = nextState.items
        background = nextState.background
        backgroundImage = nextState.backgroundImage
        saveProjectState()
    }
    
    private func binding(for item: CollageItem) -> Binding<CollageItem> {
        Binding(
            get: {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    return items[index]
                }
                return item
            },
            set: { newValue in
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = newValue
                    saveState()
                }
            }
        )
    }
}

private struct ItemControlsView: View {
    @Binding var item: CollageItem
    @State private var borderWidth: CGFloat = 0
    @State private var fontSize: CGFloat = 24
    let onDelete: () -> Void
    
    var body: some View {
        Group {
            switch item.type {
            case .photo:
                VStack(spacing: 8) {
                    HStack {
                        Text("Border")
                        Slider(value: $borderWidth, in: 0...10)
                            .onChange(of: borderWidth) { newValue in
                                var updatedItem = item
                                updatedItem.borderWidth = newValue
                                item = updatedItem
                            }
                        ColorPicker("", selection: Binding(
                            get: { item.borderColor },
                            set: { newValue in
                                var updatedItem = item
                                updatedItem.borderColor = newValue
                                item = updatedItem
                            }
                        ))
                    }
                    Toggle("Remove Background", isOn: Binding(
                        get: { item.hasBackground },
                        set: { newValue in
                            var updatedItem = item
                            updatedItem.hasBackground = newValue
                            item = updatedItem
                        }
                    ))
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                    .padding(.top, 8)
                }
                .onAppear {
                    borderWidth = item.borderWidth
                }
            case .text:
                VStack(spacing: 8) {
                    TextField("Text", text: Binding(
                        get: { item.text },
                        set: { newValue in
                            var updatedItem = item
                            updatedItem.text = newValue
                            item = updatedItem
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    HStack {
                        Text("Size")
                        Slider(value: $fontSize, in: 10...72)
                            .onChange(of: fontSize) { newValue in
                                var updatedItem = item
                                updatedItem.fontSize = newValue
                                item = updatedItem
                            }
                        ColorPicker("", selection: Binding(
                            get: { item.textColor },
                            set: { newValue in
                                var updatedItem = item
                                updatedItem.textColor = newValue
                                item = updatedItem
                            }
                        ))
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                    .padding(.top, 8)
                }
                .onAppear {
                    fontSize = item.fontSize
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct BackgroundView: View {
    let backgroundImage: UIImage?
    let backgroundColor: Color
    
    var body: some View {
        if let backgroundImage = backgroundImage {
            Image(uiImage: backgroundImage)
                .resizable()
                .scaledToFill()
        } else {
            backgroundColor
        }
    }
}

private struct CollageItemsView: View {
    @Binding var items: [CollageItem]
    @Binding var selectedItem: CollageItem?
    let canvasSize: CGSize
    let onItemsChanged: () -> Void
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            ForEach(items) { item in
                CollageItemView(item: binding(for: item), isSelected: item.id == selectedItem?.id)
                    .position(item.position)
                    .frame(width: item.size.width, height: item.size.height)
                    .rotationEffect(item.rotation)
                    .zIndex(item.zIndex)
                    .gesture(
                        TapGesture()
                            .onEnded {
                                if selectedItem?.id == item.id {
                                    selectedItem = nil
                                } else {
                                    selectedItem = item
                                }
                            }
                    )
                    .gesture(dragGesture(for: item))
                    .allowsHitTesting(true)
            }
        }
        .gesture(
            selectedItem != nil ?
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        guard let selectedItem = selectedItem,
                              let index = items.firstIndex(where: { $0.id == selectedItem.id }) else { return }
                        
                        var updatedItem = items[index]
                        let scaleDiff = scale / lastScale
                        updatedItem.size = CGSize(
                            width: updatedItem.size.width * scaleDiff,
                            height: updatedItem.size.height * scaleDiff
                        )
                        items[index] = updatedItem
                        lastScale = scale
                        onItemsChanged()
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        onItemsChanged()
                    },
                RotationGesture()
                    .onChanged { angle in
                        guard let selectedItem = selectedItem,
                              let index = items.firstIndex(where: { $0.id == selectedItem.id }) else { return }
                        
                        var updatedItem = items[index]
                        updatedItem.rotation = angle
                        items[index] = updatedItem
                        onItemsChanged()
                    }
            )
            : nil
        )
    }
    
    private func binding(for item: CollageItem) -> Binding<CollageItem> {
        Binding(
            get: {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    return items[index]
                }
                return item
            },
            set: { newValue in
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = newValue
                    onItemsChanged()
                }
            }
        )
    }
    
    private func dragGesture(for item: CollageItem) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    var updatedItem = items[index]
                    updatedItem.position = value.location
                    items[index] = updatedItem
                    if selectedItem?.id != item.id {
                        selectedItem = item
                    }
                    onItemsChanged()
                }
            }
    }
}

struct CollageItemView: View {
    @Binding var item: CollageItem
    var isSelected: Bool
    
    var body: some View {
        Group {
            if item.type == .photo {
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .if(!item.hasBackground) { view in
                            view.colorInvert()
                                .background(Color.black)
                                .colorInvert()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(item.borderColor, lineWidth: item.borderWidth)
                        )
                }
            } else {
                Text(item.text)
                    .font(.custom(item.font, size: item.fontSize))
                    .foregroundColor(item.textColor)
                    .multilineTextAlignment(.center)
            }
        }
        .overlay(
            isSelected ?
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue, lineWidth: 2)
                .padding(-4) : nil
        )
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onSelect: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelect: (UIImage) -> Void
        
        init(onSelect: @escaping (UIImage) -> Void) {
            self.onSelect = onSelect
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self?.onSelect(image)
                    }
                }
            }
        }
    }
}

struct BackgroundPicker: View {
    @Binding var color: Color
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Color") {
                    ColorPicker("Choose color", selection: $color)
                }
                
                Section("Image") {
                    Button("Choose image") {
                        showingImagePicker = true
                    }
                    
                    if image != nil {
                        Button("Remove image", role: .destructive) {
                            image = nil
                        }
                    }
                }
            }
            .navigationTitle("Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { selectedImage in
                    image = selectedImage
                }
            }
        }
    }
}

#Preview {
    EditorView(project: Project(name: "Test Project", thumbnail: nil, lastModified: Date()), projectManager: ProjectManager())
} 
