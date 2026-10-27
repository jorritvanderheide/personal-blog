// Package web holds the templates, embedded in the program. In development
// they are read from disk instead (-dev-assets), so an edit shows at once.
package web

import "embed"

//go:embed templates
var Files embed.FS
