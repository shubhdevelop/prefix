package main

import (
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"gopkg.in/yaml.v3"
)

type Config struct {
	DumpDirectory string        `yaml:"dump_directory"`
	Destinations  []Destination `yaml:"destinations"`
}

type Destination struct {
	Path   string `yaml:"path"`
	Prefix string `yaml:"prefix,omitempty"`
	Suffix string `yaml:"suffix,omitempty"`
}

func loadConfig() (*Config, error) {
	filename := ".prefix.yaml"
	home, err := os.UserHomeDir()
	configFileName := filepath.Join(home, filename)
	if err != nil {
		fmt.Printf("could not get home directory: %v\n", err)
		return nil, err
	}

	file, err := os.Open(configFileName)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			fmt.Printf("File not found: %s\n", configFileName)
			// Handle file not existing (e.g., create it, exit)
			return nil, err
		} else {
			// Handle other potential errors (e.g., permission denied)
			fmt.Printf("Error opening file: %v\n", err)
			return nil, err
		}
	}
	defer func() {
		closeErr := file.Close()
		if err == nil {
			err = closeErr // Capture close error if no other error occurred
		}
	}()
	fmt.Printf("File exists and opened successfully: %s\n", configFileName)

	data, err := os.ReadFile(configFileName)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse YAML: %w", err)
	}

	return &config, nil
}

func matchesPattern(filename string, dest Destination) bool {
	// when both prefix and suffix are specified, both must match
	if dest.Prefix != "" && dest.Suffix != "" {
		return strings.HasPrefix(filename, dest.Prefix) && strings.HasSuffix(filename, dest.Suffix)
	}
	if dest.Prefix != "" {
		return strings.HasPrefix(filename, dest.Prefix)
	}
	if dest.Suffix != "" {
		return strings.HasSuffix(filename, dest.Suffix)
	}
	return false
}

func moveFile(sourcePath, destPath string) error {
	// make sure destination directory exists
	destDir := filepath.Dir(destPath)
	if err := os.MkdirAll(destDir, 0o755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	if _, err := os.Stat(destPath); err == nil {
		return fmt.Errorf("destination file already exists: %s", destPath)
	}

	if err := os.Rename(sourcePath, destPath); err == nil {
		return nil
	}

	if err := copyFile(sourcePath, destPath); err != nil {
		return fmt.Errorf("failed to copy file: %w", err)
	}

	if err := os.Remove(sourcePath); err != nil {
		return fmt.Errorf("failed to remove source file: %w", err)
	}

	return nil
}

func copyFile(sourcePath, destPath string) error {
	sourceFile, err := os.Open(sourcePath)
	if err != nil {
		return err
	}
	defer func() {
		closeErr := sourceFile.Close()
		if err == nil {
			err = closeErr // Capture close error if no other error occurred
		}
	}()
	destFile, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer func() {
		closeErr := destFile.Close()
		if err == nil {
			err = closeErr // Capture close error if no other error occurred
		}
	}()

	if _, err := io.Copy(destFile, sourceFile); err != nil {
		return err
	}

	// Copy file permissions
	sourceInfo, err := os.Stat(sourcePath)
	if err != nil {
		return err
	}
	return os.Chmod(destPath, sourceInfo.Mode())
}

func organizeFiles(config *Config) error {
	files, err := os.ReadDir(config.DumpDirectory)
	if err != nil {
		return fmt.Errorf("failed to read dump directory: %w", err)
	}

	movedCount := 0
	skippedCount := 0

	for _, file := range files {
		if file.IsDir() {
			continue
		}

		filename := file.Name()
		sourcePath := filepath.Join(config.DumpDirectory, filename)
		moved := false

		for _, dest := range config.Destinations {
			if matchesPattern(filename, dest) {
				destPath := filepath.Join(dest.Path, filename)

				log.Printf("Moving: %s -> %s", sourcePath, destPath)

				if err := moveFile(sourcePath, destPath); err != nil {
					log.Printf("Error moving %s: %v", filename, err)
					skippedCount++
				} else {
					log.Printf("Success: %s", filename)
					movedCount++
					moved = true
				}
				break // Move to first matching destination only
			}
		}

		if !moved {
			log.Printf("No match found for: %s", filename)
			skippedCount++
		}
	}

	log.Printf("\nSummary: %d files moved, %d files skipped", movedCount, skippedCount)
	return nil
}

var timer *time.Timer

func main() {
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	if _, err := os.Stat(config.DumpDirectory); os.IsNotExist(err) {
		log.Fatalf("Dump directory does not exist: %s", config.DumpDirectory)
	}

	log.Printf("Dump directory: %s", config.DumpDirectory)
	log.Printf("Processing %d destination rules", len(config.Destinations))

	watcher, _ := fsnotify.NewWatcher()
	defer func() {
		closeErr := watcher.Close()
		if err == nil {
			err = closeErr // Capture close error if no other error occurred
		}
	}()

	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				// Log everything to see what your editor is actually doing
				log.Println(event)
				// 2. DEBOUNCING LOGIC:
				// If a timer is already running, stop it so we can restart the 5s countdown.
				if timer != nil {
					timer.Stop()
				}

				// 3. Start (or restart) the timer.
				// AfterFunc runs in its own goroutine automatically.
				timer = time.AfterFunc(5*time.Second, func() {
					log.Println("Timer expired, organizing files...")
					// Note: organizeFiles must be a function call inside this closure
					err := organizeFiles(config)
					if err != nil {
						fmt.Println(err)
					}
				})

			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Println("Error:", err)
			}
		}
	}()

	err = watcher.Add(config.DumpDirectory)
	if err != nil {
		fmt.Println(err)
	}
	select {}
}
