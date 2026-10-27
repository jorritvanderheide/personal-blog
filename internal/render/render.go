// Package render turns a post's Markdown into HTML: CommonMark with GFM
// tables, strikethrough and footnotes. Raw HTML in the Markdown is left
// out, never passed through.
package render

import (
	"bytes"
	"html/template"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/extension"
)

var markdown = goldmark.New(
	goldmark.WithExtensions(
		extension.Table,
		extension.Strikethrough,
		extension.Footnote,
	),
)

// Markdown renders src as HTML.
func Markdown(src []byte) (template.HTML, error) {
	var buf bytes.Buffer
	if err := markdown.Convert(src, &buf); err != nil {
		return "", err
	}
	// goldmark escapes the text and leaves raw HTML out, so the result is
	// safe to put in a page as it is.
	return template.HTML(buf.String()), nil
}
