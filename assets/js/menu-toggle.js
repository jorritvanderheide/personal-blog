document.addEventListener("DOMContentLoaded", () => {
  const toggleBtn = document.getElementById("menuToggle")
  const mobileMenu = document.getElementById("mobileMenu")
  const menuText = document.getElementById("menuText")

  let isOpen = false

  const toggleMenu = () => {
    isOpen = !isOpen

    toggleBtn.setAttribute("aria-expanded", isOpen)
    mobileMenu.setAttribute("aria-hidden", !isOpen)

    if (isOpen) {
      mobileMenu.classList.add("menu-open")
      menuText.textContent = "close"
    } else {
      mobileMenu.classList.remove("menu-open")
      menuText.textContent = "menu"
    }
  }

  toggleBtn.addEventListener("click", toggleMenu)

  toggleBtn.addEventListener("keydown", (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      toggleMenu()
    }
  })
})
