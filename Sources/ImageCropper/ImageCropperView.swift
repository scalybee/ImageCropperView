//
//  ImageCropperView.swift
//  ImageCropper
//
//  Created by Hetul Soni on 16/01/23.
//

import SwiftUI

public struct ImageCropperView: View {
    
    public struct CropperConfig {
        let inset: CGFloat
        let bgColor: Color
        /// Used for action button color
        let tintColor: Color
        let overlayColor: Color
        let actionBannerColor: Color 
        
        public init(inset: CGFloat = 40, bgColor: Color = Color.white, tintColor: Color = Color.white, overlayColor: Color = Color.gray.opacity(0.5), actionBannerColor: Color = Color.black.opacity(0.4)) {
            self.inset = inset
            self.bgColor = bgColor
            self.tintColor = tintColor
            self.overlayColor = overlayColor
            self.actionBannerColor = actionBannerColor
        }
    }
        
    @StateObject var viewModel: ImageMoveViewModel
    
    /// The displayImage is what wee see on this view.
    // Display Params
    @State var displayedImage: UIImage?
    @State var displayW: CGFloat = 0.0
    @State var displayH: CGFloat = 0.0
    
    // Image Params
    var imageAttributes: ImageAttributes
    var cropperConfig: CropperConfig
    
    // Zoom Params
    @State var currentAmount: CGFloat = 0
    @State var zoomAmount: CGFloat = 1.0
    @State var currentPosition: CGSize = .zero
    @State var newPosition: CGSize = .zero
    @State var horizontalOffset: CGFloat = 0.0
    @State var verticalOffset: CGFloat = 0.0
    
    /// The input image is received from the ImagePicker.
    /// We will need to calculate and refer to its aspectr ratio
    /// in the functions found in the extensions file.
    @State var inputImage: UIImage?
    
    /// The input image aspect ratio
    @State var inputImageAspectRatio: CGFloat = 0.0
    
    var completion: (Result<UIImage, Error>) -> Void
    var navigationController: UINavigationController
    
    public init(navController: UINavigationController, viewModel: ImageMoveViewModel = .init(scale: 1, xWidth: 0, yHeight: 0), config: CropperConfig = CropperConfig(), imageAttributes: ImageAttributes, completion: @escaping(Result<UIImage, Error>) -> Void) {
        navigationController = navController
        _viewModel = StateObject(wrappedValue: viewModel)
        cropperConfig = config
        self.imageAttributes = imageAttributes
        self.completion = completion
    }
    
    public var body: some View {
        ZStack {
            ZStack {
                cropperConfig.bgColor
                if let originalImage = viewModel.originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaleEffect(zoomAmount + currentAmount)
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .offset(x: self.currentPosition.width, y: self.currentPosition.height)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                } else {
                    viewModel.image
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .padding(cropperConfig.inset * 2)
                }
            }
            
            Rectangle()
                .fill(cropperConfig.overlayColor)
                .mask(rectangleShapeMask().fill(style: FillStyle(eoFill: true)))
            
            VStack(spacing: 0) {
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        navigationController.dismiss(animated: true)
                    } label: {
                        Text("Close")
                            .foregroundColor(cropperConfig.tintColor)
                    }
                    Spacer()
                    Button {
                        let result = composeImageAttributes()
                        completion(result)
                        navigationController.dismiss(animated: true)
                    } label: {
                        Text("Save")
                            .foregroundColor(cropperConfig.tintColor)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 20)
                .background(cropperConfig.actionBannerColor)
            }
            .padding(.bottom, UIDevice.current.hasNotch ? 50 : 5)
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            viewModel.loadImageAttributes(imageAttributes)
        }
        .gesture(
            MagnificationGesture()
                .onChanged { amount in
                    self.currentAmount = amount - 1
                }
                .onEnded { _ in
                    self.zoomAmount += self.currentAmount
                    if zoomAmount > 4.0 {
                        withAnimation {
                            zoomAmount = 4.0
                        }
                    }
                    self.currentAmount = 0
                    withAnimation {
                        repositionImage()
                    }
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                }
                .onEnded { value in
                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                    self.newPosition = self.currentPosition
                    withAnimation {
                        repositionImage()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded({ resetImageOriginAndScale()
                })
        )
        .onAppear {
            setCurrentImage()
        }
    }
}

// MARK: - Masking methods
extension ImageCropperView {
    func rectangleShapeMask() -> Path {
        let rect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        let insetRect = CGRect(x: cropperConfig.inset, y: (UIScreen.main.bounds.size.height * 0.5 - ((UIScreen.main.bounds.size.width * 0.5) - cropperConfig.inset)), width: UIScreen.main.bounds.size.width - ( cropperConfig.inset * 2 ), height: UIScreen.main.bounds.size.width - ( cropperConfig.inset * 2 ))
        var shape = Rectangle().path(in: rect)
        shape.addPath(Rectangle().path(in: insetRect))
        return shape
    }
}
struct ImageCropperViewPreview: PreviewProvider {
    static var previews: some View {
        ImageCropperView(navController: UINavigationController(), viewModel: ImageMoveViewModel(scale: 1, xWidth: 0, yHeight: 0), imageAttributes: ImageAttributes(originalImage: UIImage(named: "banner2.png")!, scale: 1, xWidth: 0, yHeight: 0)) { _ in
        }
    }
}
