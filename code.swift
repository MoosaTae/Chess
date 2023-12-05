import UIKit

enum GameState {
    case waitingForSelection
    case pieceSelected(ChessPiece)
    case checkmate(UIColor)
}

class Chessboard: UIView {
    var boardSquares: [[UIView]] = []
    var pieces: [[ChessPiece?]] = []
    let boardSize = 8
    var currentPlayer: UIColor = .white
    var gameState: GameState = .waitingForSelection
    var highlightedSquares: [UIView] = []
    
    var squareSize: CGFloat
    override init(frame: CGRect) {
        squareSize = frame.width / CGFloat(boardSize)
        
        super.init(frame: frame)
        self.setupBoard()
        self.setupPieces()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBoard() {
        for row in 0..<boardSize {
            var squareRow: [UIView] = []
            var pieceRow: [ChessPiece?] = []
            for col in 0..<boardSize {
                let squareFrame = CGRect(x: CGFloat(col) * squareSize, y: CGFloat(row) * squareSize, width: squareSize, height: squareSize)
                let square = UIView(frame: squareFrame)
                
                if (row + col) % 2 == 0 {
                    square.backgroundColor = UIColor(red: 1, green: 1, blue: 0.94, alpha: 1)
                } else {
                    square.backgroundColor = UIColor(red: 0.133, green: 0.545, blue: 0.133, alpha: 0.8)
                }
                
                self.addSubview(square)
                squareRow.append(square)
                pieceRow.append(nil)
            }
            boardSquares.append(squareRow)
            pieces.append(pieceRow)
        }
    }
    
    private func setupPieces() {
        let pieceNames = ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
        let pawn = "pawn"
        
        for (index, pieceName) in pieceNames.enumerated() {
            addPiece(type: pieceName, color: .black, row: 0, col: index)
            addPiece(type: pawn, color: .black, row: 1, col: index)
            addPiece(type: pieceName, color: .white, row: boardSize - 1, col: index)
            addPiece(type: pawn, color: .white, row: boardSize - 2, col: index)
        }
        
    }
    
    private func addPiece(type: String, color: UIColor, row: Int, col: Int) {
        let pieceFrame = CGRect(x: CGFloat(col) * squareSize, y: CGFloat(row) * squareSize, width: squareSize, height: squareSize)
        
        let piece : ChessPiece
        switch type {
            case "rook":
                piece = Rook(color: color, type: type, frame: pieceFrame, row: row, col: col)
            case "knight":
                piece = Knight(color: color, type: type, frame: pieceFrame, row: row, col: col)
            case "bishop":
                piece = Bishop(color: color, type: type, frame: pieceFrame, row: row, col: col)
            case "queen":
                piece = Queen(color: color, type: type, frame: pieceFrame, row: row, col: col)
            case "king":
                piece = King(color: color, type: type, frame: pieceFrame, row: row, col: col)
            case "pawn":
                piece = Pawn(color: color, type: type, frame: pieceFrame, row: row, col: col)
            default:
                return
        }
        self.addSubview(piece)
        self.pieces[row][col] = piece
    }
    
    func pieceAt(row: Int, col: Int) -> ChessPiece? {
        return pieces[row][col]
    }
    
    private func movePiece(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) {
        guard let piece = pieces[fromRow][fromCol] else {
            return
        }
        if let capturedPiece = pieces[toRow][toCol], capturedPiece.color != piece.color {
            capturedPiece.removeFromSuperview()
        }
        
        piece.row = toRow
        piece.col = toCol
        piece.frame.origin = CGPoint(x: CGFloat(toCol) * squareSize, y: CGFloat(toRow) * squareSize)
        
        pieces[fromRow][fromCol] = nil
        pieces[toRow][toCol] = piece
    }
    
    private func drawPossibleMoves(for piece: ChessPiece) {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if piece.isValidMove(toRow: row, toCol: col, onBoard: self) && canMoveSafely(piece: piece, toRow: row, toCol: col) {
                    let square = boardSquares[row][col]
                    let destinationPiece = pieceAt(row: row, col: col)
                    
                    if destinationPiece == nil {
                        let circleSize: CGFloat = frame.width / 25
                        let circleFrame = CGRect(x: (square.frame.width - circleSize) / 2,
                                                 y: (square.frame.height - circleSize) / 2,
                                                 width: circleSize,
                                                 height: circleSize)
                        let circle = UIView(frame: circleFrame)
                        circle.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
                        circle.layer.cornerRadius = circleSize / 2
                        square.addSubview(circle)
                        highlightedSquares.append(circle)
                    } else if destinationPiece?.color != piece.color {
                        let highlight = UIView(frame: square.bounds)
                        highlight.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                        square.addSubview(highlight)
                        highlightedSquares.append(highlight)
                    }
                }
            }
        }
    }
    private func clearHighlightedSquares() {
        for square in highlightedSquares {
            square.removeFromSuperview()
        }
        highlightedSquares.removeAll()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let row = Int(location.y / squareSize)
            let col = Int(location.x / squareSize)
            
            // state
            switch gameState {
            case .waitingForSelection:
                if let piece = pieceAt(row: row, col: col), piece.color == currentPlayer {
                    gameState = .pieceSelected(piece)
                    
                    drawPossibleMoves(for: piece)
                }
            case .pieceSelected(let selectedPiece):
                clearHighlightedSquares()
                
                if let destinationPiece = pieceAt(row: row, col: col), destinationPiece.color == currentPlayer {
                    gameState = .pieceSelected(destinationPiece)
                    drawPossibleMoves(for: destinationPiece)
                } else {
                    if selectedPiece.isValidMove(toRow: row, toCol: col, onBoard: self) && canMoveSafely(piece: selectedPiece, toRow: row, toCol: col) {
                        movePiece(fromRow: selectedPiece.row, fromCol: selectedPiece.col, toRow: row, toCol: col)
                        currentPlayer = currentPlayer == .white ? .black : .white
                        updateGameStateAfterMove()
                        if case .checkmate(_) = gameState {
                            
                        }
                        gameState = .waitingForSelection
                    }
                    else {
                        gameState = .waitingForSelection
                    }
                }
            default:
                break
            }
        }
    }
    
    func getCurrentPlayerKing() -> King? {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let king = pieceAt(row: row, col: col) as? King, king.color == currentPlayer {
                    return king
                }
            }
        }
        return nil
    }
    
    func isKingInCheck(king: King, ignoredPiece: ChessPiece? = nil) -> Bool {
        for pieceRow in pieces {
            for piece in pieceRow {
                if let piece = piece, piece.color != king.color, piece !== ignoredPiece {
                    if piece.isValidMove(toRow: king.row, toCol: king.col, onBoard: self) {
                        return true
                    }
                }
            }
        }
        return false
    }

    func isCheckmate(king: King) -> Bool {
        for pieceRow in pieces {
            for piece in pieceRow {
                if let piece = piece, piece.color == currentPlayer {
                    for newRow in 0..<boardSize {
                        for newCol in 0..<boardSize {
                            if piece.isValidMove(toRow: newRow, toCol: newCol, onBoard: self) && canMoveSafely(piece: piece, toRow: newRow, toCol: newCol) {
                                return false
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    func canMoveSafely(piece: ChessPiece, toRow: Int, toCol: Int) -> Bool {
        guard let currentPlayerKing = getCurrentPlayerKing() else {
            return false
        }
        let fromRow = piece.row
        let fromCol = piece.col
        let originalDestinationPiece = pieceAt(row: toRow, col: toCol)
        if let originalDestinationPiece = originalDestinationPiece {
            originalDestinationPiece.removeFromSuperview()
            pieces[toRow][toCol] = nil
        }
        movePiece(fromRow: fromRow, fromCol: fromCol, toRow: toRow, toCol: toCol)
        
        let opponentColor = piece.color == UIColor.white ? UIColor.black : UIColor.white
        let isSafe = !(piece is King) ? !isSquareAttacked(row: currentPlayerKing.row, col: currentPlayerKing.col, byColor: opponentColor) : !isSquareAttacked(row: toRow, col: toCol, byColor: opponentColor, ignorePiece: originalDestinationPiece)
        movePiece(fromRow: toRow, fromCol: toCol, toRow: fromRow, toCol: fromCol)
        
        if let originalDestinationPiece = originalDestinationPiece {
            addPiece(type: originalDestinationPiece.type, color: originalDestinationPiece.color, row: toRow, col: toCol)
        }
        return isSafe
    }
    
    func isSquareAttacked(row: Int, col: Int, byColor: UIColor, ignorePiece: ChessPiece? = nil) -> Bool {
        for pieceRow in pieces {
            for piece in pieceRow {
                if let piece = piece, piece.color == byColor, piece !== ignorePiece {
                    if piece.isValidMove(toRow: row, toCol: col, onBoard: self) {
                        return true
                    }
                }
            }
        }
        return false
    }

    func updateGameStateAfterMove() {
        if let currentPlayerKing = getCurrentPlayerKing() {
            if isKingInCheck(king: currentPlayerKing) {
//                print("Check!")
                if isCheckmate(king: currentPlayerKing) {
//                    print("\(currentPlayer == .white ? "White" : "Black") wins Checkmate!!")
                    gameState = .checkmate(currentPlayer)
                    displayCheckmateAlert()
                    
                }
            }
        }
    }
    
    func displayCheckmateAlert() {
        let alertController = UIAlertController(title: "\(currentPlayer == .white ? "Black" : "White") wins Checkmate!!", message: "Game Over", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Restart", style: .default, handler: { _ in
            self.restartGame()
        }))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func restartGame() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let piece = pieceAt(row: row, col: col) {
                    piece.removeFromSuperview()
                    pieces[row][col] = nil
                }
            }
        }
        setupPieces()
        
        currentPlayer = .white
        gameState = .waitingForSelection
    }
}

class ChessPiece: UIView {
    let color: UIColor
    let type: String
    var row: Int
    var col: Int
    
    init(color: UIColor, type: String, frame: CGRect, row: Int, col: Int) {
        self.color = color
        self.type = type
        self.row = row
        self.col = col
        super.init(frame: frame)
        self.setupPiece()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
        return false
    }

    private func setupPiece() {
        self.backgroundColor = .clear
        let imageViewSize = CGSize(width: self.frame.width , height: self.frame.height)
        let imageViewOrigin = CGPoint(x: (self.frame.width - imageViewSize.width) / 2, y: (self.frame.height - imageViewSize.height) / 2)
        let imageView = UIImageView(frame: CGRect(origin: imageViewOrigin, size: imageViewSize))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "\(self.color == .white ? "white" : "black")_\(self.type.lowercased())")
        self.addSubview(imageView)
    }
}

class Rook: ChessPiece {
    override func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
        if row != toRow && col != toCol {
            return false
        }
        let rowStep = row < toRow ? 1 : -1
        let colStep = col < toCol ? 1 : -1
        var currentRow = row + (row == toRow ? 0 : rowStep)
        var currentCol = col + (col == toCol ? 0 : colStep)
        
        while (currentRow != toRow || currentCol != toCol) {
            if board.pieceAt(row: currentRow, col: currentCol) != nil {
                return false
            }
            currentRow += row == toRow ? 0 : rowStep
            currentCol += col == toCol ? 0 : colStep
        }
        
        return true
    }
}

