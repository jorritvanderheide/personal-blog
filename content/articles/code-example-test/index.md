+++
title = 'Code Example Test'
summary = 'Testing code block highlighting and copy functionality with Nix and JavaScript examples'
date = 2026-01-12T14:00:00Z
lastmod = 2026-01-12T14:00:00Z
draft = false
cover = ''
categories = ['tech']
tags = ['article']

[author]
  name = 'Jorrit van der Heide'
+++

### Code Block Examples

This article demonstrates the code block highlighting and copy functionality with examples in different languages.

<!--more-->

### Nix Configuration Example

Here's a Nix flake configuration for a development environment:

```nix
{
  description = "Personal blog development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            hugo
            nodejs_20
            nodePackages.prettier
            python3
            python3Packages.pillow
          ];

          shellHook = ''
            echo "Personal blog development environment"
            echo "Hugo version: $(hugo version)"
            echo "Node version: $(node --version)"
          '';
        };
      }
    );
}
```

This configuration creates a reproducible development environment with Hugo, Node.js, and Python.

### JavaScript Example

Here's the improved copy-to-clipboard functionality:

```javascript
document.addEventListener("DOMContentLoaded", () => {
  const copyButtons = document.querySelectorAll(".copy-button")

  copyButtons.forEach(button => {
    button.addEventListener("click", async () => {
      const figure = button.closest("figure")
      if (!figure) return

      const liveRegion = figure.querySelector('[aria-live="polite"]')
      const code = figure.querySelector("code")
      if (!code) return

      const text = code.innerText

      if (!navigator.clipboard) {
        button.textContent = "unsupported"
        if (liveRegion) {
          liveRegion.textContent = "Clipboard API not supported"
        }
        setTimeout(() => {
          button.textContent = "copy"
          if (liveRegion) liveRegion.textContent = ""
        }, 2000)
        return
      }

      try {
        await navigator.clipboard.writeText(text)
        button.textContent = "copied!"
        button.setAttribute("aria-label", "Code copied to clipboard")

        if (liveRegion) {
          liveRegion.textContent = "Code copied to clipboard"
        }

        setTimeout(() => {
          button.textContent = "copy"
          button.setAttribute("aria-label", "Copy code to clipboard")
          if (liveRegion) liveRegion.textContent = ""
        }, 1500)
      } catch (err) {
        console.error("Copy failed:", err)
        button.textContent = "failed"

        if (liveRegion) {
          liveRegion.textContent = "Failed to copy. Try manually."
        }

        setTimeout(() => {
          button.textContent = "copy"
          if (liveRegion) liveRegion.textContent = ""
        }, 2000)
      }
    })
  })
})
```

The improved version includes better error handling, accessibility features with ARIA live regions, and proper async/await syntax.

### Shell Script Example

A simple build script:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Building site for production..."
hugo --gc --minify --environment production

echo "Build complete!"
echo "Output directory: public/"
```

### Testing the Copy Button

Try clicking the "copy" button in the top-right corner of each code block. The button will:

- Show "copied!" when successful
- Announce to screen readers via ARIA live region
- Show "failed" or "unsupported" if there's an issue
- Work on both desktop and mobile devices

The implementation includes proper accessibility features and graceful error handling.
