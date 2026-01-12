document.addEventListener("DOMContentLoaded", () => {
  const copyButtons = document.querySelectorAll(".copy-button")

  copyButtons.forEach(button => {
    button.addEventListener("click", async () => {
      // Find the code element within the figure
      const figure = button.closest("figure")
      if (!figure) return

      // Find the ARIA live region for announcements
      const liveRegion = figure.querySelector('[aria-live="polite"]')

      // Get code - with line numbers in table, we need the second td (code content)
      // Hugo generates: <table><tr><td>line numbers</td><td>code content</td></tr></table>
      const table = figure.querySelector("table")
      let text = ""

      if (table) {
        // Line numbers are in a table - get the second td which has the actual code
        const codeCells = table.querySelectorAll("td")
        if (codeCells.length >= 2) {
          // Second td contains the actual code
          const codeElement = codeCells[1].querySelector("code")
          text = codeElement ? codeElement.innerText : ""
        } else if (codeCells.length === 1) {
          // Fallback: single cell, just get the code
          const codeElement = codeCells[0].querySelector("code")
          text = codeElement ? codeElement.innerText : ""
        }
      } else {
        // No table structure, get code directly
        const code = figure.querySelector("code")
        text = code ? code.innerText : ""
      }

      if (!text) return

      // Check if clipboard API is available
      if (!navigator.clipboard) {
        button.textContent = "unsupported"
        if (liveRegion) {
          liveRegion.textContent = "Clipboard API not supported in this browser"
        }
        setTimeout(() => {
          button.textContent = "copy"
          if (liveRegion) liveRegion.textContent = ""
        }, 2000)
        return
      }

      try {
        await navigator.clipboard.writeText(text)

        // Update button text
        button.textContent = "copied!"
        button.setAttribute("aria-label", "Code copied to clipboard")

        // Announce to screen readers
        if (liveRegion) {
          liveRegion.textContent = "Code copied to clipboard"
        }

        // Reset after 1.5 seconds
        setTimeout(() => {
          button.textContent = "copy"
          button.setAttribute("aria-label", "Copy code to clipboard")
          if (liveRegion) {
            liveRegion.textContent = ""
          }
        }, 1500)
      } catch (err) {
        console.error("Copy failed:", err)

        // Show error state
        button.textContent = "failed"
        button.setAttribute("aria-label", "Failed to copy code")

        if (liveRegion) {
          liveRegion.textContent = "Failed to copy code. Please try selecting and copying manually."
        }

        // Reset after 2 seconds
        setTimeout(() => {
          button.textContent = "copy"
          button.setAttribute("aria-label", "Copy code to clipboard")
          if (liveRegion) {
            liveRegion.textContent = ""
          }
        }, 2000)
      }
    })
  })
})
