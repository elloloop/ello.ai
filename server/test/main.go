package main

import (
	"context"
	"fmt"
	"log"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "ello.ai/server/proto"
)

func main() {
	// Connect to the server
	conn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer conn.Close()

	client := pb.NewLLMServiceClient(conn)

	// Test streaming
	fmt.Println("Testing streaming chat completion...")
	streamReq := &pb.ChatRequest{
		Model: "gpt-3.5-turbo",
		Messages: []*pb.Message{
			{
				Role:    "user",
				Content: "Hello, this is a test message!",
			},
		},
		Temperature: 0.7,
		MaxTokens:   1000,
		UserId:      "test-client",
	}

	stream, err := client.ChatCompletionStream(context.Background(), streamReq)
	if err != nil {
		log.Fatalf("Failed to call ChatCompletionStream: %v", err)
	}

	for {
		response, err := stream.Recv()
		if err != nil {
			if err.Error() == "EOF" {
				break
			}
			log.Fatalf("Failed to receive response: %v", err)
		}

		fmt.Printf("Stream response: %s (done: %v)\n", response.Choice.Message.Content, response.Done)
		if response.Done {
			break
		}
	}

	// Test non-streaming
	fmt.Println("\nTesting non-streaming chat completion...")
	req := &pb.ChatRequest{
		Model: "gpt-3.5-turbo",
		Messages: []*pb.Message{
			{
				Role:    "user",
				Content: "Hello, this is a test message!",
			},
		},
		Temperature: 0.7,
		MaxTokens:   1000,
		UserId:      "test-client",
	}

	resp, err := client.ChatCompletion(context.Background(), req)
	if err != nil {
		log.Fatalf("Failed to call ChatCompletion: %v", err)
	}

	fmt.Printf("Complete response: %s\n", resp.Choices[0].Message.Content)
	fmt.Printf("Usage: %d total tokens\n", resp.UsageTotalTokens)
}
