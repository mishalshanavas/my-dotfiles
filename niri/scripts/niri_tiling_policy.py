"""Small, side-effect-free decision for grouping a third tiled window."""


def third_window_action(
    tiled_count: int, maximized_count: int, new_column_index: int | None, limit: int
) -> str | None:
    """Return the Niri action to group a new window, if grouping is appropriate."""
    if tiled_count != 3 or tiled_count > limit or maximized_count:
        return None
    if new_column_index == 2:
        return "ConsumeOrExpelWindowRight"
    return "ConsumeOrExpelWindowLeft"


def two_window_ids_to_fit(windows: list[dict], output_width: int) -> tuple[int, int] | None:
    """Find two separate columns that do not fill the output as equal halves."""
    if len(windows) != 2 or output_width <= 0:
        return None
    first, second = windows
    if first["col_idx"] is None or second["col_idx"] is None:
        return None
    if first["col_idx"] == second["col_idx"]:
        return None
    widths = [window["layout"]["tile_size"][0] for window in windows]
    # Niri's proportional width accounts for borders and gaps, so its reported
    # tile width can differ by a few pixels from half the raw output width.
    if all(abs(width - output_width / 2) <= 4 for width in widths):
        return None
    return first["id"], second["id"]
