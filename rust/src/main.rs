mod api;

use api::game::UTTTGame;
use api::game::GridPosition;

fn print_available(available: Vec<GridPosition>) {
    println!(
        "{}",
        available
            .iter()
            .map(|p| p.to_string())
            .collect::<Vec<String>>()
            .join(", ")
    );
}
 
fn main() {
    let mut game = UTTTGame::new();
    let _ = game.play(GridPosition { grid: 0, pos_in_grid: 6 }, true);
    let _ = game.play(GridPosition { grid: 0, pos_in_grid: 7 }, true);
    let _ = game.play(GridPosition { grid: 0, pos_in_grid: 8 }, true);
    println!("{}", game.state);
    println!("{}", game);
}
