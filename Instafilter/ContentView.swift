//
//  ContentView.swift
//  Instafilter
//
//  Created by Scott Obara on 15/2/21.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var showRadiusSlider = false
    @State private var filterRadius = 0.5
    
    @State private var showingFilterSheet = false
    @State private var showingImagePicker = false
    @State private var showingNoImageAlert = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    
    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)

                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }
                
                HStack {
                    Text("\(currentFilter.name)")
                        .font(.subheadline)
                        .padding(0.0)
                        //.textCase(.uppercase)
                        .foregroundColor(.secondary)
                    Spacer()
                }.padding(.top)
                
                HStack {
                    Text("Intensity")
                        .frame(width: 70)
                    Slider(value: intensity)
                }
                
                if showRadiusSlider {
                    HStack {
                        Text("Center")
                            .frame(width: 70)
                        Slider(value: radius)
                    }.transition(.slide)
                }
                

                HStack {
                    Button("Change Filter") {
                        self.showingFilterSheet = true
                    }

                    Spacer()

                    Button("Save") {
                        guard let processedImage = self.processedImage else {
                            showingNoImageAlert = true
                            return }

//                        let imageSaver = ImageSaver()
//                        imageSaver.writeToPhotoAlbum(image: processedImage)
                        
                        let imageSaver = ImageSaver()

                        imageSaver.successHandler = {
                            print("Success!")
                        }

                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                        }

                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
                .padding(.top)
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .alert(isPresented: $showingNoImageAlert) {
                Alert(title: Text("No Image Selected"), message: Text("Please chose an image before saving."), dismissButton: .default(Text("Okay")) {self.showingNoImageAlert = false})
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize()) },
                    .default(Text("Edges")) { self.setFilter(CIFilter.edges()) },
                    .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur()) },
                    .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate()) },
                    .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone()) },
                    .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask()) },
                    .default(Text("Vignette")) { self.setFilter(CIFilter.vignette()) },
                    .cancel()
                ])
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
//        image = Image(uiImage: inputImage)
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }

    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) && inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
            currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey)
            withAnimation {
                showRadiusSlider = true
            }
        }
        else {
            withAnimation {
                showRadiusSlider = false
            }
            if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
            if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
            if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
        }

        guard let outputImage = currentFilter.outputImage else { return }

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
