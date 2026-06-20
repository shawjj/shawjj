const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

document.querySelectorAll("[data-draggable]").forEach((sticker) => {
    const restingRotation = Number(sticker.dataset.rotation || 0);
    const draggingRotation = Number(sticker.dataset.dragRotation || restingRotation);
    const state = {
        activePointer: null,
        startX: 0,
        startY: 0,
        x: 0,
        y: 0,
        rotation: restingRotation,
    };

    const setPosition = () => {
        sticker.style.transform = `translate3d(${state.x}px, ${state.y}px, 0) rotate(${state.rotation}deg)`;
    };

    const clampPosition = () => {
        setPosition();
        const rect = sticker.getBoundingClientRect();
        const edgeReveal = clamp(Math.min(rect.width, rect.height) * 0.35, 24, 72);
        const minX = state.x + edgeReveal - rect.right;
        const maxX = state.x + window.innerWidth - edgeReveal - rect.left;
        const minY = state.y + edgeReveal - rect.bottom;
        const maxY = state.y + window.innerHeight - edgeReveal - rect.top;

        state.x = clamp(state.x, minX, maxX);
        state.y = clamp(state.y, minY, maxY);
        setPosition();
    };

    sticker.addEventListener("pointerdown", (event) => {
        event.preventDefault();
        state.activePointer = event.pointerId;
        state.startX = event.clientX - state.x;
        state.startY = event.clientY - state.y;
        state.rotation = draggingRotation;
        sticker.classList.add("is-dragging");
        sticker.setPointerCapture(event.pointerId);
        setPosition();
    });

    sticker.addEventListener("pointermove", (event) => {
        if (event.pointerId !== state.activePointer) {
            return;
        }

        state.x = event.clientX - state.startX;
        state.y = event.clientY - state.startY;
        clampPosition();
    });

    const endDrag = (event) => {
        if (event.pointerId !== state.activePointer) {
            return;
        }

        state.activePointer = null;
        state.rotation = restingRotation;
        sticker.classList.remove("is-dragging");
        setPosition();
    };

    sticker.addEventListener("pointerup", endDrag);
    sticker.addEventListener("pointercancel", endDrag);
    sticker.addEventListener("dragstart", (event) => event.preventDefault());
    window.addEventListener("resize", clampPosition);

    setPosition();
});

const aboutToggle = document.querySelector(".about-toggle");
const aboutPanel = document.querySelector("#about-panel");
const aboutBackdrop = document.querySelector(".about-backdrop");
const desk = document.querySelector(".desk");

if (aboutToggle && aboutPanel && aboutBackdrop && desk) {
    const setAboutOpen = (isOpen) => {
        aboutToggle.setAttribute("aria-expanded", String(isOpen));
        aboutPanel.hidden = !isOpen;
        aboutBackdrop.hidden = !isOpen;
        desk.classList.toggle("about-open", isOpen);
    };

    aboutToggle.addEventListener("click", () => {
        const isExpanded = aboutToggle.getAttribute("aria-expanded") === "true";
        setAboutOpen(!isExpanded);
    });

    aboutBackdrop.addEventListener("click", () => setAboutOpen(false));

    window.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
            setAboutOpen(false);
        }
    });
}
