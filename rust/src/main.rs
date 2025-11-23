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
    let available_move = game.play(GridPosition { grid: 0, pos_in_grid: 6 }, true);
    let _ = game.ai_play(available_move, false);
    println!("{}", game.state);
    println!("{}", game);
}
