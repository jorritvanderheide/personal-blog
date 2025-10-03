document.addEventListener("DOMContentLoaded", () => {
  const copyButtons = document.querySelectorAll(".copy-button")

  copyButtons.forEach(button => {
    button.addEventListener("click", () => {
      const code = button.nextElementSibling.querySelector("code")
      if (!code) return

      const text = code.innerText

      navigator.clipboard
        .writeText(text)
        .then(() => {
          button.textContent = "copied!"
          setTimeout(() => (button.textContent = "copy"), 1500)
        })
        .catch(() => {
          alert("Copy failed. Try manually.")
        })
    })
  })
})
