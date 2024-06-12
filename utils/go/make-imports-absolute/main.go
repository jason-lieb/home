package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func main() {
		if len(os.Args) != 1 {
			fmt.Println("Please provide absolute import path")
			os.Exit(1)
		}

    if err := filepath.Walk("./", visit); err != nil {
        panic(err)
    }
}

func visit(path string, info os.FileInfo, err error) error {
    if err != nil {
        return err
    }

    if info.IsDir() || !(strings.HasSuffix(path, ".ts") || strings.HasSuffix(path, ".tsx")) {
        return nil
    }

    if err := changeRelativeImportsToAbsolute(path); err != nil {
        return err
    }

    return nil
}


func changeRelativeImportsToAbsolute(filePath string) error {
    content, err := os.ReadFile(filePath)
    if err != nil {
        return err
    }

		modifiedContent := modifyImports(filePath, string(content))

    file, err := os.OpenFile(filePath, os.O_WRONLY|os.O_TRUNC, 0666)
    if err != nil {
        return err
    }
    defer file.Close()

		if _, err := file.WriteString(modifiedContent); err != nil {
        return err
    }

    return nil
}

func modifyImports(filePath string, content string) string {
		// sample filePaths
		// file1.ts
		// subdir/file2.ts
		absoluteImportPath := os.Args[1]
    regex := regexp.MustCompile(`from '(\..*?)'`)
    return regex.ReplaceAllString(content, `from "`+absoluteImportPath+`$1";`)
}
