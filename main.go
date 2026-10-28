// Command personal-blog makes the BW20 personal blog from content/, on
// small-press: the pages are this site's own (pages.go, and the templates
// and stylesheet in web/), and everything else is the library's. See
// small-press for the flags: -out, -serve and -receive.
package main

import (
	smallpress "codeberg.org/BW20/small-press"

	"codeberg.org/BW20/personal-blog/web"
)

func main() {
	smallpress.Main(smallpress.Site{Pages: pages, Assets: web.Files, Options: sections})
}
