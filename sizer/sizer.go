package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type Memory_stats struct {
	Flash float64 `json:"flash"`
	Sram  float64 `json:"sram"`
}

//To add more data, simply add more feilds to this struct
type Msg struct {
	Mem_stats Memory_stats `json:"memory_stats"`
}

type Event struct {
	Timestamp   time.Time `json:"timestamp"`
	Env         string    `json:"env"`
	Severity    string    `json:"severity"`
	Application string    `json:"application"`
	Message     Msg       `json:"message"`
}

// look at the output text file specified by the build. This function assumes a WEST output log. The parsing will need to be updated if there is a new type
// of output file.
func get_memory_usage(file_name string) (float64, float64) {
	var file []byte
	var flash_size, ram_size float64
	file, err := ioutil.ReadFile(file_name)
	file_string := string(file)
	lines := strings.Split(file_string, "\n")
	flag.Parse()
	if err != nil {
		log.Fatal(err)
	}
	for _, line := range lines {
		// Find the lines containing the FLASH and SRAM data from the build output. The simply split the data on white space and analyize the relevant feilds.
		// Everything is normalized to KB.
		if match, _ := regexp.Match("FLASH:", []byte(line)); match {
			elements := strings.Fields(line)
			if match, _ := regexp.Match("KB:", []byte(elements[2])); match {
				flash_size, _ = strconv.ParseFloat(elements[1], 32)
			} else if match, _ := regexp.Match("MB:", []byte(elements[2])); match {
				flash_size, _ = strconv.ParseFloat(elements[1], 32)
				flash_size *= 1000
			} else {
				flash_size, _ = strconv.ParseFloat(elements[1], 32)
				flash_size /= 1000
			}
		} else if match, _ := regexp.Match("SRAM:", []byte(line)); match {
			elements := strings.Fields(line)
			if match, _ := regexp.Match("KB:", []byte(elements[2])); match {
				ram_size, _ = strconv.ParseFloat(elements[1], 32)
			} else if match, _ := regexp.Match("MB:", []byte(elements[2])); match {
				ram_size, _ = strconv.ParseFloat(elements[1], 32)
				ram_size *= 1000
			} else {
				ram_size, _ = strconv.ParseFloat(elements[1], 32)
				ram_size /= 1000
			}
		}
	}
	return flash_size, ram_size
}

// Take the ram_size and flash size and pack them into a json approprate for Humio. Other parameters can be added, just simply add another feild to
// the "Message" struct.
func complie_package(flash_size float64, ram_size float64, project string) []byte {
	memory_stats := &Memory_stats{Flash: flash_size, Sram: ram_size}
	msg := &Msg{Mem_stats: *memory_stats}
	event := &Event{Timestamp: time.Now(), Env: "ci", Severity: "INFO", Application: "ci:" + project, Message: *msg}
	event_json, err := json.Marshal(event)
	if err != nil {
		log.Fatal(err)
	}
	return event_json
}

//Make a request to the Humio API to POST a message to the specified api
func make_humio_request(event []byte, token string, ingest_api string) *http.Request {
	var base_url string = "https://cloud.humio.com/api/v1/ingest/"
	var token_header = "Bearer " + token
	req, err := http.NewRequest("POST", base_url+ingest_api, bytes.NewBuffer(event))
	if err != nil {
		log.Fatal(err)
	}
	req.Header.Set("Authorization", token_header)
	req.Header.Add("Content-Type", "application/json")
	return req
}

func do_request(req *http.Request) {
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Println("Error while reading the response bytes:", err)
	}
	// If we dont get an empty JSON back report the message
	if string(body) != "{}" {
		log.Println("Respose error:", string(body))
	} else {
		fmt.Println("Request complete")
	}
}

func main() {
	tokenPointer := flag.String("token", "none", "a string")
	filePointer := flag.String("file_name", "none", "a string")
	projectPointer := flag.String("project", "test-data", "a string")
	flag.Parse()

	flash_size, ram_size := get_memory_usage(*filePointer)
	upload_package := complie_package(flash_size, ram_size, *projectPointer)
	humio_request := make_humio_request(upload_package, *tokenPointer, "raw")
	do_request(humio_request)
}
