mod api;

use api::game::Game;
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
    let mut game = Game::new();
    let _ = game.play(GridPosition { grid: 1, pos_in_grid: 0 }, true);
    let _ = game.play(GridPosition { grid: 0, pos_in_grid: 4 }, false);
    let available = game.play(GridPosition { grid: 4, pos_in_grid: 0 }, false);
    print_available(available);
    println!("{}", game.state);
    println!("{}", game);
}
