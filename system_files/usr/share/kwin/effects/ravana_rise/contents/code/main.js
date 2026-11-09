/*
    Ravana Rise: Ravana OS's own open/close motion.
    Open: the window rises ~3% of its height into place while scaling up from 95%
    and fading in, on a fast, confident ease-out. Close: it sinks and fades.
    Structure follows KWin's Scale effect (Vlad Zahorodnii, GPL-2.0-or-later).
*/
"use strict";

const blacklist = {
    "ksmserver ksmserver": [],
    "ksmserver-logout-greeter ksmserver-logout-greeter": [],
    "ksplashqml ksplashqml": [],
    "spectacle org.kde.spectacle": ["region-editor"],
};

class RavanaRise {
    constructor() {
        effect.configChanged.connect(this.loadConfig.bind(this));
        effect.animationEnded.connect(this.cleanup.bind(this));
        effects.windowAdded.connect(this.opened.bind(this));
        effects.windowClosed.connect(this.closed.bind(this));
        this.loadConfig();
    }

    loadConfig() {
        this.openTime = animationTime(260);
        this.closeTime = animationTime(170);
    }

    static wanted(w) {
        if (w.windowClass == "plasmashell plasmashell" || w.windowClass == "plasmashell org.kde.plasmashell") {
            return w.hasDecoration;
        }
        const tags = blacklist[w.windowClass];
        if (tags && (tags.length === 0 || tags.includes(w.tag))) return false;
        if (w.hasDecoration) return true;
        if (w.popupWindow || w.lockScreen || w.outline || !w.managed) return false;
        return w.normalWindow || w.dialog;
    }

    cleanup(w) {
        w.setData(Effect.WindowForceBackgroundContrastRole, null);
        w.setData(Effect.WindowForceBlurRole, null);
    }

    opened(w) {
        if (effects.hasActiveFullScreenEffect || !RavanaRise.wanted(w) || !w.visible) return;
        if (effect.isGrabbed(w, Effect.WindowAddedGrabRole)) return;
        w.setData(Effect.WindowForceBlurRole, true);
        const rise = Math.min(36, Math.round(w.height * 0.03));
        w.riseAnimation = animate({
            window: w,
            curve: QEasingCurve.OutQuint,
            duration: this.openTime,
            animations: [
                { type: Effect.Scale, from: 0.95 },
                { type: Effect.Translation, from: { value1: 0, value2: rise }, to: { value1: 0, value2: 0 } },
                { type: Effect.Opacity, from: 0 },
            ],
        });
    }

    closed(w) {
        if (effects.hasActiveFullScreenEffect || !RavanaRise.wanted(w)) return;
        if (!w.visible || w.skipsCloseAnimation) return;
        if (effect.isGrabbed(w, Effect.WindowClosedGrabRole)) return;
        if (w.riseAnimation) {
            cancel(w.riseAnimation);
            delete w.riseAnimation;
        }
        w.setData(Effect.WindowForceBlurRole, true);
        animate({
            window: w,
            curve: QEasingCurve.InCubic,
            duration: this.closeTime,
            animations: [
                { type: Effect.Scale, to: 0.96 },
                { type: Effect.Translation, from: { value1: 0, value2: 0 }, to: { value1: 0, value2: Math.min(20, Math.round(w.height * 0.02)) } },
                { type: Effect.Opacity, to: 0 },
            ],
        });
    }
}

new RavanaRise();
