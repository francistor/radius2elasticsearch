package main

import (
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/francistor/igor/cdrwriter"
	"github.com/francistor/igor/core"
	"github.com/francistor/igor/router"
)

var ew *cdrwriter.ElasticCDRWriter

func main() {

	// defer profile.Start(profile.BlockProfile).Stop()

	// After ^C, signalChan will receive a message
	doneChan := make(chan struct{}, 1)
	signalChan := make(chan os.Signal, 1)
	go func() {
		<-signalChan
		close(doneChan)
		fmt.Println()
		fmt.Println("terminating server")
	}()
	signal.Notify(signalChan, syscall.SIGINT, syscall.SIGTERM)

	// Get the command line arguments
	bootPtr := flag.String("boot", "resources/searchRules.json", "File or http URL with Configuration Search Rules")
	instancePtr := flag.String("instance", "", "Name of instance")
	elasticUrlPtr := flag.String("elasticurl", "http://localhost:9200", "URL of the Elasticsearch host")

	flag.Parse()

	// Initialize the Config Object
	ci := core.InitPolicyConfigInstance(*bootPtr, *instancePtr, nil, true)

	// Get logger
	logger := core.GetLogger()
	if logger == nil {
		panic("logger is nil")
	}

	// Start Radius
	r := router.NewRadiusRouter(*instancePtr, RequestHandler)

	// Initializations
	// Read elastic configuration
	elasticFormatConfig := core.NewConfigObject[cdrwriter.ElasticFormatConf]("elasticFormat.json")
	if err := elasticFormatConfig.Update(&ci.CM); err != nil {
		fmt.Println("could not read elasticFormat.json file %w", err)
		return
	}
	elasticFormat := cdrwriter.NewElasticFormat(elasticFormatConfig.Get())

	// Build cdr writer
	ew = cdrwriter.NewElasticCDRWriter(*elasticUrlPtr+"/_doc/_bulk?filter_path=took,errors", "", "", elasticFormat, 1 /* Timeout */, 2 /* GlitchSeconds */)

	// Start server
	r.Start()
	logger.Info("Radius router started")

	// Wait for termination signal
	<-doneChan

	// Close router gracefully
	r.Close()
}

// Packet handler
func RequestHandler(request *core.RadiusPacket) (*core.RadiusPacket, error) {

	hl := core.NewHandlerLogger()
	l := hl.L
	l.Debug("")

	defer func(h *core.HandlerLogger) {
		h.L.Debug("---[END REQUEST]-----")
		h.L.Debug("")
		h.WriteLog()
	}(hl)

	l.Debug("---[START REQUEST]-----")
	if core.IsDebugEnabled() {
		l.Debug(request.String())
	}

	ew.WriteRadiusCDR(request)

	response := core.NewRadiusResponse(request, true)

	return response, nil
}
