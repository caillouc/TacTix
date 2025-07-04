use std::fmt::{self};

pub struct UTTTGame {
    // 1 bit per position on the board, thus only the first 81 bit are relevant
    // The first 9 bits correspond to the top left grid, the 9 next one to the middle top one and so on

    // A bit is set to one if the corresponding position is occupied by a cross
    crosses: u128,
    // A bit is set to one if the corresponding position is occupied by a noughts
    noughts: u128,
    // The first 9 bit correspond to grid won by crosses, the 9 next one to grid won by noughts
    // Top left position correspond to bit with index 0
    // Example the board
    // a b c
    // d e f
    // g h i
    // will give 'ihgfedcba' in binary
    big_game: u32,
    pub state: GameState,
}

#[derive(Debug)]
pub enum GameState {
    CrosssesWin,
    NoughtsWin,
    Tie,
    CrossesTurn,
    NoughtsTurn,
}

#[derive(Debug)]
pub struct GridPosition {
    // The origin is top left
    pub grid: u16,
    pub pos_in_grid: u16,
}

impl UTTTGame {
    pub fn new() -> Self {
        Self {
            crosses: 0,
            noughts: 0,
            big_game: 0,
            state: GameState::CrossesTurn,
        }
    }

    fn check_win(&mut self) {
        // Take only the first 9 bits
        if self.check_single_win(self.big_game & 511) {
            self.state = GameState::CrosssesWin;
        // Take only the 9 bits for noughts
        } else if self.check_single_win(self.big_game << 9) {
            self.state = GameState::NoughtsWin;
        }
    }

    fn check_single_win(&self, pos: u32) -> bool {
        // Not using a for loop over a list, for better performance
        // Likely not that useful

        // 111
        // 000
        // 000
        // => 000 000 111 = 7
        let mut res = (pos & 7) == 7;
        // 000 111 000 = 56
        res &= (pos & 56) == 56;
        // 111 000 000 = 448
        res &= (pos & 448) == 448;
        // 100
        // 100
        // 100
        // => 001 001 001 = 73
        res &= (pos & 73) == 73;
        // 010 010 010 = 146
        res &= (pos & 146) == 146;
        // 100 100 100 = 291
        res &= (pos & 292) == 292;
        // 100
        // 010
        // 001
        // => 100 010 001 = 273
        res &= (pos & 273) == 273;
        // 001 010 100 = 84
        res & (pos & 84 == 84)
    }

    pub fn play(&mut self, cell: GridPosition, cross_playing: bool) -> Vec<GridPosition> {
        let cell_pos_global = cell.grid * 9 + cell.pos_in_grid;
        println!("Cell position global : {cell_pos_global}");
        if cross_playing {
            self.crosses |= 1 << cell_pos_global;
            println!("crosses has been updated : {}", self.crosses)
        } else {
            self.noughts |= 1 << cell_pos_global;
            println!("noughts has been updated : {}", self.noughts)
        }
        // if next grid is available (next grid pos = current cell pos in grid)
        let mut next_moves = vec![];
        let mut start_check_index = 0;
        let mut end_check_index = 81;
        if self.big_game & 1 << cell.pos_in_grid == 0
            && (self.crosses | self.noughts) & (511 << cell.pos_in_grid) != 511
        {
            // The corresponding grid is not won and has empty cell
            // This should be the most common scenario
            start_check_index = cell.pos_in_grid * 9;
            end_check_index = start_check_index + 9;
        }
        println!("Start Check Index : {start_check_index}");
        println!("End Check Index : {end_check_index}");
        let available_cell = self.crosses | self.noughts;
        for i in start_check_index..end_check_index {
            if self.big_game & (1 << (i / 9)) == 0 && available_cell & (1 << i) == 0 {
                // Cell is available and grid is not yet won
                next_moves.push(GridPosition { grid: i / 9, pos_in_grid: i % 9 });
            }
        }
        if next_moves.len() == 0 {
            self.state = GameState::Tie;
        } else if cross_playing {
            self.state = GameState::NoughtsTurn;
        } else {
            self.state = GameState::CrossesTurn;
        }
        self.check_win();
        next_moves
    }
}

impl fmt::Display for UTTTGame {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(f, "Game State: {}\n", self.state)?;

        for row in 0..9 {
            for col in 0..9 {
                let grid_number = (row / 3) * 3 + col / 3;
                let cell_pos_in_grid = (row % 3) * 3 + col % 3;
                let bit_index = grid_number * 9 + cell_pos_in_grid;
                let ch = if (self.crosses >> bit_index) & 1 == 1 {
                    'X'
                } else if (self.noughts >> bit_index) & 1 == 1 {
                    'O'
                } else {
                    '.'
                };
                write!(f, "{}", ch)?;

                // Add space between 3x3 subgrids
                if col % 3 == 2 && col != 8 {
                    write!(f, " | ")?;
                } else if col != 8 {
                    write!(f, " ")?;
                }
            }

            writeln!(f)?;

            // Add separator line between 3x3 subgrid rows
            if row % 3 == 2 && row != 8 {
                writeln!(f, "------+-------+------")?;
            }
        }

        Ok(())
    }
}

impl fmt::Display for GameState {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::CrossesTurn => write!(f, "Crosses Turn (X)"),
            Self::NoughtsTurn => write!(f, "Noughts Turn (O)"),
            Self::Tie => write!(f, "Tie (XO)"),
            Self::CrosssesWin => write!(f, "Crosse Win (XXX)"),
            Self::NoughtsWin => write!(f, "Noughts Win (OOO)"),
        }
    }
}

impl fmt::Display for GridPosition {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "(Grid: {}, Pos: {})", self.grid, self.pos_in_grid)
    }
}
