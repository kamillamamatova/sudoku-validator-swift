import Foundation

struct SudokuValidator{
    
    // Checks the entire board
    // Calls three helper functions to check rows, columns, and the 3 x 3 squares
    func isValid(board: [[Int]]) -> Bool{
        return areRowsValid(board: board) &&
               areColumnsValid(board: board) &&
               areSquaresValid(board: board)
    }
    
    // Checks if all rows are valid
    private func areRowsValid(board: [[Int]]) -> Bool{
        for row in board{
            // If an invalid row is found
            if !isSetValid(row){
                return false
            }
        }
        // All rows are valid
        return true
    }
    
    // Checks if all columns are valid
    private func areColumnsValid(board: [[Int]]) -> Bool{
        // Transposse the board to treat columns as rows for easy checking
        for colIndex in 0..<9{
            var column: [Int] = []
            for rowIndex in 0..<9{
                column.append(board[rowIndex][colIndex])
            }
            // If an invalid column is found
            if !isSetValid(column){
                return false
            }
        }
        // All columns are valid
        return true
    }
    
    // Checks if all 3 x 3 squares are valid
    private func areSquaresValid(board: [[Int]]) -> Bool{
        // Iterates through the starting point of each of the 9 squares
        for rowOffset in stride(from: 0, to: 9, by: 3){ // 0, 3, 6
            for colOffset in stride(from: 0, to: 9, by: 3){ // 0, 3, 6
                
                var square: [Int] = []
                for rowIndex in 0..<3{
                    for colIndex in 0..<3{
                        square.append(board[rowOffset + rowIndex][colOffset + colIndex])
                    }
                }
                
                if !isSetValid(square){
                    // If an invalid square is found
                    return false
                }
            }
        }
        // All squares are valid
        return true
    }
    
    // Checks if a given array of 9 numbers is valid
    // A set is valid if it contains numbers 1-9 with no duplicates
    // `Set` automatically handles duplicates
    private func isSetValid(_ set: [Int]) -> Bool{
        var seenNumbers = Set<Int>()
        for number in set{
            // If a number is outside the 1-9 range, it's invalid
            if number < 1 || number > 9{
                return false
            }
            // If the number has been seen before, it's a duplicate
            if seenNumbers.contains(number){
                return false
            }
            seenNumbers.insert(number)
        }
        // Got through the whole loop without issues, the set is valid
        return true
    }
}
