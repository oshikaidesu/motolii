# Effect licences and attribution

Motolii bundles effects, scripts and expressions from many authors and many worlds (ISF, AviUtl2, Cavalry, p5.js, After Effects, Shadertoy, …). Users mix them freely. For that to keep working, everyone — the author who shares an effect, the user who mixes six of them, and the community that grows around both — needs to trust that credit lands where it should.

## Design: credit at the exit, not at the shelf

Licence information is surfaced when the user exports or shares their work, not while they browse or compose effects. This keeps attribution reliable and complete without making licence choice a competitive signal between authors.

During editing, the effect card shows **by author** — the person, not the terms. Full attribution (author, licence, source) appears at the exits:

| Exit | What happens |
|---|---|
| **Export** | A `_credits.txt` appears beside the exported video, listing every effect the project used. Already working. |
| **Share / template** | When a `.motolii` project is shared, the attribution travels with it, so the recipient knows what is inside. |
| **Publish to shelf** | When a user puts their own effect on a shelf, the `meta.yaml` records `origin: self`. |

Motolii does not warn about licence compatibility during editing. The tool records where things come from; the user decides what to do with that information.

## Origin

Every effect has an origin. It is either written in `meta.yaml` or derived automatically:

| `origin` | Meaning | Derived when |
|---|---|---|
| `builtin` | Ships with Motolii, made by motolii | `author` is `motolii` |
| `community` | Made by someone else, bundled or added | Any other author, or no metadata |
| `self` | Made by the user | Set explicitly in `meta.yaml` |

The receipt groups by origin first, then by licence within the community section:

```
Effects used in this project
========================================

[Your Effects]
  My Custom Blur

[motolii]
  bounce_in
  fade_in

[Community]
  [MIT]
    Blur (Sashimono)  by Sashimono Edit  (https://github.com/...)
    Diagonal Blur  by VIDVOX  (https://editor.isf.video)
  [CC0-1.0]
    Chromatic Aberration  by こんにゃくねこ  (https://github.com/...)
```

Builtin and self effects list only names. Community effects list author, licence and source — the full attribution the author deserves.

## What Motolii ships vs. what the user brings in

| | Bundled (`shelves/`) | Pasted by the user (⌘V) |
|---|---|---|
| **Who distributes it** | Motolii | The user |
| **Licence requirement** | Commercial-use-compatible only (MIT, CC0, Unlicense, …) | The user's responsibility |
| **Attribution** | `meta.yaml` beside the file, always present | Motolii records the source format (Shadertoy, p5.js, …) in the project |
| **On the receipt** | Full: author, licence, source | Source format and what the user pasted |

Everything on the shelf is commercially safe. Code the user pastes is theirs to judge — Motolii records where it came from so the receipt can show it, but does not block or warn.

This is the same boundary as Hydra (AGPL-3.0): not bundled, fetched by the user with `extensions/hydra/get.sh`, deleted and Motolii is as it was. Works whose author publishes no licence text follow the same rule (already in [CONTRIBUTING](../../.github/CONTRIBUTING.md): not bundled; fetched at build time instead).

## For the future

When a content protocol (ACP or otherwise) brings effects in from outside, `origin` extends naturally: `store`, `import`, whatever the channel is. The attribution format does not change; a new origin section appears.

The goal stays the same: **credit is clear, but it does not become a fence.** The community can mix freely. Motolii records where things come from; the user decides what to do with that information.

## Where the code lives

| File | Role |
|---|---|
| `app/lib/storage/shelf_meta.dart` | `ShelfMeta`: parses `meta.yaml`, derives `resolvedOrigin` |
| `app/lib/workspace/state/effect_credits.dart` | `EffectCredit`, `projectCredits()`, `creditsText()`, `writeCreditsFile()` |
| `app/lib/inspector/card_meta_row.dart` | `CardMetaRow`: the metadata line under an effect card (author only) |
| `shelves/*/meta.yaml` | The source metadata: `author`, `license`, `source`, and optionally `origin` |
