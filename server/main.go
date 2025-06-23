package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "ello.ai/server/proto"
)

type server struct {
	pb.UnimplementedLLMServiceServer
}

func (s *server) ChatCompletionStream(req *pb.ChatRequest, stream pb.LLMService_ChatCompletionStreamServer) error {
	log.Printf("Received streaming request for model: %s", req.Model)

	// Get the last user message to echo back
	var lastUserMessage string
	for _, msg := range req.Messages {
		if msg.Role == "user" {
			lastUserMessage = msg.Content
		}
	}

	if lastUserMessage == "" {
		return status.Error(codes.InvalidArgument, "No user message found")
	}

	// Simulate streaming response by sending the message word by word
	words := []string{"Echo:", lastUserMessage, "(streaming", "response", "from", "server)"}

	for i, word := range words {
		response := &pb.ChatResponse{
			Id:    fmt.Sprintf("msg_%d", i),
			Model: req.Model,
			Choice: &pb.Choice{
				Message: &pb.Message{
					Role:    "assistant",
					Content: word + " ",
				},
				FinishReason: "",
				Index:        int32(i),
			},
			Created: uint64(time.Now().Unix()),
			Done:    false,
		}

		if err := stream.Send(response); err != nil {
			return err
		}

		// Simulate some processing time
		time.Sleep(200 * time.Millisecond)
	}

	// Send final message indicating completion
	finalResponse := &pb.ChatResponse{
		Id:    "msg_final",
		Model: req.Model,
		Choice: &pb.Choice{
			Message: &pb.Message{
				Role:    "assistant",
				Content: "",
			},
			FinishReason: "stop",
			Index:        int32(len(words)),
		},
		Created: uint64(time.Now().Unix()),
		Done:    true,
	}

	return stream.Send(finalResponse)
}

func (s *server) ChatCompletion(ctx context.Context, req *pb.ChatRequest) (*pb.ChatCompletionResponse, error) {
	log.Printf("Received non-streaming request for model: %s", req.Model)

	// Get the last user message to echo back
	var lastUserMessage string
	for _, msg := range req.Messages {
		if msg.Role == "user" {
			lastUserMessage = msg.Content
		}
	}

	if lastUserMessage == "" {
		return nil, status.Error(codes.InvalidArgument, "No user message found")
	}

	response := &pb.ChatCompletionResponse{
		Id:    "msg_complete",
		Model: req.Model,
		Choices: []*pb.Choice{
			{
				Message: &pb.Message{
					Role:    "assistant",
					Content: fmt.Sprintf("Echo: %s (complete response from server)", lastUserMessage),
				},
				FinishReason: "stop",
				Index:        0,
			},
		},
		Created:               uint64(time.Now().Unix()),
		UsagePromptTokens:     uint64(len(lastUserMessage)),
		UsageCompletionTokens: uint64(len(lastUserMessage) + 30), // Rough estimate
		UsageTotalTokens:      uint64(len(lastUserMessage)*2 + 30),
	}

	return response, nil
}

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterLLMServiceServer(s, &server{})

	log.Printf("gRPC server listening on :50051")
	log.Printf("This server echoes back user messages for testing purposes")

	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
