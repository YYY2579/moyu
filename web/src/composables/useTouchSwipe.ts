import { ref, onMounted, onUnmounted, Ref } from 'vue'

interface SwipeOptions {
  threshold?: number
  preventDefault?: boolean
  passive?: boolean
}

interface SwipeDirection {
  left: boolean
  right: boolean
  up: boolean
  down: boolean
}

export function useTouchSwipe(
  element: Ref<HTMLElement | null>,
  options: SwipeOptions = {}
) {
  const {
    threshold = 50,
    preventDefault = true,
    passive = true
  } = options

  const startX = ref(0)
  const startY = ref(0)
  const endX = ref(0)
  const endY = ref(0)

  const swipeDirection = ref<SwipeDirection>({
    left: false,
    right: false,
    up: false,
    down: false
  })

  const isSwiping = ref(false)

  const handleTouchStart = (e: TouchEvent) => {
    if (!element.value) return

    const touch = e.touches[0]
    startX.value = touch.clientX
    startY.value = touch.clientY
    isSwiping.value = true

    // 重置方向
    swipeDirection.value = {
      left: false,
      right: false,
      up: false,
      down: false
    }
  }

  const handleTouchMove = (e: TouchEvent) => {
    if (!isSwiping.value || !element.value) return

    if (preventDefault) {
      e.preventDefault()
    }

    const touch = e.touches[0]
    endX.value = touch.clientX
    endY.value = touch.clientY
  }

  const handleTouchEnd = (e: TouchEvent) => {
    if (!isSwiping.value || !element.value) return

    const deltaX = endX.value - startX.value
    const deltaY = endY.value - startY.value
    const absDeltaX = Math.abs(deltaX)
    const absDeltaY = Math.abs(deltaY)

    // 判断是否达到滑动阈值
    if (Math.max(absDeltaX, absDeltaY) > threshold) {
      if (absDeltaX > absDeltaY) {
        // 水平滑动
        swipeDirection.value.left = deltaX < 0
        swipeDirection.value.right = deltaX > 0
      } else {
        // 垂直滑动
        swipeDirection.value.up = deltaY < 0
        swipeDirection.value.down = deltaY > 0
      }
    }

    isSwiping.value = false
  }

  const handleTouchCancel = () => {
    isSwiping.value = false
  }

  onMounted(() => {
    if (!element.value) return

    const eventOptions: AddEventListenerOptions = {
      passive: passive && !preventDefault,
      capture: true
    }

    element.value.addEventListener('touchstart', handleTouchStart, eventOptions)
    element.value.addEventListener('touchmove', handleTouchMove, eventOptions)
    element.value.addEventListener('touchend', handleTouchEnd, eventOptions)
    element.value.addEventListener('touchcancel', handleTouchCancel, eventOptions)
  })

  onUnmounted(() => {
    if (!element.value) return

    element.value.removeEventListener('touchstart', handleTouchStart)
    element.value.removeEventListener('touchmove', handleTouchMove)
    element.value.removeEventListener('touchend', handleTouchEnd)
    element.value.removeEventListener('touchcancel', handleTouchCancel)
  })

  return {
    swipeDirection,
    isSwiping,
    startX,
    startY,
    endX,
    endY
  }
}

export function useTouchLongPress(
  element: Ref<HTMLElement | null>,
  callback: () => void,
  options: { delay?: number } = {}
) {
  const { delay = 500 } = options
  const timeoutId = ref<NodeJS.Timeout | null>(null)
  const isPressed = ref(false)

  const handleTouchStart = (e: TouchEvent) => {
    isPressed.value = true
    timeoutId.value = setTimeout(() => {
      if (isPressed.value) {
        callback()
      }
    }, delay)
  }

  const handleTouchEnd = () => {
    isPressed.value = false
    if (timeoutId.value) {
      clearTimeout(timeoutId.value)
      timeoutId.value = null
    }
  }

  const handleTouchCancel = () => {
    isPressed.value = false
    if (timeoutId.value) {
      clearTimeout(timeoutId.value)
      timeoutId.value = null
    }
  }

  onMounted(() => {
    if (!element.value) return

    element.value.addEventListener('touchstart', handleTouchStart)
    element.value.addEventListener('touchend', handleTouchEnd)
    element.value.addEventListener('touchcancel', handleTouchCancel)
  })

  onUnmounted(() => {
    if (!element.value) return

    element.value.removeEventListener('touchstart', handleTouchStart)
    element.value.removeEventListener('touchend', handleTouchEnd)
    element.value.removeEventListener('touchcancel', handleTouchCancel)
    
    if (timeoutId.value) {
      clearTimeout(timeoutId.value)
    }
  })

  return {
    isPressed
  }
}