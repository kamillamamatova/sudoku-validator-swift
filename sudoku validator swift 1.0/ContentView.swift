import SwiftUI
import Vision

struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var validationMessage: String = ""
    @State private var finalGrid: [[Int]]? = nil
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Sudoku Validator")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .border(Color.gray, width: 2)
                } else {
                    ZStack {
                        Rectangle().fill(Color(.secondarySystemBackground))
                            .frame(width: 300, height: 300)
                            .border(Color.gray, width: 2)
                        Text("No image scanned").font(.headline).foregroundStyle(.secondary)
                    }
                }

                Button("Select Sudoku Image") {
                    self.validationMessage = ""
                    self.finalGrid = nil
                    self.isShowingCamera = true
                }
                .font(.title2).padding().background(Color.blue).foregroundStyle(.white).clipShape(Capsule())

                if capturedImage != nil {
                    Button(action: {
                        self.isProcessing = true
                        let gridProcessor = GridProcessor()
                        gridProcessor.process(image: self.capturedImage!) { grid in
                            self.finalGrid = grid
                            let validator = SudokuValidator()
                            let result = validator.validate(board: grid)
                            switch result {
                            case .validAndComplete: self.validationMessage = "Puzzle is Valid & Complete!"
                            case .validAndIncomplete: self.validationMessage = "Valid, but Incomplete."
                            case .invalid: self.validationMessage = "Invalid Puzzle."
                            }
                            self.isProcessing = false
                        }
                    }) {
                        if isProcessing {
                            HStack { ProgressView(); Text("Processing...") }
                        } else {
                            Text("Process Image for Numbers")
                        }
                    }
                    .font(.title2).padding().background(Color.green).foregroundStyle(.white).clipShape(Capsule())
                    .disabled(isProcessing)

                    Text(validationMessage).font(.title3).fontWeight(.medium).padding(.top, 5)

                    if let grid = finalGrid {
                        VStack(spacing: 2) {
                            Text("Final Processed Grid:").font(.headline).padding(.bottom, 5)
                            ForEach(0..<9, id: \.self) { row in
                                HStack(spacing: 2) {
                                    ForEach(0..<9, id: \.self) { col in
                                        Text("\(grid[row][col])")
                                            .font(.system(size: 14, design: .monospaced).bold())
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(grid[row][col] == 0 ? .red : .primary)
                                            .border(Color.gray, width: 0.5)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(selectedImage: $capturedImage)
            }
        }
    }
}
