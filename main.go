package main

import (
	"errors"
	"flag"
	"fmt"
	"image"
	"image/color"
	"log"
	"net/http"
	"time"

	"github.com/hybridgroup/mjpeg"
	"github.com/nats-io/nats.go"
	tf "github.com/wamuir/graft/tensorflow"
	"github.com/wamuir/graft/tensorflow/op"
	"gocv.io/x/gocv"
	"gocv.io/x/gocv/contrib"
)

func main() {
	var captureURL string

	flag.StringVar(&captureURL, "url", "udp://@:9988", "video capture stream URL")
	flag.Parse()

	if captureURL == "" {
		flag.Usage()
		return
	}

	printVersion()

	rtp, err := gocv.OpenVideoCaptureWithAPI(captureURL, gocv.VideoCaptureFFmpeg)
	if err != nil {
		log.Panic(err)
	}
	defer rtp.Close()

	nc, err := nats.Connect("nats://nats-server:4222")
	if err != nil {
		log.Panic(err)
	}
	defer nc.Close()

	log.Printf("Capture started from %s\n", captureURL)

	stream, err := trackObject(rtp, nc)
	if err != nil {
		log.Panic(err)
	}

	log.Println("Tracking started")

	if err := serverHTTP(stream); err != nil {
		log.Panic(err)
	}
}

func printVersion() {
	scope := op.NewScope()
	ver := op.Const(scope, tf.Version())

	graph, err := scope.Finalize()
	if err != nil {
		log.Panic(err)
	}

	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		log.Panic(err)
	}

	output, err := sess.Run(nil, []tf.Output{ver}, nil)
	if err != nil {
		log.Panic(err)
	}

	log.Printf("TensorFlow version %s\n", output[0].Value())
	log.Printf("OpenCV version %s\n", gocv.Version())
}

func serverHTTP(stream *mjpeg.Stream) error {
	http.Handle("/", stream)

	server := &http.Server{
		Addr:         ":8080",
		ReadTimeout:  60 * time.Second,
		WriteTimeout: 60 * time.Second,
	}

	log.Println("Processed at http://localhost:8080/")

	return server.ListenAndServe()
}

func trackObject(vc *gocv.VideoCapture, nc *nats.Conn) (*mjpeg.Stream, error) {
	stream := mjpeg.NewStream()
	mat := gocv.NewMat()

	readImg(&mat, vc)

	initImg, err := mat.ToImage()
	if err != nil {
		return nil, err
	}

	// Crop to the middle of the image (face tracking).
	crop := image.Rect(
		initImg.Bounds().Max.X/2-100,
		initImg.Bounds().Max.Y/2-100,
		initImg.Bounds().Max.X/2+100,
		initImg.Bounds().Max.Y/2+100,
	)

	tracker := contrib.NewTrackerKCF()
	if !tracker.Init(mat, crop) {
		return nil, errors.New("cannot initialize tracker")
	}

	// Ticker to print center coordinates every 2 seconds
	ticker := time.NewTicker(2 * time.Second)

	go func() {
		defer mat.Close()
		defer tracker.Close()
		defer ticker.Stop()

		blue := color.RGBA{0, 0, 255, 0}

		for {
			readImg(&mat, vc)

			rect, _ := tracker.Update(mat)

			// Draw the rectangle
			gocv.Rectangle(&mat, rect, blue, 1)

			// Calculate center of the rectangle
			centerX := rect.Min.X + (rect.Dx() / 2)
			centerY := rect.Min.Y + (rect.Dy() / 2)

			select {
			case <-ticker.C:
				log.Printf("Center of blue rectangle: (%d, %d)\n", centerX, centerY)

				// Create a message payload with the coordinates
				message := fmt.Sprintf("X: %d, Y: %d", centerX, centerY)

				// Publish the message to NATS
				if err := nc.Publish("chicken.coordinates", []byte(message)); err != nil {
					log.Println("Failed to publish message:", err)
				}
			default:
			}

			buf, _ := gocv.IMEncode(".jpg", mat)
			stream.UpdateJPEG(buf.GetBytes())
			buf.Close()
		}
	}()

	return stream, nil
}

func readImg(img *gocv.Mat, cap *gocv.VideoCapture) {
	for {
		if ok := cap.Read(img); !ok {
			log.Println("cannot read capture")

			return
		}

		if img.Empty() {
			continue
		}

		return
	}
}
