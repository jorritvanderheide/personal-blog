package build

import (
	"strconv"
	"time"
)

// seasons names each month by its place in its season, December first in
// winter, as on the old site.
var seasons = [12]string{
	"mid winter", "late winter",
	"early spring", "mid spring", "late spring",
	"early summer", "mid summer", "late summer",
	"early autumn", "mid autumn", "late autumn",
	"early winter",
}

// season is a date as a season: "early spring 2026".
func season(t time.Time) string {
	return seasons[t.Month()-1] + " " + strconv.Itoa(t.Year())
}
