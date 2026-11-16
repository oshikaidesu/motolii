// SMOKE: minimal shim to verify module loading
if (typeof globalThis.navigator === 'undefined') globalThis.navigator = { userAgent: '' };
if (typeof globalThis.window === 'undefined') globalThis.window = null;
if (typeof globalThis.document === 'undefined') globalThis.document = null;
import Expressions from 'motolii-lottie/utils/expressions/Expressions.js';
globalThis.__lottie_smoke = typeof Expressions;
