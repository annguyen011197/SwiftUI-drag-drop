# Notes

## GridSizePreferenceKey

`GridSizePreferenceKey` is used to read `geo.size` from a `GeometryReader` background via the PreferenceKey mechanism. This was needed because `.frame(in: .named("grid"))` returns `.zero` on iOS 14 — named coordinate spaces aren't reliably propagated in this view hierarchy.

**Known issue:** `GridSizePreferenceKey` does not work as expected. The same PreferenceKey struct is shared for both the title height and the grid size reads. Because `PreferenceKey.reduce` uses `value = nextValue()`, the second child's value overwrites the first. This means `titleHeight` may not get updated correctly — it depends on evaluation order. A proper fix would use two separate PreferenceKey types (one for title, one for grid).
