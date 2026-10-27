// Package web holds the templates, the stylesheet and the list of crawlers
// to keep out, embedded in the program. In development they are read from
// disk instead (-dev-assets), so an edit shows at once.
package web

import "embed"

//go:embed templates static crawlers.txt
var Files embed.FS
