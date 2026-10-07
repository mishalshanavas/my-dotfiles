import unittest

from niri_tiling_policy import third_window_action, two_window_ids_to_fit


class ThirdWindowPolicyTests(unittest.TestCase):
    def test_groups_new_third_window_on_the_appropriate_side(self):
        self.assertEqual(third_window_action(3, 0, 2, 3), "ConsumeOrExpelWindowRight")
        self.assertEqual(third_window_action(3, 0, 1, 3), "ConsumeOrExpelWindowLeft")

    def test_leaves_other_counts_and_maximized_layouts_alone(self):
        for args in ((1, 0, 1, 3), (2, 0, 1, 3), (4, 0, 3, 3), (3, 1, 2, 3), (3, 0, 2, 2)):
            with self.subTest(args=args):
                self.assertIsNone(third_window_action(*args))

    def test_fits_only_two_separate_columns_that_do_not_fill_the_screen(self):
        def window(window_id, column, width):
            return {"id": window_id, "col_idx": column, "layout": {"tile_size": [width, 744]}}

        self.assertEqual(
            two_window_ids_to_fit([window(1, 1, 1366), window(2, 2, 683)], 1366),
            (1, 2),
        )
        self.assertEqual(
            two_window_ids_to_fit([window(1, 1, 504), window(2, 2, 454)], 1366),
            (1, 2),
        )
        self.assertIsNone(two_window_ids_to_fit([window(1, 1, 683), window(2, 2, 683)], 1366))
        self.assertIsNone(two_window_ids_to_fit([window(1, 1, 1366), window(2, 1, 1366)], 1366))


if __name__ == "__main__":
    unittest.main()
