# Parsik app icon

Created with the built-in Imagegen tool. The custom wrench, folded ribbon and
spirit level represent the app's everyday tools. No stock Material glyph is used.

- `icon.png`: opaque 1024 × 1024 artwork for the app and store.
- `icon_foreground.png`: transparent 1024 × 1024 adaptive foreground.
- Android background: `#2020B0`; foreground inset: 20%.
- Regenerate Android density assets with `dart run flutter_launcher_icons`.
- `tool/prepare_icon_assets.dart` resizes generated artwork, preserves foreground
  alpha, and makes the store icon opaque.

## Generation prompt

Use case: logo-brand. Create a finished premium Android app icon for Parsik Toolbox, a Persian everyday utilities app with measurement, QR scanning, compass, flashlight and text tools. One square 1024x1024 image, full-bleed rich indigo to violet subtly luminous background, no rounded outer corners (Android supplies mask). Center an original sculptural geometric multitool emblem: a bold ivory precision wrench jaw flowing into a folded interlocking P-like angular ribbon, with a small vivid turquoise inset that suggests a spirit-level bubble. Cohesive single recognisable silhouette, custom industrial design, polished softly dimensional ceramic/enamel edges, sophisticated restrained depth, not a generic Material icon, not a briefcase/handbag, not a collage of tools. Strong legibility at 48px. Emblem entirely within central 62% of canvas with generous consistent empty background around all sides for adaptive cropping. Symmetrical visual balance, crisp clean geometry. No lettering, no words, no numbers, no watermarks, no mockup, no border. Deliver actual finished icon only.

## Foreground extraction prompt

Remove only the background from the generated icon. Preserve the ivory wrench,
turquoise spirit level, folded ribbon and their material edges. Deliver actual
transparent alpha, including the hole inside the emblem. No new objects or text.

The generated foreground was recentered by Imagegen; the launcher inset keeps
the complete emblem inside the adaptive mask.
