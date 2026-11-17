# Effect licences — the receipt, not the price tag

Motolii bundles effects, scripts and expressions from many authors and many worlds (ISF, AviUtl2, Cavalry, p5.js, After Effects, Shadertoy, …). Users will mix them freely. For that to keep working, everyone — the author who shares an effect, the user who mixes six of them, and the community that grows around both — needs to trust that credit lands where it should, without turning licence labels into fences.

## The problem with price tags

If a licence badge sits on every effect card, it becomes something people optimise for. Prominent `MIT` / `CC0` / `proprietary` labels turn the shelf into a marketplace before there is one, and rational authors pick the most restrictive option to protect themselves — which makes the shelf less open with every new effect. Motolii's whole point is a crossroads of expressions that were apart; licensing arms races close the crossroads.

## A receipt instead

A receipt does not influence what you buy; it records what you bought — after the fact, at the exit. In Motolii the exits are:

| Exit | What happens |
|---|---|
| **Export** | A `_credits.txt` appears beside the exported video, listing every effect the project used. Already working. |
| **Share / template** | When a `.motolii` project is shared, the receipt travels with it, so the recipient knows what is inside. |
| **Publish to shelf** | When a user puts their own effect on a shelf, the `meta.yaml` records `origin: self`. |

During editing, the effect card shows only **by author** — the person, not the terms. The licence is on the receipt, not on the shelf.

The one exception: a warning may surface during editing when a project mixes effects whose licences conflict (e.g. a copyleft effect composed with a proprietary one). That is a guardrail, not a label.

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

## For the future

When a content protocol (ACP or otherwise) brings effects in from outside, `origin` extends naturally: `store`, `import`, whatever the channel is. The receipt format does not change; a new origin section appears.

The goal stays the same: **credit is clear, but it does not become a fence.** The community should be able to mix freely without having to think about licence compatibility until the moment they export — and at that moment, the receipt is already there, complete and correct, without anyone having had to assemble it by hand.

## Where the code lives

| File | Role |
|---|---|
| `app/lib/storage/shelf_meta.dart` | `ShelfMeta`: parses `meta.yaml`, derives `resolvedOrigin` |
| `app/lib/workspace/state/effect_credits.dart` | `EffectCredit`, `projectCredits()`, `creditsText()`, `writeCreditsFile()` |
| `app/lib/inspector/card_meta_row.dart` | `CardMetaRow`: the metadata line under an effect card (author only) |
| `shelves/*/meta.yaml` | The source metadata: `author`, `license`, `source`, and optionally `origin` |
