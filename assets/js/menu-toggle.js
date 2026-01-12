import gsap from "gsap"

document.addEventListener("DOMContentLoaded", () => {
  const toggleBtn = document.getElementById("menuToggle")
  const mobileMenu = document.getElementById("mobileMenu")
  const menuText = document.getElementById("menuText")

  // Create a paused timeline for menu animation
  const menuTimeline = gsap.timeline({ paused: true })

  // Animate opacity and slide down/up
  menuTimeline.to(mobileMenu, {
    duration: 0.3,
    autoAlpha: 1,
    y: 0,
    ease: "power2.out",
    display: "flex",
  })

  // Initially hidden and shifted up
  gsap.set(mobileMenu, { autoAlpha: 0, y: -32, display: "none" })

  let isOpen = false

  const toggleMenu = () => {
    isOpen = !isOpen

    // Update ARIA attributes
    toggleBtn.setAttribute("aria-expanded", isOpen)
    mobileMenu.setAttribute("aria-hidden", !isOpen)

    if (isOpen) {
      menuTimeline.play()
      menuText.textContent = "close"
    } else {
      menuTimeline.reverse()
      menuText.textContent = "menu"
    }
  }

  // Click event
  toggleBtn.addEventListener("click", toggleMenu)

  // Keyboard support (Enter and Space)
  toggleBtn.addEventListener("keydown", (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      toggleMenu()
    }
  })
})
