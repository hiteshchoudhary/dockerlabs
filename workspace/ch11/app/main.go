// ChaiCode API — Go edition. Compiles to a single static binary, which is
// exactly what makes tiny final images possible. You don't need Go installed:
// the build happens inside a container (that's the whole point of the chapter).
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"runtime"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"service": "chaicode-api",
			"status":  "ok",
			"lang":    "go",
			"arch":    runtime.GOARCH,
		})
	})
	log.Println("chaicode-api (go) listening on :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}
