#!/usr/bin/env python3
# look_models.py: the two picture readers the shelves' maps tell likeness by (motolii_likeness, motolii_calls_map.h), written as
# ONNX files into ~/Library/Caches/Motolii/models, outside the repository:
#   clip_b32.onnx      OpenAI CLIP ViT-B/32's image encoder (the effects' frames)
#   fontclip_b32.onnx  FontCLIP's (the fonts' specimens: Tatsukawa et al., Eurographics 2024; its weights MIT, as its
#                      author says in its issue 13), which is that encoder with FontCLIP's fine-tuned visual weights in
# each loaded as FontMap loads FontCLIP (tfrere/fontmap, pipeline/fontclip_model.py, load_fontclip_openclip: open_clip's
# OpenAI ViT-B/32 and the checkpoint's visual.* tensors), its checkpoint fetched as FontCLIP's setup_data.py fetches it
# (gdown), each written by torch.onnx.export, then read back by ONNX Runtime and told against torch.
# Run once, in a Python of its own:  pip install torch open_clip_torch gdown onnx onnxruntime;  python3 engine/deps/look_models.py
import pathlib

import gdown
import numpy as np
import onnxruntime
import open_clip
import torch

out = pathlib.Path.home() / "Library/Caches/Motolii/models"
sources = out / "sources"
sources.mkdir(parents=True, exist_ok=True)

openai = sources / "ViT-B-32.pt"
if not openai.exists():
    open_clip.pretrained.download_pretrained_from_url(open_clip.get_pretrained_url("ViT-B-32", "openai"), cache_dir=str(sources))
    next(sources.glob("ViT-B-32*.pt")).rename(openai)
fontclip = sources / "fontclip_model.pt"
if not fontclip.exists():
    gdown.download("https://drive.google.com/uc?id=1Tym7rAIuaGr6Gv-gZRSJmPstQjOWPgl1", str(fontclip), quiet=False)


def clip():
    return open_clip.openai.load_openai_model(str(openai), device="cpu").float().eval()


def font_clip():
    model = clip()
    state = torch.load(fontclip, map_location="cpu", weights_only=False)["model_state_dict"]
    model.visual.load_state_dict({k[len("visual."):]: v.float() for k, v in state.items() if k.startswith("visual.")}, strict=True)
    return model.eval()


probe = torch.rand(2, 3, 224, 224)
for name, model in (("clip_b32.onnx", clip()), ("fontclip_b32.onnx", font_clip())):
    # (out of no_grad: there torch's MultiheadAttention takes its fast path, _native_multi_head_attention, which ONNX lacks)
    torch.onnx.export(model.visual, probe[:1], str(out / name), input_names=["image"], output_names=["seen"],
                      dynamic_axes={"image": {0: "n"}, "seen": {0: "n"}}, opset_version=17, dynamo=False)
    with torch.no_grad():
        want = model.visual(probe).numpy()
    got = onnxruntime.InferenceSession(str(out / name)).run(None, {"image": probe.numpy()})[0]
    print(name, got.shape, "most apart from torch:", float(np.abs(got - want).max()))