class Bishop: ChessPiece {
    override func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
        if abs(row - toRow) != abs(col - toCol) {
            return false
        }
        let rowStep = row < toRow ? 1 : -1
        let colStep = col < toCol ? 1 : -1
        var currentRow = row + rowStep
        var currentCol = col + colStep
        
        while currentRow != toRow && currentCol != toCol && currentRow >= 0 && currentRow < board.boardSize && currentCol >= 0 && currentCol < board.boardSize {
            if board.pieceAt(row: currentRow, col: currentCol) != nil {
                return false
            }
            currentRow += rowStep
            currentCol += colStep
        }
        return true
    }
}

class Knight: ChessPiece {
    override func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
        let rowDiff = abs(toRow - row)
        let colDiff = abs(toCol - col)
        return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2)
    }
}

class Queen: ChessPiece {
    override func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
       
        let rowDiff = abs(toRow - row)
        let colDiff = abs(toCol - col)
        if toRow != row && toCol != col && rowDiff != colDiff {
            return false
        }

        let rowStep = row < toRow ? 1 : -1
        let colStep = col < toCol ? 1 : -1
        var currentRow = row + (row == toRow ? 0 : rowStep)
        var currentCol = col + (col == toCol ? 0 : colStep)

        while (currentRow != toRow || currentCol != toCol) {
            if board.pieceAt(row: currentRow, col: currentCol) != nil {
                return false
            }
            currentRow += row == toRow ? 0 : rowStep
            currentCol += col == toCol ? 0 : colStep
        }
        return true
    }
}

