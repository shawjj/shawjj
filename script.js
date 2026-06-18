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
        const rect = sticker.getBoundingClientRect();
        const margin = Math.min(window.innerWidth * 0.28, 150);
        const minX = -rect.left - rect.width + margin;
        const maxX = window.innerWidth - rect.left - margin;
        const minY = -rect.top - rect.height + margin;
        const maxY = window.innerHeight - rect.top - margin;

        state.x = clamp(state.x, minX, maxX);
        state.y = clamp(state.y, minY, maxY);
        setPosition();
    };

    sticker.addEventListener("pointerdown", (event) => {
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
    window.addEventListener("resize", clampPosition);

    setPosition();
});
