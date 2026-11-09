/*
    Ravana Ember: Ravana OS's own minimize motion. The window shrinks into its dock
    icon on a smooth S-curve and fades out before it arrives (no genie warp);
    restoring plays it in reverse. Structure follows KWin's Squash effect
    (Vlad Zahorodnii, GPL-2.0-or-later).
*/
"use strict";

const ember = {
    duration: animationTime(300),

    path(w, icon) {
        const r = w.geometry;
        return {
            size: { value1: Math.max(1, icon.width), value2: Math.max(1, icon.height * r.height / Math.max(1, r.width)) },
            move: {
                value1: icon.x - r.x - (r.width - icon.width) / 2,
                value2: icon.y - r.y - (r.height - icon.height) / 2,
            },
            full: { value1: r.width, value2: r.height },
        };
    },

    minimized(w) {
        if (effects.hasActiveFullScreenEffect) return;
        const icon = w.iconGeometry;
        if (icon.width == 0 || icon.height == 0) return;
        if (w.restoreAnimation) {
            if (redirect(w.restoreAnimation, Effect.Backward)) return;
            cancel(w.restoreAnimation);
            delete w.restoreAnimation;
        }
        if (w.minimizeAnimation) {
            if (redirect(w.minimizeAnimation, Effect.Forward)) return;
            cancel(w.minimizeAnimation);
        }
        const p = ember.path(w, icon);
        w.setData(Effect.WindowForceBlurRole, true);
        w.minimizeAnimation = animate({
            window: w,
            curve: QEasingCurve.InOutQuint,
            duration: ember.duration,
            keepAlive: false,
            animations: [
                { type: Effect.Size, from: p.full, to: p.size },
                { type: Effect.Translation, from: { value1: 0, value2: 0 }, to: p.move },
                { type: Effect.Opacity, from: 1.0, to: 0.0, curve: QEasingCurve.InQuad },
            ],
        });
    },

    restored(w) {
        if (effects.hasActiveFullScreenEffect) return;
        const icon = w.iconGeometry;
        if (icon.width == 0 || icon.height == 0) return;
        if (w.minimizeAnimation) {
            if (redirect(w.minimizeAnimation, Effect.Backward)) return;
            cancel(w.minimizeAnimation);
            delete w.minimizeAnimation;
        }
        if (w.restoreAnimation) {
            if (redirect(w.restoreAnimation, Effect.Forward)) return;
            cancel(w.restoreAnimation);
        }
        const p = ember.path(w, icon);
        w.setData(Effect.WindowForceBlurRole, true);
        w.restoreAnimation = animate({
            window: w,
            curve: QEasingCurve.OutQuint,
            duration: ember.duration,
            keepAlive: false,
            animations: [
                { type: Effect.Size, from: p.size, to: p.full },
                { type: Effect.Translation, from: p.move, to: { value1: 0, value2: 0 } },
                { type: Effect.Opacity, from: 0.0, to: 1.0 },
            ],
        });
    },

    added(w) {
        w.minimizedChanged.connect(() => w.minimized ? ember.minimized(w) : ember.restored(w));
    },

    init() {
        effect.configChanged.connect(() => { ember.duration = animationTime(300); });
        effect.animationEnded.connect(w => w.setData(Effect.WindowForceBlurRole, null));
        effects.windowAdded.connect(ember.added);
        for (const w of effects.stackingOrder) ember.added(w);
    },
};

ember.init();
