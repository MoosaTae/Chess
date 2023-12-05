import SwiftUI

struct ChessboardView: UIViewRepresentable {
    func makeUIView(context: Context) -> Chessboard {
        let screenSize = UIScreen.main.bounds.size
        let chessboardSize = min(screenSize.width, screenSize.height)
        let chessboard = Chessboard(frame: CGRect(x: 0, y: 0, width: chessboardSize, height: chessboardSize))
        
        return chessboard
    }
    func updateUIView(_ uiView: Chessboard, context: Context) {
    }
}

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ChessboardView()
                    .aspectRatio(1.0, contentMode: .fit)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .edgesIgnoringSafeArea(.all)
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
