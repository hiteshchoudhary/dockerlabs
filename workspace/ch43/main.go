// Chapter 43 scaffold — a tiny API compiled to ONE static binary.
// The final image is FROM scratch: no shell, no package manager, no /tmp. Nothing.
//
// Two listeners:
//   :8043 — the public endpoint (published to the host in the exercise)
//   :9090 — an internal "admin" endpoint that is NEVER published.
//           Reaching it is the whole point of the Challenge.
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	admin := http.NewServeMux()
	admin.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, `{"admin":"ok","secret":"the-whale-sees-all"}`)
	})
	go func() {
		log.Fatal(http.ListenAndServe(":9090", admin))
	}()

	public := http.NewServeMux()
	public.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, `{"status":"ok","service":"chai-43-api"}`)
	})
	log.Println("chai-43-api up — public :8043, admin :9090 (not published)")
	log.Fatal(http.ListenAndServe(":8043", public))
}