class King: ChessPiece {
    override func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
        let rowDiff = abs(toRow - row)
        let colDiff = abs(toCol - col)
        let opponentColor = self.color == UIColor.white ? UIColor.black : UIColor.white
        
        if rowDiff <= 1 && colDiff <= 1 && !board.isSquareAttacked(row: toRow, col: toCol, byColor: opponentColor) {
            if let destinationPiece = board.pieceAt(row: toRow, col: toCol) {
                if destinationPiece.color == self.color {
                    return false
                }
            }
            return true
        }
        return false
    }
}

class Pawn: ChessPiece {
    override func isValidMove(toRow: Int, toCol: Int, onBoard board: Chessboard) -> Bool {
        let direction = color == .white ? -1 : 1
        let initialRow = color == .white ? board.boardSize - 2 : 1
        let rowDiff = toRow - row
        if toCol == col && rowDiff == direction && board.pieceAt(row: toRow, col: toCol) == nil {
            return true
        }
        
        if toCol == col && row == initialRow && rowDiff == 2 * direction && board.pieceAt(row: toRow, col: toCol) == nil && board.pieceAt(row: row + direction, col: col) == nil {
            return true
        }
        
        if abs(toCol - col) == 1 && rowDiff == direction, let destinationPiece = board.pieceAt(row: toRow, col: toCol), destinationPiece.color != color {
            return true
        }
        return false
    }
}

let boardFrame = CGRect(x: 0, y: 0, width: 400, height: 400)
let chessboard = Chessboard(frame: boardFrame)

//PlaygroundPage.current.liveView = chessboard
