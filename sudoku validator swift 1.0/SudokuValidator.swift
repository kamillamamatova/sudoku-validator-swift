import Foundation

// Defines an enum for more descriptive validation results
enum SudokuValidationResult{
    case validAndComplete
    case validAndIncomplete
    case invalid
}

struct SudokuValidator{
    // Checks for duplicates
    func validate(board: [[Int]]) -> SudokuValidationResult{
        let hasNoDuplicates = areRowsValid(board: board) && areColumnsValid(board: board) && areSquaresValid(board: board)
        
        if !hasNoDuplicates{
            return .invalid
        }
        
        // Checks if there are any empty cells
        let isBoardComplete = !board.flatMap { $0 }.contains(0)
        
        if isBoardComplete{
            return .validAndComplete
        }
        else{
            return .validAndIncomplete
        }
    }
    
    // Checks if all the rows are valid
    private func areRowsValid(board: [[Int]]) -> Bool{
        for row in board{
            if !isSetValid(row){
                return false;
            }
        }
        return true;
    }
    
    // Checks if all the columns are valid
    private func areColumnsValid(board: [[Int]]) -> Bool{
        for colIndex in 0..<9{
            var column: [Int] = []
            for rowIndex in 0..<9{
                column.append(board[rowIndex][colIndex])
            }
            if !isSetValid(column){
                return false
            }
        }
        return true;
    }
    
    // Checks if all 3 x 3 squares are valid
    private func areSquaresValid(board: [[Int]]) -> Bool{
        for rowOffset in stride(from: 0, to: 9, by: 3){
            for colOffset in stride(from: 0, to: 9, by: 3){
                var square: [Int] = []
                for rowIndex in 0..<3{
                    for colIndex in 0..<3{
                        square.append(board[rowOffset + rowIndex][colOffset + colIndex])
                    }
                }
                if !isSetValid(square){
                    return false
                }
            }
        }
        return true;
    }
    
    // Checks if a given array of 9 numbers is valid
    private func isSetValid(_ set: [Int]) -> Bool {
        var seen: Set<Int> = []
        for number in set {
            // Skips empty cells
            if number == 0 {
                continue
            }
            // Checks for invalid numbers or duplicates
            if number < 1 || number > 9 || seen.contains(number) {
                return false
            }
            seen.insert(number)
        }
        return true
    }
}
