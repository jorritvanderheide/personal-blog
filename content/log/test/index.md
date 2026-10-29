+++
title = "Test"
summary = "A test post that uses every Obsidian element, to check how each one renders on the blog."
date = 2026-10-29T14:23:22Z
generator = "micropub"
references = ["hoepmanAuthenticityEffectiveAntidote2025"]
draft = true
+++

This post exists to check how every Obsidian element renders on the blog. Each section covers one group of elements.

## Text formatting

Plain text, **bold**, *italic*, ***bold and italic***, ~~strikethrough~~, highlight, and `inline code`. Escaped characters stay literal: \*not italic\*, ==not highlighted==.

A line with a hard break at the end  
continues on the next line. A footnote can also be written inline.[^1]

------------------------------------------------------------------------

### Heading level 3

#### Heading level 4

## Lists

- Bullet one
- Bullet two
  - Nested bullet
    - Deeper nested bullet
- Bullet three

1.  First
2.  Second
    1.  Nested numbered
    2.  Another nested
3.  Third

- [ ] Open task
- [x] Finished task
- [ ] Task with a nested list
  - [x] Nested finished task
  - [ ] Nested open task

## Links

- Internal link: Authenticity
- Internal link with alias: a signature
- Link to a heading: Signature
- Link to a heading in this note: Callouts
- Link to a note that does not exist yet: Note that does not exist
- External link: [Obsidian](https://obsidian.md)
- Bare URL: <https://bw20.nl>
- Citation link: ([Hoepman 2025, 2](#ref-hoepmanAuthenticityEffectiveAntidote2025))

A paragraph with a block id, so it can be linked to.

Link to that block: Test

## Images

![alt text](ce96697e2a4a.jpg)

*Caption*

The same image at a fixed width:

![alt text](ce96697e2a4a.jpg)

An image with a width and height: ![alt text](cae02a9442e1.png)

## Quotes

> he proposes to use authenticity as a proxy for veracity based on the belief that the ubiquitous use of (cryptographic) techniques to establish the authenticity of a message (e.g., via a signature) would help people make their own credibility judgments ([Hoepman 2025, 2](#ref-hoepmanAuthenticityEffectiveAntidote2025))

That was a quote[^2]

> A quote with several paragraphs.
>
> > A nested quote inside it.
>
> Back in the outer quote.

## Callouts

> A plain note callout.

> **A note with a custom title**  
> The body of the callout, with **formatting** and a link.

> Info callout.

> Tip callout.

> Success callout.

> Question callout.

> Warning callout.

> Failure callout.

> Danger callout.

> Bug callout.

> Example callout.

> Quote callout.

> Abstract callout.

> Todo callout.

> **Foldable, closed by default**  
> This is hidden until the reader opens it.

> **Foldable, open by default**  
> This is visible, and the reader can close it.

> **Nested callouts**  
> The outer callout.
>
> > **The inner callout**  
> > Inside the outer one.

## Tables

| Element   | Syntax     | Renders as |
|-----------|------------|------------|
| Highlight | `==text==` | text       |
| Wikilink  | `[[Note]]` | Signature  |

| Left | Centre | Right |
|:-----|:------:|------:|
| a    |   b    |     c |
| 1    |   2    |     3 |

## Math

Inline math: $`e^{i\pi} + 1 = 0`$.

Block math:

``` math
\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}
```

``` math
\begin{aligned}
a &= b + c \\
d &= e + f
\end{aligned}
```

## Diagrams

``` mermaid
graph LR
    Issuer --> Holder
    Holder --> Verifier
    Verifier --> Issuer
```

``` mermaid
sequenceDiagram
    Holder->>Verifier: Presents credential
    Verifier->>Issuer: Checks signature
    Issuer-->>Verifier: Valid
    Verifier-->>Holder: Access granted
```

## Embeds

An embedded note:

An embedded heading from another note:

## Tags

Inline tags: test test/nested source/ai

## Footnotes

A second footnote, to check numbering.[^3] A named footnote that is defined at the end.[^4]

[^1]: This is an inline footnote.

[^2]: Test

[^3]: A second footnote with **formatting** and a link.

[^4]: A footnote with a name instead of a number.
